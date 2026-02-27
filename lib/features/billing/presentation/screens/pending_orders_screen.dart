import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_provider.dart';
import '../utils/bill_generator.dart';

class PendingOrdersScreen extends ConsumerStatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  ConsumerState<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends ConsumerState<PendingOrdersScreen> {
  String? selectedLocationId;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final userLocationId = currentUser?.locationId ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pending Orders'),
        elevation: 0,
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Location Selector
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('locations').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final locations = snapshot.data!.docs.map((doc) {
                    return {
                      'id': doc.id,
                      'name': doc['name'] ?? 'Unknown',
                    };
                  }).toList();

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedLocationId,
                      decoration: InputDecoration(
                        labelText: 'Select Location',
                        prefixIcon: Icon(Icons.location_on, color: Colors.orange.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Locations'),
                        ),
                        ...locations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location['id'],
                            child: Text(location['name']!),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedLocationId = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var orders = snapshot.data!.docs;

                // Filter by status (pending/confirmed) and location
                orders = orders.where((order) {
                  final data = order.data() as Map<String, dynamic>;
                  final status = data['status'] as String?;
                  
                  // Only show pending and confirmed orders
                  if (status != 'pending' && status != 'confirmed') {
                    return false;
                  }
                  
                  // Filter by selected location or user location
                  final shopLocationId = data['shopLocationId'] as String?;
                  if (selectedLocationId != null) {
                    return shopLocationId == selectedLocationId;
                  } else if (userLocationId.isNotEmpty) {
                    return shopLocationId == null || shopLocationId.isEmpty || shopLocationId == userLocationId;
                  }
                  
                  return true;
                }).toList();

                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No pending orders', style: TextStyle(color: Colors.grey, fontSize: 18)),
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
                    final status = order['status'] ?? 'pending';
                    final totalAmount = (order['totalAmount'] ?? 0).toDouble();
                    final totalItems = order['totalItems'] ?? 0;
                    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        onTap: () {
                          _showOrderDetails(context, orderId, order);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Shop Name & Amount
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shopName,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${orderId.substring(0, 8)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            fontFamily: 'Monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${totalAmount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'pending' 
                                            ? Colors.orange.shade100 
                                            : Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: status == 'pending' 
                                              ? Colors.orange.shade800 
                                              : Colors.blue.shade800,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Info Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.grey[700]),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$totalItems Items',
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (createdAt != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, size: 18, color: Colors.grey[700]),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('dd MMM, hh:mm a').format(createdAt),
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              
                              // Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: FilledButton.icon(
                                        onPressed: () {
                                          _processBilling(context, orderId, order);
                                        },
                                        icon: const Icon(Icons.check_circle_outline),
                                        label: const Text(
                                          'MARK BILLED',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: IconButton.filledTonal(
                                      onPressed: () async {
                                        await BillGenerator.generateAndShare(
                                          context: context,
                                          orderId: orderId,
                                          order: order,
                                        );
                                      },
                                      icon: const Icon(Icons.share),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        foregroundColor: Colors.blue.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, String orderId, Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  order['shopName'] ?? 'Order Details',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: $orderId',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      final quantity = (item['quantity'] ?? 0).toDouble();
                      final price = (item['price'] ?? 0).toDouble();
                      final subtotal = quantity * price;

                      return ListTile(
                        title: Text(item['productName'] ?? 'Unknown'),
                        subtitle: Text('${quantity.toStringAsFixed(0)} Ã— ₹${price.toStringAsFixed(2)}'),
                        trailing: Text(
                          '₹${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _processBilling(BuildContext context, String orderId, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Billing'),
        content: Text(
          'Mark this order as billed?\n\nShop: ${order['shopName']}\nAmount: ₹${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                  'status': 'billed',
                  'billedAt': FieldValue.serverTimestamp(),
                });
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order marked as billed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
