import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_provider.dart';

class DeliveryHistoryScreen extends ConsumerWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final userLocationId = currentUser?.locationId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'delivered')
            .orderBy('deliveredAt', descending: true)
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
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history, size: 64, color: Colors.indigo.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Text('No delivery history', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
              final deliveredAt = order['deliveredAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                  ),
                  title: Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Order ID: ${orderId.substring(0, 8)}...'),
                      Text('Items: $totalItems | Amount: ₹${totalAmount.toStringAsFixed(2)}'),
                      if (deliveredAt != null)
                        Text('Delivered: ${DateFormat('dd MMM yyyy, hh:mm a').format(deliveredAt.toDate())}',
                          style: const TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._buildOrderItems(order['items'] as List<dynamic>? ?? []),
                        ],
                      ),
                    ),
                  ],
                ),
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
}
