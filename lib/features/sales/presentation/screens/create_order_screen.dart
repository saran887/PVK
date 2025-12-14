import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedShopId;
  String? _selectedShopName;
  final List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Shop Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Shop',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('shops')
                                .orderBy('name')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }

                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final shops = snapshot.data!.docs;

                              if (shops.isEmpty) {
                                return const Text('No shops available');
                              }

                              return DropdownButtonFormField<String>(
                                value: _selectedShopId,
                                decoration: const InputDecoration(
                                  labelText: 'Shop',
                                  prefixIcon: Icon(Icons.store),
                                  border: OutlineInputBorder(),
                                ),
                                items: shops.map((shop) {
                                  final data = shop.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: shop.id,
                                    child: Text(data['name'] ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedShopId = value;
                                    final selectedShop = shops.firstWhere((s) => s.id == value);
                                    final data = selectedShop.data() as Map<String, dynamic>;
                                    _selectedShopName = data['name'] ?? 'Unknown';
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a shop';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Order Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order Items',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addOrderItem,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_orderItems.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No items added yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ..._orderItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(item['productName'] ?? 'Unknown'),
                                  subtitle: Text(
                                    'Qty: ${item['quantity']} × ₹${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${((item['quantity'] ?? 0) * (item['price'] ?? 0)).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _orderItems.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Order Summary
                  if (_orderItems.isNotEmpty)
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Items:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${_orderItems.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₹${_calculateTotal().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _orderItems.isEmpty || _isLoading ? null : _createOrder,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Order'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addOrderItem() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddOrderItemDialog(),
    );

    if (result != null) {
      setState(() {
        _orderItems.add(result);
      });
    }
  }

  double _calculateTotal() {
    return _orderItems.fold(
      0.0,
      (sum, item) => sum + ((item['quantity'] ?? 0) * (item['price'] ?? 0)),
    );
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate() || _orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop and add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'shopId': _selectedShopId,
        'shopName': _selectedShopName,
        'items': _orderItems,
        'totalAmount': _calculateTotal(),
        'totalItems': _orderItems.length,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _AddOrderItemDialog extends StatefulWidget {
  const _AddOrderItemDialog();

  @override
  State<_AddOrderItemDialog> createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<_AddOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  String? _selectedProductName;
  double? _selectedProductPrice;
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Order Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('isActive', isEqualTo: true)
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final products = snapshot.data!.docs;

                  if (products.isEmpty) {
                    return const Text('No products available');
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                    items: products.map((product) {
                      final data = product.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final price = data['price'] ?? 0;
                      return DropdownMenuItem<String>(
                        value: product.id,
                        child: Text('$name - ₹${price.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                        final selectedProduct = products.firstWhere((p) => p.id == value);
                        final data = selectedProduct.data() as Map<String, dynamic>;
                        _selectedProductName = data['name'] ?? 'Unknown';
                        _selectedProductPrice = (data['price'] ?? 0).toDouble();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a product';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter valid quantity';
                  }
                  return null;
                },
              ),
              if (_selectedProductPrice != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '₹${((_selectedProductPrice ?? 0) * (double.tryParse(_quantityController.text) ?? 0)).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'productId': _selectedProductId,
                'productName': _selectedProductName,
                'price': _selectedProductPrice,
                'quantity': double.parse(_quantityController.text),
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
