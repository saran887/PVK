import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? selectedLocationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('locations').snapshots(),
                            builder: (context, locationsSnapshot) {
                              if (!locationsSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final locations = locationsSnapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return {
                                  'id': doc.id,
                                  'name': data['name'] ?? 'Unknown',
                                };
                              }).toList();

                              return DropdownButtonFormField<String>(
                                initialValue: selectedLocationId,
                                decoration: const InputDecoration(
                                  labelText: 'Filter by Location',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Locations'),
                                  ),
                                  ...locations.map((location) {
                                    return DropdownMenuItem<String>(
                                      value: location['id'],
                                      child: Text(location['name']),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedLocationId = value;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                if (!usersSnapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                var users = usersSnapshot.data!.docs;
                if (selectedLocationId != null) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['locationId'] == selectedLocationId;
                  }).toList();
                }

                final totalUsers = users.length;
                final activeUsers = users
                    .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false)
                    .length;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('shops').snapshots(),
                  builder: (context, shopsSnapshot) {
                    if (!shopsSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    var shops = shopsSnapshot.data!.docs;
                    if (selectedLocationId != null) {
                      shops = shops.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['locationId'] == selectedLocationId;
                      }).toList();
                    }

                    final totalShops = shops.length;
                    final activeShops = shops
                        .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false)
                        .length;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').snapshots(),
                      builder: (context, productsSnapshot) {
                        if (!productsSnapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        var products = productsSnapshot.data!.docs;
                        if (selectedLocationId != null) {
                          products = products.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return data['locationId'] == selectedLocationId;
                          }).toList();
                        }

                        final totalProducts = products.length;
                        final activeProducts = products
                            .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false)
                            .length;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, ordersSnapshot) {
                            if (!ordersSnapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            var orders = ordersSnapshot.data!.docs;
                            
                            // Filter by selected location
                            if (selectedLocationId != null) {
                              orders = orders.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return data['shopLocationId'] == selectedLocationId;
                              }).toList();
                            }

                            final totalOrders = orders.length;
                            final pendingOrders = orders
                                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending')
                                .length;
                            final confirmedOrders = orders
                                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'confirmed')
                                .length;
                            final billedOrders = orders
                                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'billed')
                                .length;
                            final deliveredOrders = orders
                                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'delivered')
                                .length;

                            return Column(
                              children: [
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1,
                                  children: [
                                    _StatCard(
                                      title: 'Total Users',
                                      value: totalUsers.toString(),
                                      subtitle: 'Active: $activeUsers',
                                      color: Colors.blue,
                                      icon: Icons.people,
                                    ),
                                    _StatCard(
                                      title: 'Total Shops',
                                      value: totalShops.toString(),
                                      subtitle: 'Active: $activeShops',
                                      color: Colors.green,
                                      icon: Icons.store,
                                    ),
                                    _StatCard(
                                      title: 'Total Products',
                                      value: totalProducts.toString(),
                                      subtitle: 'Active: $activeProducts',
                                      color: Colors.orange,
                                      icon: Icons.inventory,
                                    ),
                                    _StatCard(
                                      title: 'Total Orders',
                                      value: totalOrders.toString(),
                                      subtitle: 'Pending: $pendingOrders',
                                      color: Colors.purple,
                                      icon: Icons.shopping_cart,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Order Status Breakdown',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _OrderStatusRow(
                                          status: 'Pending',
                                          count: pendingOrders,
                                          color: Colors.orange,
                                        ),
                                        const Divider(),
                                        _OrderStatusRow(
                                          status: 'Confirmed',
                                          count: confirmedOrders,
                                          color: Colors.blue,
                                        ),
                                        const Divider(),
                                        _OrderStatusRow(
                                          status: 'Billed',
                                          count: billedOrders,
                                          color: Colors.green,
                                        ),
                                        const Divider(),
                                        _OrderStatusRow(
                                          status: 'Delivered',
                                          count: deliveredOrders,
                                          color: Colors.teal,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Recent Activity',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('orders')
                                      .orderBy('createdAt', descending: true)
                                      .limit(20)
                                      .snapshots(),
                                  builder: (context, recentOrdersSnapshot) {
                                    if (!recentOrdersSnapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }

                                    var recentOrders = recentOrdersSnapshot.data!.docs;
                                    
                                    // Apply the same filters as the main analytics
                                    if (selectedLocationId != null) {
                                      recentOrders = recentOrders.where((doc) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        return data['shopLocationId'] == selectedLocationId;
                                      }).toList();
                                    }

                                    // Take only the first 5 after filtering
                                    recentOrders = recentOrders.take(5).toList();

                                    return Card(
                                      child: Column(
                                        children: recentOrders.map((order) {
                                          final data = order.data() as Map<String, dynamic>;
                                          final shopName = data['shopName'] ?? 'Unknown Shop';
                                          final status = data['status'] ?? 'pending';
                                          final totalAmount = (data['totalAmount'] ?? 0).toDouble();
                                          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                                          return ListTile(
                                            title: Text(shopName),
                                            subtitle: Text(
                                              'Order ID: ${order.id.substring(0, 8)} • ${createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : 'Unknown date'}',
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '₹${totalAmount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: status == 'pending'
                                                        ? Colors.orange
                                                        : status == 'confirmed'
                                                            ? Colors.blue
                                                            : status == 'billed'
                                                                ? Colors.green
                                                                : Colors.teal,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    status.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusRow extends StatelessWidget {
  final String status;
  final int count;
  final Color color;

  const _OrderStatusRow({
    required this.status,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}