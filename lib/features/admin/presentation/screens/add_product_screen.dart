import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  final bool isEdit;
  
  const AddProductScreen({super.key, this.productId, this.isEdit = false});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedUnit = 'kg';
  String _selectedQuantityUnit = 'pcs';
  bool _isLoading = false;
  bool _isUploading = false;
  List<String> _categories = [];
  String? _selectedCategory;
  File? _imageFile;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.isEdit && widget.productId != null) {
      _loadProductData();
    }
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _categories = snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    });
  }

  Future<void> _loadProductData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _productIdController.text = widget.productId ?? '';
          _nameController.text = data['name'] ?? '';
          _weightController.text = (data['weight'] ?? 0).toString();
          _quantityController.text = (data['quantity'] ?? 0).toString();
          _priceController.text = (data['price'] ?? 0).toString();
          _imageUrlController.text = data['imageUrl'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _selectedUnit = data['weightUnit'] ?? 'kg';
          _selectedQuantityUnit = data['quantityUnit'] ?? 'pcs';
          _selectedCategory = data['category'];
          _uploadedImageUrl = data['imageUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }



  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _uploadBytesToHost(List<int> bytes, String fileName) async {
    // Try multiple hosts in order until one succeeds
    final hosts = [
      // Try imgbb.io (no auth needed for small files)
      () async {
        debugPrint('🔄 Trying freeimage.host...');
        final request = http.MultipartRequest('POST', Uri.parse('https://freeimage.host/api/1/upload'));
        request.fields['key'] = '6d207e02198a847aa98d0a2a901485a5'; // Free public key
        request.files.add(http.MultipartFile.fromBytes('source', bytes, filename: fileName));
        final response = await http.Response.fromStream(await request.send());
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['image']?['url'] as String?;
        }
        return null;
      },
      // Fallback: catbox.moe
      () async {
        debugPrint('🔄 Trying catbox.moe...');
        final request = http.MultipartRequest('POST', Uri.parse('https://catbox.moe/user/api.php'));
        request.fields['reqtype'] = 'fileupload';
        request.files.add(http.MultipartFile.fromBytes('fileToUpload', bytes, filename: fileName));
        final response = await http.Response.fromStream(await request.send());
        if (response.statusCode == 200 && response.body.startsWith('http')) {
          return response.body.trim();
        }
        return null;
      },
      // Fallback: 0x0.st
      () async {
        debugPrint('🔄 Trying 0x0.st...');
        final request = http.MultipartRequest('POST', Uri.parse('https://0x0.st'));
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
        final response = await http.Response.fromStream(await request.send());
        if (response.statusCode == 200 && response.body.trim().startsWith('http')) {
          return response.body.trim();
        }
        return null;
      },
    ];

    for (final hostFn in hosts) {
      try {
        final url = await hostFn().timeout(const Duration(seconds: 30));
        if (url != null && url.isNotEmpty) {
          debugPrint('✅ Upload successful: $url');
          return url;
        }
      } catch (e) {
        debugPrint('⚠️ Host failed: $e');
        continue;
      }
    }
    
    return null;
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      debugPrint('📤 Uploading image...');
      
      final bytes = await _imageFile!.readAsBytes();
      final extension = _imageFile!.path.split('.').last.toLowerCase();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      final imageUrl = await _uploadBytesToHost(bytes, fileName);
      
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('All upload services failed. Please try again later.');
      }
      
      setState(() {
        _uploadedImageUrl = imageUrl;
        _imageUrlController.text = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showAddCategoryDialog() async {
    // ignore: use_build_context_synchronously
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Beverages, Snacks',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_categoryController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('categories').add({
                  'name': _categoryController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context, _categoryController.text.trim());
                _categoryController.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _loadCategories();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = _uploadedImageUrl ?? _imageUrlController.text.trim();
      final productId = widget.isEdit ? widget.productId! : _productIdController.text.trim();

      // Check if custom productId already exists (only for new products)
      if (!widget.isEdit && productId.isNotEmpty) {
        final existingDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        
        if (existingDoc.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product ID already exists. Please use a different ID.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }
      // If user pasted a data URL (base64) into the manual URL field, upload it
      if (imageUrl.isNotEmpty && imageUrl.startsWith('data:')) {
        setState(() => _isUploading = true);
        try {
          debugPrint('📤 Detected data URL, uploading decoded bytes...');
          final data = imageUrl;
          final parts = data.split(',');
          final base64Part = parts.length > 1 ? parts[1] : data.replaceFirst(RegExp(r'data:.*;base64,'), '');
          final bytes = base64Decode(base64Part);

          String ext = 'jpg';
          final mimeMatch = RegExp(r'data:image/(.*);base64').firstMatch(data);
          if (mimeMatch != null && mimeMatch.groupCount >= 1) {
            final m = mimeMatch.group(1)!.toLowerCase();
            if (m.contains('png')) ext = 'png';
            else if (m.contains('jpeg') || m.contains('jpg')) ext = 'jpg';
            else if (m.contains('gif')) ext = 'gif';
          }

          final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final uploadedUrl = await _uploadBytesToHost(bytes, fileName);
          
          if (uploadedUrl == null || uploadedUrl.isEmpty) {
            throw Exception('All upload services failed. Please try again later.');
          }
          
          imageUrl = uploadedUrl;
          setState(() {
            _uploadedImageUrl = uploadedUrl;
            _imageUrlController.text = uploadedUrl;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded from base64 successfully!'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          debugPrint('❌ Data-URL upload error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isLoading = false);
          return;
        } finally {
          setState(() => _isUploading = false);
        }
      }

      final productData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory ?? 'Uncategorized',
        'description': _descriptionController.text.trim(),
        'weight': double.tryParse(_weightController.text) ?? 0,
        'weightUnit': _selectedUnit,
        'quantity': double.tryParse(_quantityController.text) ?? 0,
        'quantityUnit': _selectedQuantityUnit,
        'price': double.tryParse(_priceController.text) ?? 0,
        'imageUrl': imageUrl,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isEdit) {
        // Update existing product
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update(productData);
      } else {
        // Create new product
        productData['createdAt'] = FieldValue.serverTimestamp();
        if (productId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .set(productData);
        } else {
          await FirebaseFirestore.instance
              .collection('products')
              .add(productData);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Product updated successfully!' : 'Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Product' : 'Add New Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _productIdController,
              decoration: const InputDecoration(
                labelText: 'Product ID (Optional - Auto-generated if empty)',
                prefixIcon: Icon(Icons.qr_code),
                hintText: 'e.g., PROD001',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                     value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((cat) {
                       return DropdownMenuItem<String>(value: cat, child: Text(cat));
                    }).toList(),
                     onChanged: (value) {
                       setState(() => _selectedCategory = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _showAddCategoryDialog,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                     value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: const [
                      DropdownMenuItem<String>(value: 'kg', child: Text('kg')),
                      DropdownMenuItem<String>(value: 'g', child: Text('g')),
                      DropdownMenuItem<String>(value: 'l', child: Text('l')),
                      DropdownMenuItem<String>(value: 'ml', child: Text('ml')),
                    ],
                     onChanged: (value) {
                       setState(() => _selectedUnit = value ?? 'kg');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                     value: _selectedQuantityUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: const [
                      DropdownMenuItem<String>(value: 'pcs', child: Text('pcs')),
                      DropdownMenuItem<String>(value: 'box', child: Text('box')),
                      DropdownMenuItem<String>(value: 'pack', child: Text('pack')),
                      DropdownMenuItem<String>(value: 'carton', child: Text('carton')),
                    ],
                     onChanged: (value) {
                       setState(() => _selectedQuantityUnit = value ?? 'pcs');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('Product Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_uploadedImageUrl != null || _imageFile != null || _imageUrlController.text.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _uploadedImageUrl != null
                    ? Image.network(_uploadedImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, size: 50));
                      })
                    : _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : _imageUrlController.text.isNotEmpty
                            ? (_imageUrlController.text.trim().startsWith('data:')
                                ? Builder(builder: (context) {
                                    try {
                                      final data = _imageUrlController.text.trim();
                                      final parts = data.split(',');
                                      final bytes = base64Decode(parts.length > 1 ? parts[1] : data);
                                      return Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.broken_image, size: 50));
                                      });
                                    } catch (e) {
                                      return const Center(child: Icon(Icons.broken_image, size: 50));
                                    }
                                  })
                                : Image.network(_imageUrlController.text, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.broken_image, size: 50));
                                  }))
                            : const SizedBox(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: _isUploading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image),
                    label: Text(_isUploading ? 'Uploading...' : 'Pick Image'),
                  ),
                ),
                if (_uploadedImageUrl != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _uploadedImageUrl = null;
                        _imageFile = null;
                        _imageUrlController.clear();
                      });
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Or enter image URL manually:',
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icon(Icons.link),
              ),
              enabled: _uploadedImageUrl == null,
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to show image preview
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createProduct,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
