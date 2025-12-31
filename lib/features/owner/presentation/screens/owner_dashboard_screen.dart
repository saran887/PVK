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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
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
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business_center_rounded,
                              color: Colors.black87,
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
                                  user?.name ?? 'Owner',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 21,
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
                    const SnackBar(content: Text('Notifications - Coming Soon!')),
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

          // Dashboard Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Overview Section
                  const Text(
                    'Business Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOverviewStats(),
                  const SizedBox(height: 24),

                  // Management Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple[200]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business, size: 14, color: Colors.purple[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Owner',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildManagementGrid(context),
                  const SizedBox(height: 24),

                  // Reports & Analytics Section
                  const Text(
                    'Reports & Analytics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportsGrid(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
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
          childAspectRatio: 0.80,
          children: [
            _EnhancedStatCard(
              icon: Icons.currency_rupee_rounded,
              title: 'Total Revenue',
              value: '₹${(totalRevenue / 1000).toStringAsFixed(1)}K',
              subtitle: 'All time',
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _EnhancedStatCard(
              icon: Icons.today_rounded,
              title: 'Today\'s Revenue',
              value: '₹${todayRevenue.toStringAsFixed(0)}',
              subtitle: '$todayOrders orders',
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _EnhancedStatCard(
              icon: Icons.pending_actions_rounded,
              title: 'Pending Payments',
              value: '₹${(pendingPayments / 1000).toStringAsFixed(1)}K',
              subtitle: 'Outstanding',
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _EnhancedStatCard(
              icon: Icons.warning_amber_rounded,
              title: 'Low Stock Alert',
              value: lowStockCount.toString(),
              subtitle: lowStockCount > 0 ? 'Items < 10' : 'All stocked',
              gradient: LinearGradient(
                colors: lowStockCount > 0 
                    ? [Colors.red[400]!, Colors.red[600]!]
                    : [Colors.grey[400]!, Colors.grey[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
      childAspectRatio: 1.0,
      children: [
        _ColorfulActionCard(
          icon: Icons.people_rounded,
          title: 'User Analytics',
          subtitle: 'View team performance',
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => GoRouter.of(context).push('/owner/users'),
        ),
        _ColorfulActionCard(
          icon: Icons.store_mall_directory_rounded,
          title: 'Shop Performance',
          subtitle: 'Track shop metrics',
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => GoRouter.of(context).push('/owner/shops'),
        ),
        _ColorfulActionCard(
          icon: Icons.inventory_2_rounded,
          title: 'Product Insights',
          subtitle: 'Inventory analysis',
          gradient: LinearGradient(
            colors: [Colors.orange[400]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => GoRouter.of(context).push('/owner/products'),
        ),
        _ColorfulActionCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Salary Management',
          subtitle: 'Payroll overview',
          gradient: LinearGradient(
            colors: [Colors.purple[400]!, Colors.purple[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
      childAspectRatio: 1.0,
      children: [
        _ColorfulActionCard(
          icon: Icons.analytics_rounded,
          title: 'Business Analytics',
          subtitle: 'Sales & revenue insights',
          gradient: LinearGradient(
            colors: [Colors.teal[400]!, Colors.teal[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => GoRouter.of(context).push('/owner/analytics'),
        ),
        _ColorfulActionCard(
          icon: Icons.receipt_long_rounded,
          title: 'Expenses',
          subtitle: 'Track spending',
          gradient: LinearGradient(
            colors: [Colors.indigo[400]!, Colors.indigo[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => GoRouter.of(context).push('/owner/expenses'),
        ),
        _ColorfulActionCard(
          icon: Icons.person_add_rounded,
          title: 'Add User',
          subtitle: 'Create new account',
          gradient: LinearGradient(
            colors: [Colors.cyan[400]!, Colors.cyan[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => GoRouter.of(context).push('/admin/add-person'),
        ),
        _ColorfulActionCard(
          icon: Icons.add_business_rounded,
          title: 'Add Shop',
          subtitle: 'Register new shop',
          gradient: LinearGradient(
            colors: [Colors.lightGreen[400]!, Colors.lightGreen[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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

// Enhanced Statistics Card with gradient background
class _EnhancedStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Gradient gradient;

  const _EnhancedStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

// Colorful Action Card with gradient background
class _ColorfulActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ColorfulActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
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
