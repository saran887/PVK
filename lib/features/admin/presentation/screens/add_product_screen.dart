import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

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

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      debugPrint('📤 Uploading image...');
      
      // Read file as bytes
      final bytes = await _imageFile!.readAsBytes();
      
      // Get file extension
      final extension = _imageFile!.path.split('.').last.toLowerCase();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      // Upload to postimg.cc (free, no API key needed)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://postimg.cc/json'),
      );
      
      request.fields['upload_session'] = DateTime.now().millisecondsSinceEpoch.toString();
      request.fields['numfiles'] = '1';
      request.fields['gallery'] = '';
      request.fields['ui'] = 'json';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );
      
      debugPrint('🔄 Sending upload request...');
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - Please check your internet connection');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // PostImg returns the direct image URL
        final imageUrl = data['url'] ?? '';
        
        if (imageUrl.isEmpty) {
          throw Exception('No image URL in response');
        }
        
        debugPrint('✅ Image uploaded: $imageUrl');
        
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
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
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
      final imageUrl = _uploadedImageUrl ?? _imageUrlController.text.trim();
      final productId = _productIdController.text.trim();

      // Check if custom productId already exists
      if (productId.isNotEmpty) {
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
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
        title: const Text('Add New Product'),
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
                            ? Image.network(_imageUrlController.text, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, size: 50));
                              })
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
