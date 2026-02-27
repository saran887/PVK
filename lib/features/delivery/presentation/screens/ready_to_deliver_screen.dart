import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/providers/auth_provider.dart';

class ReadyToDeliverScreen extends ConsumerWidget {
  const ReadyToDeliverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final userLocationId = currentUser?.locationId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready to Deliver'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'billed')
            .orderBy('billedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          // Filter by location if user has a location assigned
          if (userLocationId.isNotEmpty) {
            orders = orders.where((order) {
              final data = order.data() as Map<String, dynamic>;
              final shopLocationId = data['shopLocationId'] as String?;
              // Include orders with matching location or no location set (backward compatibility)
              return shopLocationId == null || shopLocationId.isEmpty || shopLocationId == userLocationId;
            }).toList();
          }

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.inventory_outlined, size: 64, color: Colors.orange.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Text('No orders ready for delivery', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final shopName = order['shopName'] ?? 'Unknown Shop';
              final totalAmount = order['totalAmount'] ?? 0;
              final totalItems = order['totalItems'] ?? 0;
              final billedAt = order['billedAt'] as Timestamp?;

              final shopId = order['shopId'] as String?;

              return StreamBuilder<DocumentSnapshot>(
                stream: shopId != null 
                    ? FirebaseFirestore.instance.collection('shops').doc(shopId).snapshots()
                    : null,
                builder: (context, shopSnapshot) {
                  final shopData = shopSnapshot.data?.data() as Map<String, dynamic>?;
                  final shopPhone = shopData?['phone'] as String? ?? '';
                  final shopAddress = shopData?['address'] as String? ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Order ID: ${orderId.substring(0, 8)}...'),
                          Text('Items: $totalItems | Amount: ₹${totalAmount.toStringAsFixed(2)}'),
                          if (billedAt != null)
                            Text('Billed: ${DateFormat('dd MMM yyyy, hh:mm a').format(billedAt.toDate())}',
                              style: const TextStyle(fontSize: 12)),
                          if (shopAddress.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(shopAddress)}');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.map, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      shopAddress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: shopPhone.isNotEmpty
                          ? IconButton.filledTonal(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () async {
                                final url = Uri.parse('tel:$shopPhone');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                            )
                          : null,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ..._buildOrderItems(order['items'] as List<dynamic>? ?? []),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _markAsDelivered(
                                  context,
                                  orderId: orderId,
                                  amount: (totalAmount is num) ? totalAmount.toDouble() : 0,
                                ),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Mark as Delivered'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildOrderItems(List<dynamic> items) {
    return items.map((item) {
      final name = item['productName'] ?? item['name'] ?? 'Unknown';
      final quantity = item['quantity'] ?? 0;
      final price = item['price'] ?? 0;
      final total = quantity * price;
      final productId = item['productId'] ?? '';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name x $quantity'),
                  if (productId.isNotEmpty)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .doc(productId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        
                        final productData = snapshot.data?.data() as Map<String, dynamic>?;
                        if (productData == null) {
                          return const SizedBox.shrink();
                        }
                        
                        final stock = int.tryParse(productData['quantity']?.toString() ?? '0') ?? 0;
                        final stockColor = stock < 10 ? Colors.red : (stock < 50 ? Colors.orange : Colors.green);
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2, size: 12, color: stockColor),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: $stock ${productData['quantityUnit'] ?? 'pcs'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: stockColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _markAsDelivered(
    BuildContext context, {
    required String orderId,
    required double amount,
  }) async {
    final paymentMethod = await _showPaymentMethodSheet(context, amount: amount);
    if (paymentMethod == null) return;

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'paid',
        'paymentMethod': paymentMethod,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as delivered via ${paymentMethod.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showPaymentMethodSheet(BuildContext context, {required double amount}) async {
    String selected = 'cash';
    final methods = [
      {'key': 'cash', 'title': 'Cash', 'icon': Icons.payments_outlined, 'color': Colors.green},
      {'key': 'gpay', 'title': 'GPay UPI', 'icon': Icons.qr_code_scanner, 'color': Colors.blue},
      {'key': 'credit', 'title': 'Credit', 'icon': Icons.credit_card, 'color': Colors.purple},
    ];

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Select payment method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Amount: ₹${amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  ...methods.map((m) {
                    final isSelected = selected == m['key'];
                    final color = m['color'] as Color;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? color : Colors.grey.shade300),
                        color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(m['icon'] as IconData, color: color),
                        ),
                        title: Text(m['title'] as String),
                        trailing: Radio<String>(
                          value: m['key'] as String,
                          // ignore: deprecated_member_use
                          groupValue: selected,
                          activeColor: color,
                          // ignore: deprecated_member_use
                          onChanged: (val) => setState(() => selected = val!),
                        ),
                        onTap: () => setState(() => selected = m['key'] as String),
                      ),
                    );
                  }),
                  if (selected == 'gpay') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Scan QR Code to Pay',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('UPI ID: saransarvesh213@oksbi'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: QrImageView(
                              data: 'upi://pay?pa=saransarvesh213@oksbi&pn=Saran Sarvesh A G&am=${amount.toStringAsFixed(2)}&cu=INR',
                              size: 180,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Amount: ₹${amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, selected),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          child: const Text('Confirm & Deliver'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }
}
