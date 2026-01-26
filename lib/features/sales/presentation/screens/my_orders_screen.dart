import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  String _selectedFilter = 'all'; // all, pending, billed, delivered

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final userLocationId = user?.locationId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'all',
                    onSelected: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pending',
                    isSelected: _selectedFilter == 'pending',
                    onSelected: () => setState(() => _selectedFilter = 'pending'),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Billed',
                    isSelected: _selectedFilter == 'billed',
                    onSelected: () => setState(() => _selectedFilter = 'billed'),
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Delivered',
                    isSelected: _selectedFilter == 'delivered',
                    onSelected: () => setState(() => _selectedFilter = 'delivered'),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (userLocationId.isNotEmpty
            ? FirebaseFirestore.instance
              .collection('orders')
              .where('shopLocationId', isEqualTo: userLocationId)
            : FirebaseFirestore.instance.collection('orders'))
          .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data?.docs ?? [];

          // Filter by status
          if (_selectedFilter != 'all') {
            orders = orders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] ?? 'pending').toString().toLowerCase();
              return status == _selectedFilter;
            }).toList();
          }

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'all' ? 'No orders found' : 'No $_selectedFilter orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first order to get started',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index].data() as Map<String, dynamic>;
                final orderId = orders[index].id;
                final shopName = order['shopName'] ?? 'Unknown Shop';
                final totalAmount = order['totalAmount'] ?? 0;
                final totalItems = order['totalItems'] ?? 0;
                final status = order['status'] ?? 'pending';
                final createdAt = order['createdAt'] as Timestamp?;
                final items = order['items'] as List<dynamic>? ?? [];

                String formattedDate = 'N/A';
                if (createdAt != null) {
                  final date = createdAt.toDate();
                  formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);
                }

                Color statusColor;
                IconData statusIcon;
                switch (status.toLowerCase()) {
                  case 'pending':
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending;
                    break;
                  case 'confirmed':
                    statusColor = Colors.blue;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'billed':
                    statusColor = Colors.purple;
                    statusIcon = Icons.receipt;
                    break;
                  case 'dispatched':
                    statusColor = Colors.indigo;
                    statusIcon = Icons.local_shipping;
                    break;
                  case 'delivered':
                    statusColor = Colors.green;
                    statusIcon = Icons.done_all;
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.info;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    _showOrderDetails(context, orderId, order);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shopName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Order #${orderId.substring(0, 8).toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 14, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.shopping_bag, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              '$totalItems items',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
    );
  }

  void _showOrderDetails(BuildContext context, String orderId, Map<String, dynamic> order) {
    final shopName = order['shopName'] ?? 'Unknown Shop';
    final totalAmount = order['totalAmount'] ?? 0;
    final totalItems = order['totalItems'] ?? 0;
    final status = order['status'] ?? 'pending';
    final createdAt = order['createdAt'] as Timestamp?;
    final items = order['items'] as List<dynamic>? ?? [];

    String formattedDate = 'N/A';
    if (createdAt != null) {
      final date = createdAt.toDate();
      formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order #${orderId.substring(0, 8).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                shopName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${status.toUpperCase()}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                    ...items.map((item) {
                      final productName = item['productName'] ?? 'Unknown Product';
                      final quantity = item['quantity'] ?? 0;
                      final price = item['price'] ?? 0;
                      final subtotal = quantity * price;
                      final productId = item['productId'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.inventory_2, size: 20, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: $quantity × ₹${price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
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
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(Icons.warehouse, size: 12, color: stockColor),
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
                              Text(
                                '₹${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).primaryColor;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}
