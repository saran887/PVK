import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/common_widgets.dart';

// Order item model for better type safety
class OrderItem {
  final String productId;
  final String customProductId;
  final String productName;
  final double price;
  final double buyingPrice;
  final double profit;
  double quantity;

  OrderItem({
    required this.productId,
    required this.customProductId,
    required this.productName,
    required this.price,
    required this.buyingPrice,
    required this.profit,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'customProductId': customProductId,
    'productName': productName,
    'price': price,
    'buyingPrice': buyingPrice,
    'profit': profit,
    'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] ?? '',
    customProductId: map['customProductId'] ?? '',
    productName: map['productName'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    buyingPrice: (map['buyingPrice'] ?? 0).toDouble(),
    profit: (map['profit'] ?? 0).toDouble(),
    quantity: (map['quantity'] ?? 0).toDouble(),
  );
  
  double get total => quantity * price;
}

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedShopId;
  String? _selectedShopName;
  String? _selectedShopLocationId;
  final List<OrderItem> _orderItems = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        actions: [
          if (_orderItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_orderItems.length} items',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildShopSelectionCard(context),
                  const SizedBox(height: 16),
                  _buildOrderItemsCard(context),
                  const SizedBox(height: 16),
                  if (_orderItems.isNotEmpty) _buildOrderSummaryCard(context),
                ],
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildShopSelectionCard(BuildContext context) {
    return Card(
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
            InkWell(
              onTap: _showShopSelectionSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedShopId != null ? Colors.green : Colors.grey,
                    width: _selectedShopId != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedShopId != null ? Colors.green.shade50 : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedShopId != null ? Icons.store : Icons.store_outlined,
                      color: _selectedShopId != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedShopName ?? 'Tap to select shop',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedShopName == null ? Colors.grey[600] : Colors.black,
                          fontWeight: _selectedShopName != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: _selectedShopId != null ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedShopId == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Please select a shop to continue',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context) {
    return Card(
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
                FilledButton.tonalIcon(
                  onPressed: _addOrderItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_orderItems.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                width: double.infinity,
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No items added yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add Item" to start',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ..._orderItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildOrderItemTile(context, index, item);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(BuildContext context, int index, OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.price.toStringAsFixed(2)} per unit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.blue,
                  onPressed: () => _editOrderItem(index),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red,
                  onPressed: () => _removeOrderItem(index),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncate() ? 0 : 2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${item.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    final totalAmount = _calculateTotal();
    final totalItems = _orderItems.length;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.summarize_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Items', style: TextStyle(color: Colors.grey)),
                Text('$totalItems', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isLoading || _orderItems.isEmpty ? null : _createOrder,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showShopSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ShopSelectionSheet(
          scrollController: scrollController,
          onShopSelected: (shopId, shopName, locationId) {
            setState(() {
              _selectedShopId = shopId;
              _selectedShopName = shopName;
              _selectedShopLocationId = locationId;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _addOrderItem() async {
    if (_selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const _SelectProductScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        _orderItems.add(OrderItem.fromMap(result));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added to order'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _editOrderItem(int index) {
    final item = _orderItems[index];
    final quantityController = TextEditingController(text: item.quantity.toStringAsFixed(item.quantity == item.quantity.truncate() ? 0 : 2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.price.toStringAsFixed(2)} per unit',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                setState(() {
                  _orderItems[index].quantity = quantity;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quantity updated'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    return _orderItems.fold(0.0, (sum, item) => sum + item.total);
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

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shop: $_selectedShopName'),
            const SizedBox(height: 8),
            Text('Total Items: ${_orderItems.length}'),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ₹${_calculateTotal().toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider).asData?.value;
      final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      
      await FirebaseFirestore.instance.collection('orders').add({
        'shopId': _selectedShopId,
        'shopName': _selectedShopName,
        'shopLocationId': _selectedShopLocationId ?? '',
        'items': _orderItems.map((item) => item.toMap()).toList(),
        'totalAmount': _calculateTotal(),
        'totalItems': _orderItems.length,
        'status': 'pending',
        'createdBy': userId,
        'createdByName': currentUser?.name ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Order created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

class _SelectProductScreen extends StatefulWidget {
  const _SelectProductScreen();

  @override
  State<_SelectProductScreen> createState() => _SelectProductScreenState();
}

class _SelectProductScreenState extends State<_SelectProductScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Product'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(150),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by name...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              // Category Selection Header
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (context, snapshot) {
                  final categories = snapshot.data?.docs ?? [];
                  
                  return SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All Products'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = null);
                            },
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: _selectedCategory == null ? Colors.blue.shade900 : Colors.black87,
                              fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          ))
                        else
                          ...categories.map((cat) {
                            final data = cat.data() as Map<String, dynamic>?;
                            final name = data?['name'] ?? 'Unknown';
                            final isSelected = _selectedCategory == name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? name : null;
                                  });
                                },
                                selectedColor: Colors.blue.shade100,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var products = snapshot.data!.docs;

          // Filter by category
          if (_selectedCategory != null) {
            products = products.where((product) {
              final data = product.data() as Map<String, dynamic>;
              return data['category'] == _selectedCategory;
            }).toList();
          }

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            products = products.where((product) {
              final data = product.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery);
            }).toList();
          }

          // Sort by name
          products.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aName = aData['name'] ?? '';
            final bName = bData['name'] ?? '';
            return aName.compareTo(bName);
          });

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No products found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              final customProductId = product['productId'] ?? '';
              final name = product['name'] ?? 'Unknown';
              final price = (product['sellingPrice'] ?? 0).toDouble();
              final buyingPrice = (product['buyingPrice'] ?? 0).toDouble();
              final category = product['category'] ?? '';
              final stock = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
              final stockColor = stock < 10 ? Colors.red : (stock < 50 ? Colors.orange : Colors.green);
              final quantityUnit = product['quantityUnit'] ?? 'pcs';

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    _showQuantityDialog(context, productId, customProductId, name, price, buyingPrice);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (customProductId.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'ID: $customProductId',
                                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (category.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                category,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.inventory_2, size: 12, color: stockColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Stock: $stock $quantityUnit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: stockColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, String productId, String customProductId, String productName, double price, double buyingPrice) {
    double currentQuantity = 1;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(productName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (customProductId.isNotEmpty)
                  Text(
                    'Product ID: $customProductId',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                const SizedBox(height: 8),
                Text(
                  '₹${price.toStringAsFixed(2)} per unit',
                  style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        if (currentQuantity > 1) {
                          setState(() {
                            currentQuantity--;
                            quantityController.text = currentQuantity.toStringAsFixed(0); // Assuming integer for now, or remove fixed(0) if float needed
                          });
                        }
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: quantityController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          final val = double.tryParse(value);
                          if (val != null) {
                            currentQuantity = val;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          currentQuantity++;
                          quantityController.text = currentQuantity.toStringAsFixed(0);
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 20, 50].map((val) {
                    return ActionChip(
                      label: Text('+$val'),
                      onPressed: () {
                        setState(() {
                          currentQuantity += val;
                          quantityController.text = currentQuantity.toStringAsFixed(0);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (currentQuantity > 0) {
                    Navigator.pop(context);
                    Navigator.pop(context, {
                      'productId': productId,
                      'customProductId': customProductId,
                      'productName': productName,
                      'price': price,
                      'buyingPrice': buyingPrice,
                      'profit': price - buyingPrice,
                      'quantity': currentQuantity,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid quantity'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopSelectionSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(String, String, String?) onShopSelected;

  const _ShopSelectionSheet({
    required this.scrollController,
    required this.onShopSelected,
  });

  @override
  ConsumerState<_ShopSelectionSheet> createState() => _ShopSelectionSheetState();
}

class _ShopSelectionSheetState extends ConsumerState<_ShopSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final userLocationId = currentUser?.locationId ?? '';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: userLocationId.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('shops')
                    .where('locationId', isEqualTo: userLocationId)
                    .orderBy('name')
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('shops')
                    .orderBy('name')
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var shops = snapshot.data!.docs;

              if (_searchQuery.isNotEmpty) {
                shops = shops.where((shop) {
                  final data = shop.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();
              }

              if (shops.isEmpty) {
                return const Center(
                  child: Text('No shops found'),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index].data() as Map<String, dynamic>;
                  final shopId = shops[index].id;
                  final name = shop['name'] ?? 'Unknown';
                  final address = shop['address'] ?? '';
                  final locationId = shop['locationId'] as String?;

                  return ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: address.isNotEmpty ? Text(address) : null,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                    ),
                    onTap: () => widget.onShopSelected(shopId, name, locationId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
