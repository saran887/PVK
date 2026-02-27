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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Product' : 'Add New Product'),
        elevation: 0,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PRODUCT DETAILS SECTION ---
              _buildSectionHeader('Product Details', Icons.inventory),
              _buildSectionCard([
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'e.g. Basmati Rice 5kg',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Product name is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _showAddCategoryDialog,
                      tooltip: 'Add new category',
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Category')),
                    ..._categories.map((category) => DropdownMenuItem(value: category, child: Text(category))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      if (value != null) _categoryController.text = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  maxLines: 2,
                ),
              ]),

              // --- IDENTIFICATION SECTION ---
              _buildSectionHeader('Identification', Icons.qr_code),
              _buildSectionCard([
                TextFormField(
                  controller: _productIdController,
                  decoration: const InputDecoration(
                    labelText: 'Product ID / Barcode',
                    prefixIcon: Icon(Icons.qr_code_scanner),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Product ID is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _itemCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code',
                    prefixIcon: Icon(Icons.tag),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ]),

              // --- INVENTORY SECTION ---
              _buildSectionHeader('Inventory & Stock', Icons.inventory_2),
              _buildSectionCard([
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          prefixIcon: Icon(Icons.scale),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedQuantityUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        items: ['pcs', 'box', 'pack', 'dozen', 'bundle']
                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedQuantityUnit = value!),
                      ),
                    ),
                  ],
                ),
              ]),

              // --- PRICING & TAX SECTION ---
              _buildSectionHeader('Pricing & Tax', Icons.payments),
              _buildSectionCard([
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Buying Price',
                          prefixIcon: Icon(Icons.input),
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Selling price is required';
                          if (double.tryParse(value) == null) return 'Invalid amount';
                          return null;
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
                        controller: _hsnCodeController,
                        decoration: const InputDecoration(
                          labelText: 'HSN Code',
                          prefixIcon: Icon(Icons.list_alt),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _gstRateController,
                        decoration: const InputDecoration(
                          labelText: 'GST %',
                          prefixIcon: Icon(Icons.percent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.isEdit ? 'UPDATE PRODUCT' : 'SAVE PRODUCT',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
          ),
        ),
      ),
    );
  }
}