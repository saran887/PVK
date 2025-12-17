import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

                final totalUsers = usersSnapshot.data!.docs.length;
                final activeUsers = usersSnapshot.data!.docs
                    .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false)
                    .length;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('shops').snapshots(),
                  builder: (context, shopsSnapshot) {
                    if (!shopsSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final totalShops = shopsSnapshot.data!.docs.length;
                    final activeShops = shopsSnapshot.data!.docs
                        .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false)
                        .length;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').snapshots(),
                      builder: (context, productsSnapshot) {
                        if (!productsSnapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final totalProducts = productsSnapshot.data!.docs.length;
                        final activeProducts = productsSnapshot.data!.docs
                            .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false)
                            .length;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, ordersSnapshot) {
                            if (!ordersSnapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final totalOrders = ordersSnapshot.data!.docs.length;
                            final pendingOrders = ordersSnapshot.data!.docs
                                .where((doc) => doc['status'] == 'pending' || doc['status'] == 'confirmed')
                                .length;
                            final processedOrders = ordersSnapshot.data!.docs
                                .where((doc) => doc['status'] == 'billed')
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
                                          count: ordersSnapshot.data!.docs
                                              .where((doc) => doc['status'] == 'pending')
                                              .length,
                                          color: Colors.orange,
                                        ),
                                        const Divider(),
                                        _OrderStatusRow(
                                          status: 'Confirmed',
                                          count: ordersSnapshot.data!.docs
                                              .where((doc) => doc['status'] == 'confirmed')
                                              .length,
                                          color: Colors.blue,
                                        ),
                                        const Divider(),
                                        _OrderStatusRow(
                                          status: 'Billed',
                                          count: processedOrders,
                                          color: Colors.green,
                                        ),
                                        const Divider(),
                                        _OrderStatusRow(
                                          status: 'Delivered',
                                          count: ordersSnapshot.data!.docs
                                              .where((doc) => doc['status'] == 'delivered')
                                              .length,
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
                                      .limit(5)
                                      .snapshots(),
                                  builder: (context, recentOrdersSnapshot) {
                                    if (!recentOrdersSnapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }

                                    return Card(
                                      child: Column(
                                        children: recentOrdersSnapshot.data!.docs.map((order) {
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