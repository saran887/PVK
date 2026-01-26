import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:pkv2/features/auth/providers/auth_provider.dart';
import 'package:pkv2/shared/widgets/common_widgets.dart';

/// Provider for owner dashboard statistics
final ownerStatsProvider = StreamProvider<OwnerStats>((ref) {
  final ordersStream = FirebaseFirestore.instance.collection('orders').snapshots();
  final productsStream = FirebaseFirestore.instance.collection('products').snapshots();
  final shopsStream = FirebaseFirestore.instance
      .collection('shops')
      .where('isActive', isEqualTo: true)
      .snapshots();

  return Rx.combineLatest3(
    ordersStream,
    productsStream,
    shopsStream,
    (QuerySnapshot orders, QuerySnapshot products, QuerySnapshot shops) {
      double totalRevenue = 0;
      double todayRevenue = 0;
      int todayOrders = 0;
      int lowStockCount = 0;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      for (var order in orders.docs) {
        final data = order.data() as Map<String, dynamic>;
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final status = data['status'] ?? 'pending';

        if (status != 'cancelled') {
          totalRevenue += amount;
          if (createdAt != null && createdAt.isAfter(todayStart)) {
            todayRevenue += amount;
            todayOrders++;
          }
        }
      }

      for (var product in products.docs) {
        final data = product.data() as Map<String, dynamic>;
        final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
        if (quantity < 10) lowStockCount++;
      }

      return OwnerStats(
        totalRevenue: totalRevenue,
        todayRevenue: todayRevenue,
        todayOrders: todayOrders,
        lowStockCount: lowStockCount,
        activeShopsCount: shops.docs.length,
      );
    },
  );
});

class OwnerStats {
  final double totalRevenue;
  final double todayRevenue;
  final int todayOrders;
  final int lowStockCount;
  final int activeShopsCount;

  const OwnerStats({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.todayOrders,
    required this.lowStockCount,
    required this.activeShopsCount,
  });
}

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final statsAsync = ref.watch(ownerStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownerStatsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade800, Colors.purple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
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
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.business_center_rounded,
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
                                      'Business Summary',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, letterSpacing: 1),
                                    ),
                                    Text(
                                      user?.name ?? 'Owner',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
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
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ],
            ),

            // Dashboard Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary Stats - Revenue
                    _buildOverviewStats(context, statsAsync),
                    const SizedBox(height: 32),

                    // Section 1: Business Insights
                    const SectionHeader(
                      title: 'Business Reports',
                      actionLabel: 'View Full Analytics',
                    ),
                    const SizedBox(height: 12),
                    _buildInsightsGrid(context),
                    const SizedBox(height: 32),

                    // Section 2: Management & Operations
                    const SectionHeader(title: 'Administrative Controls'),
                    const SizedBox(height: 12),
                    _buildOperationsGrid(context),
                    const SizedBox(height: 32),

                    // Section 3: User & Shop Entry
                    const SectionHeader(title: 'Quick Registration'),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats(BuildContext context, AsyncValue<OwnerStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Column(
        children: [
          // Low stock warning - Very important for owner
          if (stats.lowStockCount > 0)
            GestureDetector(
              onTap: () => GoRouter.of(context).push('/owner/products'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade800, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${stats.lowStockCount} Products are Low on Stock',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          
          // Main Stats Row
          Row(
            children: [
              Expanded(
                child: _MainStatCard(
                  label: 'Today',
                  value: '₹${_formatAmount(stats.todayRevenue)}',
                  subtitle: '${stats.todayOrders} orders',
                  color: Colors.blue.shade700,
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MainStatCard(
                  label: 'Total Sale',
                  value: '₹${_formatAmount(stats.totalRevenue)}',
                  subtitle: 'Gross revenue',
                  color: Colors.green.shade700,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => CompactErrorCard(message: error.toString()),
    );
  }

  Widget _buildInsightsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _SmallActionCard(
          icon: Icons.analytics_outlined,
          title: 'Sales Report',
          color: Colors.teal,
          onTap: () => GoRouter.of(context).push('/owner/analytics'),
        ),
        _SmallActionCard(
          icon: Icons.payments_outlined,
          title: 'Expenses',
          color: Colors.indigo,
          onTap: () => GoRouter.of(context).push('/owner/expenses'),
        ),
      ],
    );
  }

  Widget _buildOperationsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _OperationCard(
          icon: Icons.store_rounded,
          title: 'Manage Shops',
          subtitle: 'Performance',
          color: Colors.blueAccent,
          onTap: () => GoRouter.of(context).push('/owner/shops'),
        ),
        _OperationCard(
          icon: Icons.group_rounded,
          title: 'Employees',
          subtitle: 'Tracking',
          color: Colors.orange,
          onTap: () => GoRouter.of(context).push('/owner/users'),
        ),
        _OperationCard(
          icon: Icons.inventory_2_outlined,
          title: 'Products',
          subtitle: 'Inventory',
          color: Colors.green,
          onTap: () => GoRouter.of(context).push('/owner/products'),
        ),
        _OperationCard(
          icon: Icons.currency_rupee_rounded,
          title: 'Salary',
          subtitle: 'Payroll',
          color: Colors.purple,
          onTap: () => GoRouter.of(context).push('/owner/salary'),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => GoRouter.of(context).push('/admin/add-person'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add User'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.teal.shade700,
              side: BorderSide(color: Colors.teal.shade200),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => GoRouter.of(context).push('/admin/add-shop'),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Add Shop'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.indigo.shade700,
              side: BorderSide(color: Colors.indigo.shade200),
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _MainStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MainStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OperationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
