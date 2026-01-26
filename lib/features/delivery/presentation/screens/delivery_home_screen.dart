import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';

class DeliveryHomeScreen extends ConsumerWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          final orders = snapshot.data?.docs ?? [];

          int readyCount = 0;
          int inTransitCount = 0;
          int deliveredToday = 0;
          int pendingDelivery = 0;

          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          for (final order in orders) {
            final data = order.data() as Map<String, dynamic>;
            final status = (data['status'] as String? ?? '').toLowerCase();
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            if (status == 'out_for_delivery' || status == 'ready_for_delivery') {
              readyCount++;
            }
            if (status == 'in_transit' || status == 'out_for_delivery') {
              inTransitCount++;
            }
            if (status == 'delivered' && createdAt != null && createdAt.isAfter(todayStart)) {
              deliveredToday++;
            }
            if (status == 'billed' || status == 'confirmed') {
              pendingDelivery++;
            }
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                floating: false,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade200,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    Text(
                                      user?.name ?? 'Delivery Partner',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications - Coming soon!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black87),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                        children: [
                          _DeliveryStatCard(
                            icon: Icons.inventory_2_rounded,
                            title: 'Ready to Deliver',
                            value: readyCount.toString(),
                          ),
                          _DeliveryStatCard(
                            icon: Icons.local_shipping_rounded,
                            title: 'In Transit',
                            value: inTransitCount.toString(),
                          ),
                          _DeliveryStatCard(
                            icon: Icons.check_circle_rounded,
                            title: 'Delivered Today',
                            value: deliveredToday.toString(),
                          ),
                          _DeliveryStatCard(
                            icon: Icons.pending_actions_rounded,
                            title: 'Pending Delivery',
                            value: pendingDelivery.toString(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        children: [
                          _ActionCard(
                            icon: Icons.inventory_rounded,
                            title: 'Ready to Deliver',
                            subtitle: 'View assigned orders',
                            onTap: () => context.push('/delivery/ready-to-deliver'),
                          ),
                          _ActionCard(
                            icon: Icons.history_rounded,
                            title: 'Delivery History',
                            subtitle: 'View completed trips',
                            onTap: () => context.push('/delivery/history'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Ready to Deliver',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReadyOrdersPreview(orders: orders),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeliveryStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DeliveryStatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  Color _getIconColor() {
    if (icon == Icons.inventory_2_rounded) return Colors.orange.shade600;
    if (icon == Icons.local_shipping_rounded) return Colors.blue.shade600;
    if (icon == Icons.check_circle_rounded) return Colors.green.shade600;
    if (icon == Icons.pending_actions_rounded) return Colors.amber.shade600;
    return Colors.grey.shade600;
  }

  Color _getBackgroundColor() {
    if (icon == Icons.inventory_2_rounded) return Colors.orange.shade50;
    if (icon == Icons.local_shipping_rounded) return Colors.blue.shade50;
    if (icon == Icons.check_circle_rounded) return Colors.green.shade50;
    if (icon == Icons.pending_actions_rounded) return Colors.amber.shade50;
    return Colors.grey.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: _getIconColor()),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  Color _getIconColor() {
    if (icon == Icons.inventory_rounded) return Colors.orange.shade600;
    if (icon == Icons.history_rounded) return Colors.indigo.shade600;
    return Colors.blue.shade600;
  }

  Color _getBackgroundColor() {
    if (icon == Icons.inventory_rounded) return Colors.orange.shade50;
    if (icon == Icons.history_rounded) return Colors.indigo.shade50;
    return Colors.blue.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: _getBackgroundColor(),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: _getIconColor()),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyOrdersPreview extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;

  const _ReadyOrdersPreview({required this.orders});

  @override
  Widget build(BuildContext context) {
    final readyOrders = orders.where((order) {
      final data = order.data() as Map<String, dynamic>;
      final status = (data['status'] as String? ?? '').toLowerCase();
      return status == 'out_for_delivery' || status == 'ready_for_delivery';
    }).toList();

    if (readyOrders.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.inventory_outlined, size: 28, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No orders ready to deliver',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () => GoRouter.of(context).push('/delivery/ready-to-deliver'),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
      );
    }

    final preview = readyOrders.take(4).toList();

    return Column(
      children: [
        ...preview.map((order) {
          final data = order.data() as Map<String, dynamic>;
          final shopName = data['shopName'] as String? ?? 'Unknown Shop';
          final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final items = (data['items'] as List?)?.length ?? 0;
          final status = (data['status'] as String? ?? '').toLowerCase();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: status == 'out_for_delivery' 
                    ? Colors.blue.shade50 
                    : Colors.orange.shade50,
                child: Icon(
                  status == 'out_for_delivery' ? Icons.local_shipping : Icons.inventory,
                  color: status == 'out_for_delivery' 
                      ? Colors.blue.shade600 
                      : Colors.orange.shade600,
                ),
              ),
              title: Text(shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('$items items • ₹${totalAmount.toStringAsFixed(0)}'),
              trailing: TextButton(
                onPressed: () => GoRouter.of(context).push('/delivery/ready-to-deliver'),
                child: const Text('Details'),
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => GoRouter.of(context).push('/delivery/ready-to-deliver'),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('View all ready orders'),
        ),
      ],
    );
  }
}
