import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _itemCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _gstRateController = TextEditingController();
  String _selectedUnit = 'kg';
  String _selectedQuantityUnit = 'pcs';
  bool _isLoading = false;
  List<String> _categories = [];
  String? _selectedCategory;

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
    _itemCodeController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _hsnCodeController.dispose();
    _gstRateController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();
      
      setState(() {
        _categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadProductData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _productIdController.text = data['productId'] ?? '';
          _itemCodeController.text = data['itemCode'] ?? '';
          _nameController.text = data['name'] ?? '';
          _weightController.text = (data['weight'] ?? '').toString();
          _quantityController.text = (data['quantity'] ?? '').toString();
          _buyingPriceController.text = (data['buyingPrice'] ?? '').toString();
          _sellingPriceController.text = (data['sellingPrice'] ?? '').toString();
          _categoryController.text = data['category'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _hsnCodeController.text = data['hsnCode'] ?? '';
          _gstRateController.text = (data['gstRate'] ?? '').toString();
          _selectedUnit = data['weightUnit'] ?? 'kg';
          _selectedQuantityUnit = data['quantityUnit'] ?? 'pcs';
          _selectedCategory = data['category'];
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

  Future<void> _showAddCategoryDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final textField = (context as Element)
                  .findAncestorWidgetOfExactType<AlertDialog>()!
                  .content as TextField;
              Navigator.of(context).pop(textField.controller?.text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('categories').add({
          'name': result.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await _loadCategories();
        setState(() {
          _selectedCategory = result.trim();
          _categoryController.text = result.trim();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final buyingPrice = double.tryParse(_buyingPriceController.text) ?? 0.0;
      final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
      final gstRate = double.tryParse(_gstRateController.text) ?? 0.0;

      final productData = {
        'productId': _productIdController.text.trim(),
        'itemCode': _itemCodeController.text.trim(),
        'name': _nameController.text.trim(),
        'weight': _weightController.text.trim(),
        'weightUnit': _selectedUnit,
        'quantity': _quantityController.text.trim(),
        'quantityUnit': _selectedQuantityUnit,
        'buyingPrice': buyingPrice,
        'sellingPrice': sellingPrice,
        'gstRate': gstRate,
        'hsnCode': _hsnCodeController.text.trim(),
        'category': _selectedCategory ?? _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isEdit && widget.productId != null) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(productData);
      } else {
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Product updated successfully!' : 'Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product ID
              TextFormField(
                controller: _productIdController,
                decoration: const InputDecoration(
                  labelText: 'Product ID',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                  helperText: 'Unique identifier for the product',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product ID is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Item Code
              TextFormField(
                controller: _itemCodeController,
                decoration: const InputDecoration(
                  labelText: 'Item Code',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                  helperText: 'Unique item identification code',
                ),
              ),

              const SizedBox(height: 16),

              // HSN Code
              TextFormField(
                controller: _hsnCodeController,
                decoration: const InputDecoration(
                  labelText: 'HSN Code',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(),
                  helperText: 'Harmonized System of Nomenclature Code',
                ),
              ),

              const SizedBox(height: 16),

              // GST Rate
              TextFormField(
                controller: _gstRateController,
                decoration: const InputDecoration(
                  labelText: 'GST Rate (%)',
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                  helperText: 'Goods and Services Tax rate',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddCategoryDialog,
                    tooltip: 'Add new category',
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select Category')),
                  ..._categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    if (value != null) _categoryController.text = value;
                  });
                },
                validator: (value) {
                  if ((value == null || value.isEmpty) && _categoryController.text.trim().isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Weight
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        prefixIcon: Icon(Icons.scale),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: ['kg', 'g', 'lb', 'liter', 'ml']
                          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedUnit = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quantity
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.inventory_2),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedQuantityUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: ['pcs', 'box', 'pack', 'dozen', 'bundle']
                          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedQuantityUnit = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Prices
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Buying Price',
                        prefixIcon: Icon(Icons.shopping_cart),
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                        prefixIcon: Icon(Icons.sell),
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Selling price is required';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.isEdit ? 'Update Product' : 'Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}