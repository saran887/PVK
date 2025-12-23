import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color.alphaBlend(Colors.purple.withAlpha((0.1 * 255).toInt()), Colors.white),
                      child: const Icon(Icons.business_center, size: 30, color: Colors.purple),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome,', style: Theme.of(context).textTheme.bodySmall),
                          Text(user?.name ?? 'Owner', style: Theme.of(context).textTheme.titleLarge),
                          Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Business Overview Section
            Text('Business Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildOverviewStats(),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text('Management', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildManagementGrid(context),
            const SizedBox(height: 24),

            // Reports & Analytics Section
            Text('Reports & Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildReportsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _combineStreams([
        FirebaseFirestore.instance.collection('orders').snapshots(),
        FirebaseFirestore.instance.collection('products').snapshots(),
        FirebaseFirestore.instance.collection('shops')
            .where('isActive', isEqualTo: true)
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data?[0].docs ?? [];
        final allProducts = snapshot.data?[1].docs ?? [];
        final activeShops = snapshot.data?[2].docs.length ?? 0;

        // Calculate revenue metrics
        double totalRevenue = 0;
        double todayRevenue = 0;
        int todayOrders = 0;
        double pendingPayments = 0;
        int lowStockCount = 0;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        for (var order in allOrders) {
          final data = order.data() as Map;
          final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final paymentStatus = data['paymentStatus'] ?? 'pending';

          // Only count paid orders in revenue
          if (paymentStatus == 'paid') {
            totalRevenue += amount;
          }

          if (paymentStatus != 'paid') {
            pendingPayments += amount;
          }

          if (createdAt != null && createdAt.isAfter(todayStart)) {
            if (paymentStatus == 'paid') {
              todayRevenue += amount;
            }
            todayOrders++;
          }
        }

        // Count low stock products
        for (var product in allProducts) {
          final data = product.data() as Map;
          final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
          final isActive = data['isActive'] ?? true;
          if (quantity < 10 && isActive) {
            lowStockCount++;
          }
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _StatCard(
              icon: Icons.currency_rupee,
              title: 'Total Revenue',
              value: '₹${(totalRevenue / 1000).toStringAsFixed(1)}K',
              color: Colors.green,
              subtitle: 'All time',
            ),
            _StatCard(
              icon: Icons.today,
              title: 'Today\'s Revenue',
              value: '₹${todayRevenue.toStringAsFixed(0)}',
              color: Colors.blue,
              subtitle: '$todayOrders orders',
            ),
            _StatCard(
              icon: Icons.pending_actions,
              title: 'Pending Payments',
              value: '₹${(pendingPayments / 1000).toStringAsFixed(1)}K',
              color: Colors.orange,
              subtitle: 'Outstanding',
            ),
            _StatCard(
              icon: Icons.warning_amber,
              title: 'Low Stock Alert',
              value: lowStockCount.toString(),
              color: lowStockCount > 0 ? Colors.red : Colors.grey,
              subtitle: lowStockCount > 0 ? 'Items < 10' : 'All stocked',
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _QuickActionCard(
          icon: Icons.people_alt,
          title: 'User Analytics',
          color: Colors.blue,
          onTap: () => GoRouter.of(context).push('/owner/users'),
        ),
        _QuickActionCard(
          icon: Icons.store_mall_directory,
          title: 'Shop Performance',
          color: Colors.green,
          onTap: () => GoRouter.of(context).push('/owner/shops'),
        ),
        _QuickActionCard(
          icon: Icons.inventory_2,
          title: 'Product Insights',
          color: Colors.orange,
          onTap: () => GoRouter.of(context).push('/owner/products'),
        ),
        _QuickActionCard(
          icon: Icons.account_balance_wallet,
          title: 'Salary Management',
          color: Colors.purple,
          onTap: () => GoRouter.of(context).push('/owner/salary'),
        ),
      ],
    );
  }

  Widget _buildReportsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _QuickActionCard(
          icon: Icons.analytics,
          title: 'Business Analytics',
          color: Colors.teal,
          onTap: () => GoRouter.of(context).push('/owner/analytics'),
        ),
        _QuickActionCard(
          icon: Icons.receipt_long,
          title: 'Expenses',
          color: Colors.indigo,
          onTap: () => GoRouter.of(context).push('/owner/expenses'),
        ),
        _QuickActionCard(
          icon: Icons.person_add,
          title: 'Add User',
          color: Colors.cyan,
          onTap: () => GoRouter.of(context).push('/admin/add-person'),
        ),
        _QuickActionCard(
          icon: Icons.add_business,
          title: 'Add Shop',
          color: Colors.lime,
          onTap: () => GoRouter.of(context).push('/admin/add-shop'),
        ),
      ],
    );
  }

  Stream<List<QuerySnapshot>> _combineStreams(List<Stream<QuerySnapshot>> streams) {
    return Stream.periodic(const Duration(milliseconds: 500))
        .asyncMap((_) => Future.wait(streams.map((s) => s.first)));
  }
}

// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: color),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
