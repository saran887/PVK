import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BillGenerator {
  // Company Details
  static const String companyName = 'Sri Balaji Trading Company';
  static const String companyAddress = '18/348, Narayana Valasu\nVivekanandhar Salai, Erode - 11.';
  static const String fssaiNo = 'FSSAI NO:12418007000565';
  static const String gstin = 'GSTIN No : 33AGTPG1206B1Z1';

  static String _pickPhone(Map<String, dynamic> source) {
    const keys = [
      'phone',
      'phoneNumber',
      'mobile',
      'mobileNumber',
      'contact',
      'contactNumber',
      'whatsapp',
      'whatsappNumber',
      'shopPhone',
      'shopMobile',
      'shopMobileNumber',
      'shopPhoneNumber',
      'shopContact',
      'ownerPhone',
    ];
    for (final key in keys) {
      final v = source[key];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  static String _formatWhatsappNumber(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final withCountry = clean.startsWith('+')
        ? clean.substring(1)
        : clean.startsWith('91')
            ? clean
            : '91$clean';
    return withCountry;
  }
  
  static Future<void> generateAndShare({
    required BuildContext context,
    required String orderId,
    required Map<String, dynamic> order,
  }) async {
    final shopName = (order['shopName'] ?? 'Unknown Shop').toString();
    final shopId = (order['shopId'] ?? '').toString();
    
    // Fetch shop details from database
    String shopAddress = 'Bhavani Main Road';
    final fallbackPhone = _pickPhone(order) == '' && order['shop'] is Map<String, dynamic>
      ? _pickPhone(order['shop'] as Map<String, dynamic>)
      : _pickPhone(order);
    String shopPhone = fallbackPhone;
    String shopGst = '';
    
    if (shopId.isNotEmpty) {
      try {
        final shopDoc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .get();
        
        if (shopDoc.exists) {
          final shopData = shopDoc.data() as Map<String, dynamic>;
          shopAddress = (shopData['address'] ?? 'Bhavani Main Road').toString();
          shopPhone = _pickPhone(shopData);
          shopGst = (shopData['gst'] ?? '').toString();
        }
      } catch (e) {
        // If fetch fails, continue with defaults
        debugPrint('Error fetching shop details: $e');
      }
    }

    // Secondary lookup by shopName if phone still empty and no shopId path helped
    if (shopPhone.isEmpty && shopName.isNotEmpty) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('shops')
            .where('name', isEqualTo: shopName)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          shopPhone = _pickPhone(data);
          if (shopAddress == 'Bhavani Main Road') {
            shopAddress = (data['address'] ?? shopAddress).toString();
          }
          if (shopGst.isEmpty) {
            shopGst = (data['gst'] ?? '').toString();
          }
        }
      } catch (e) {
        debugPrint('Error fetching shop by name: $e');
      }
    }

    // If shop phone not found in shop doc, fallback to the order payload
    if (shopPhone.isEmpty && fallbackPhone.isNotEmpty) {
      shopPhone = fallbackPhone;
    }

    debugPrint('BillGenerator: orderId=$orderId shopId=$shopId phoneResolved="$shopPhone" fallback="$fallbackPhone"');

    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      try {
        if (v is Map && v.containsKey('_seconds')) {
          final seconds = (v['_seconds'] as num).toInt();
          final nanos = (v['_nanoseconds'] as num?)?.toInt() ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanos ~/ 1000000));
        }
      } catch (_) {}
      return null;
    }

    final billedAt = toDate(order['billedAt']) ?? toDate(order['createdAt']);
    final date = billedAt ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final fileNameDate = DateFormat('dd-MM-yyyy').format(date); // Safe filename format
    final sanitizedShopName = shopName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_'); // Clean shop name for filename
    final items = (order['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    
    // Calculate GST totals
    double subtotal = 0;
    for (var item in items) {
      final qty = ((item['quantity'] ?? 0) as num).toDouble();
      final rate = ((item['price'] ?? 0) as num).toDouble();
      subtotal += (qty * rate);
    }
    
    final gstAmount = subtotal * 0.05; // 5% GST
    final netTotal = subtotal + gstAmount;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - TAX INVOICE
              pw.Center(
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Company and Customer Details Box
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Side - Company Details
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              companyName,
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(fssaiNo, style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(gstin, style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Right Side - Customer Details
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'To : $shopName',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 4),
                            pw.Text('Ph : $shopPhone', style: const pw.TextStyle(fontSize: 9)),
                            if (shopGst.isNotEmpty)
                              pw.Text('GST No : $shopGst', style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 8),
              
              // Bill Details Row
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bill No : ${orderId.substring(0, 8)}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Bill Date : $formattedDate', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Bill Type : CREDIT BILL', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Eway Bill No :', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 8),
              
              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),   // S.No
                  1: const pw.FlexColumnWidth(3),     // Item Name
                  2: const pw.FixedColumnWidth(60),   // HSN Code
                  3: const pw.FixedColumnWidth(40),   // Qty
                  4: const pw.FixedColumnWidth(50),   // Rate
                  5: const pw.FixedColumnWidth(35),   // Dis%
                  6: const pw.FixedColumnWidth(45),   // D.Amt
                  7: const pw.FixedColumnWidth(35),   // GST%
                  8: const pw.FixedColumnWidth(55),   // Net Rate
                  9: const pw.FixedColumnWidth(65),   // Net Amount
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildTableCell('S.No', isHeader: true),
                      _buildTableCell('Item Name', isHeader: true),
                      _buildTableCell('HSN Code', isHeader: true),
                      _buildTableCell('Qty', isHeader: true),
                      _buildTableCell('Rate', isHeader: true),
                      _buildTableCell('Dis%', isHeader: true),
                      _buildTableCell('D.Amt', isHeader: true),
                      _buildTableCell('GST%', isHeader: true),
                      _buildTableCell('Net Rate', isHeader: true),
                      _buildTableCell('Net Amount', isHeader: true),
                    ],
                  ),
                  
                  // Item Rows
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    final productName = (item['productName'] ?? 'Unknown').toString();
                    final hsnCode = (item['hsnCode'] ?? '11029090').toString();
                    final qty = ((item['quantity'] ?? 0) as num).toDouble();
                    final rate = ((item['price'] ?? 0) as num).toDouble();
                    final unit = (item['unit'] ?? 'Nos').toString();
                    final discount = 0.0;
                    final discountAmt = 0.0;
                    final gstPercent = 5.0;
                    final netRate = rate * (1 + gstPercent / 100);
                    final netAmount = qty * netRate;
                    
                    return pw.TableRow(
                      children: [
                        _buildTableCell(index.toString()),
                        _buildTableCell(productName, align: pw.TextAlign.left),
                        _buildTableCell(hsnCode),
                        _buildTableCell('${qty.toStringAsFixed(0)} $unit'),
                        _buildTableCell(rate.toStringAsFixed(2)),
                        _buildTableCell(discount.toStringAsFixed(0)),
                        _buildTableCell(discountAmt.toStringAsFixed(2)),
                        _buildTableCell(gstPercent.toStringAsFixed(0)),
                        _buildTableCell(netRate.toStringAsFixed(2)),
                        _buildTableCell(netAmount.toStringAsFixed(2)),
                      ],
                    );
                  }),
                ],
              ),
              
              pw.SizedBox(height: 8),
              
              // Total Section
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Subtotal: Rs.${subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('GST (5%): Rs.${gstAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Total Amount: Rs.${netTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await doc.save();
    final fileName = '${sanitizedShopName}_$fileNameDate.pdf';

    // One-click: Generate, Save, and Send summary to WhatsApp
    if (context.mounted) {
      if (shopPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ WhatsApp number not found in database!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating and sending bill...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Track if WhatsApp was sent successfully
      bool whatsappSuccess = false;
      
      try {
        // Send WhatsApp summary message
        await _sendSummaryToWhatsApp(
          shopPhone: shopPhone,
          shopName: shopName,
          items: items,
          netTotal: netTotal,
          gstAmount: gstAmount,
          subtotal: subtotal,
          fileName: fileName,
        );
        whatsappSuccess = true;
        
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
        }
      } catch (e) {
        debugPrint('❌ Error sending WhatsApp summary: $e');
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ WhatsApp failed. Saving PDF anyway...'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // Continue to save PDF even if WhatsApp fails
      }

      // Always save the PDF to device (regardless of WhatsApp status)
      try {
        await _savePDFToDevice(
          bytes,
          fileName,
          shopName,
          context,
          whatsappSuccess: whatsappSuccess,
        );
      } catch (e) {
        debugPrint('❌ Error saving PDF: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(whatsappSuccess 
                ? 'Summary sent, but PDF save failed: $e'
                : '❌ Both WhatsApp and PDF save failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  static Future<void> _savePDFToDevice(
    Uint8List bytes,
    String fileName,
    String shopName,
    BuildContext context, {
    required bool whatsappSuccess,
  }) async {
    debugPrint('💾 Starting PDF save to device...');
    
    try {
      // Handle web platform separately
      if (kIsWeb) {
        debugPrint('🌐 Web platform detected - using browser download');
        
        // For web, use the printing package's share functionality which triggers browser download
        await Printing.sharePdf(
          bytes: bytes,
          filename: fileName,
        );
        
        debugPrint('✅ PDF download initiated in browser');
        
        // Show success message for web
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(whatsappSuccess ? Icons.check_circle : Icons.warning, 
                       color: whatsappSuccess ? Colors.green : Colors.orange, 
                       size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      whatsappSuccess 
                        ? 'Bill Generated Successfully'
                        : 'Bill Downloaded (WhatsApp Not Available)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!whatsappSuccess)
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'WhatsApp is not available on web',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  if (!whatsappSuccess) const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.download, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PDF downloaded to browser',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Step 1: Request storage permission (mobile only)
      debugPrint('📂 Requesting storage permissions...');
      
      if (Platform.isAndroid) {
        // Request appropriate permission based on Android version
        PermissionStatus storageStatus;
        
        // Try manageExternalStorage first (for Android 11+)
        storageStatus = await Permission.manageExternalStorage.status;
        debugPrint('📂 Manage external storage status: $storageStatus');
        
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.manageExternalStorage.request();
          debugPrint('📂 Manage external storage request result: $storageStatus');
        }
        
        // If still not granted, try regular storage permission
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.status;
          debugPrint('📂 Storage permission status: $storageStatus');
          
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
            debugPrint('📂 Storage permission request result: $storageStatus');
          }
        }
        
        // Check if we have any storage permission
        final hasPermission = storageStatus.isGranted || 
                             storageStatus.isLimited || 
                             await Permission.storage.isGranted ||
                             await Permission.manageExternalStorage.isGranted;
        
        if (!hasPermission) {
          debugPrint('❌ No storage permissions granted');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('❌ Storage permission required. Please grant permission in app settings.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      // Step 2: Save PDF to appropriate directory
      Directory? directory;
      String savedPath = '';
      
      if (Platform.isAndroid) {
        // Try multiple directory options
        List<Directory?> directoryOptions = [];
        
        // Option 1: Downloads directory
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            directoryOptions.add(downloadsDir);
          }
        } catch (e) {
          debugPrint('⚠️ Cannot access Downloads: $e');
        }
        
        // Option 2: Documents directory
        try {
          final documentsDir = Directory('/storage/emulated/0/Documents');
          if (await documentsDir.exists()) {
            directoryOptions.add(documentsDir);
          }
        } catch (e) {
          debugPrint('⚠️ Cannot access Documents: $e');
        }
        
        // Option 3: External storage directory
        try {
          directoryOptions.add(await getExternalStorageDirectory());
        } catch (e) {
          debugPrint('⚠️ Cannot access external storage: $e');
        }
        
        // Option 4: Application documents directory
        try {
          directoryOptions.add(await getApplicationDocumentsDirectory());
        } catch (e) {
          debugPrint('⚠️ Cannot access app documents: $e');
        }
        
        // Try each directory until one works
        for (final dir in directoryOptions) {
          if (dir != null) {
            try {
              // Create BillPDFs subdirectory
              final billsDir = Directory('${dir.path}/BillPDFs');
              if (!await billsDir.exists()) {
                await billsDir.create(recursive: true);
              }
              
              // Try to write a test file
              final testFile = File('${billsDir.path}/.test');
              await testFile.writeAsString('test');
              await testFile.delete();
              
              directory = dir;
              debugPrint('✅ Using directory: ${dir.path}');
              break;
            } catch (e) {
              debugPrint('⚠️ Cannot write to ${dir.path}: $e');
              continue;
            }
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
        debugPrint('📂 Using documents directory: ${directory.path}');
      }

      if (directory == null) {
        throw Exception('Could not find a writable directory to save file. Please check app permissions.');
      }

      // Create BillPDFs subdirectory if it doesn't exist
      final billsDir = Directory('${directory.path}/BillPDFs');
      if (!await billsDir.exists()) {
        await billsDir.create(recursive: true);
        debugPrint('📁 Created BillPDFs directory: ${billsDir.path}');
      }

      // Save the file
      final permanentFile = File('${billsDir.path}/$fileName');
      debugPrint('💾 Writing file to: ${permanentFile.path}');
      await permanentFile.writeAsBytes(bytes, flush: true);
      savedPath = permanentFile.path;
      
      // Verify file was saved
      if (await permanentFile.exists()) {
        final fileSize = await permanentFile.length();
        debugPrint('✅ PDF saved successfully to: $savedPath (Size: $fileSize bytes)');
        
        // Verify file size is reasonable
        if (fileSize < 100) {
          throw Exception('File size too small ($fileSize bytes). File may be corrupted.');
        }
      } else {
        throw Exception('File verification failed - file does not exist after writing');
      }

      // Show success message
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(whatsappSuccess ? Icons.check_circle : Icons.warning, 
                     color: whatsappSuccess ? Colors.green : Colors.orange, 
                     size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    whatsappSuccess 
                      ? 'Bill Generated Successfully'
                      : 'Bill Saved (WhatsApp Failed)',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(whatsappSuccess ? Icons.check_circle : Icons.error, 
                           color: whatsappSuccess ? Colors.green : Colors.red, 
                           size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          whatsappSuccess 
                            ? 'WhatsApp message sent'
                            : 'WhatsApp message failed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: whatsappSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bill saved to device:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      savedPath,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Shop: $shopName',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _savePDFToDevice: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Failed to save bill to device:\n$e\n\nPlease check app permissions in Settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  static Future<void> _sendSummaryToWhatsApp({
    required String shopPhone,
    required String shopName,
    required List<Map<String, dynamic>> items,
    required double netTotal,
    required double gstAmount,
    required double subtotal,
    required String fileName,
  }) async {
    debugPrint('📱 Sending WhatsApp summary to: $shopPhone');
    
    final summary = StringBuffer()
      ..writeln('Hello $shopName, here is your order summary:')
      ..writeln('Total: ₹${netTotal.toStringAsFixed(2)} (Subtotal: ₹${subtotal.toStringAsFixed(2)}, GST: ₹${gstAmount.toStringAsFixed(2)})')
      ..writeln('Items:');

    for (final item in items) {
      final name = (item['productName'] ?? 'Item').toString();
      final qty = ((item['quantity'] ?? 0) as num).toStringAsFixed(0);
      final price = ((item['price'] ?? 0) as num).toDouble();
      summary.writeln('- $name: $qty × ₹${price.toStringAsFixed(2)}');
    }

    summary.writeln('\nThank you! (Ref: $fileName)');

    final normalized = _formatWhatsappNumber(shopPhone);
    debugPrint('📱 Normalized WhatsApp number: $normalized');

    try {
      final whatsappUrl = Uri.parse("https://wa.me/$normalized?text=${Uri.encodeFull(summary.toString())}");
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
      debugPrint('✅ WhatsApp summary sent successfully');
    } catch (e) {
      debugPrint('❌ WhatsApp share failed: $e');
      throw Exception('Failed to send WhatsApp summary: $e');
    }
  }
  
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.center, double? height}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: height,
      alignment: align == pw.TextAlign.left ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}
