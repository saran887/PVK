import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/animations.dart';

/// Provider for sales statistics
final salesStatsProvider = StreamProvider.family<SalesStats, String>((ref, locationId) {
  if (locationId.isEmpty) {
    return Stream.value(const SalesStats(todayOrders: 0, pendingOrders: 0, todayRevenue: 0));
  }

  return FirebaseFirestore.instance
      .collection('orders')
      .where('shopLocationId', isEqualTo: locationId)
      .snapshots()
      .map((snapshot) {
        int todayOrders = 0;
        int pendingOrders = 0;
        double todayRevenue = 0;

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final createdAt = data['createdAt'] as Timestamp?;
          final status = data['status'] as String?;
          final amount = (data['totalAmount'] ?? 0) as num;

          if (createdAt != null) {
            final orderDate = createdAt.toDate();
            if (orderDate.isAfter(today)) {
              todayOrders++;
              todayRevenue += amount.toDouble();
            }
          }

          if (status == 'pending') {
            pendingOrders++;
          }
        }

        return SalesStats(
          todayOrders: todayOrders,
          pendingOrders: pendingOrders,
          todayRevenue: todayRevenue,
        );
      });
});

class SalesStats {
  final int todayOrders;
  final int pendingOrders;
  final double todayRevenue;

  const SalesStats({
    required this.todayOrders,
    required this.pendingOrders,
    required this.todayRevenue,
  });
}

class SalesHomeScreen extends ConsumerStatefulWidget {
  const SalesHomeScreen({super.key});

  @override
  ConsumerState<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends ConsumerState<SalesHomeScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    // Trigger entrance animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showContent = true);
    });
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final userLocationId = user?.locationId ?? '';
    final statsAsync = ref.watch(salesStatsProvider(userLocationId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Notifications - Coming Soon!'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesStatsProvider(userLocationId));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card with fade in
              SlideFadeIn(
                show: _showContent,
                delay: const Duration(milliseconds: 100),
                child: _buildWelcomeCard(context, user),
              ),
              const SizedBox(height: 20),
              
              // Statistics Row with staggered animation
              SlideFadeIn(
                show: _showContent,
                delay: const Duration(milliseconds: 200),
                child: _buildStatsRow(statsAsync),
              ),
              const SizedBox(height: 24),
              
              // Quick Actions header
              SlideFadeIn(
                show: _showContent,
                delay: const Duration(milliseconds: 300),
                child: const SectionHeader(title: 'Quick Actions'),
              ),
              const SizedBox(height: 14),
              // Quick Actions grid with animation
              SlideFadeIn(
                show: _showContent,
                delay: const Duration(milliseconds: 350),
                child: _buildQuickActions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.08),
            Theme.of(context).primaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'Sales Person',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user?.locationName != null && user!.locationName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        user.locationName!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.green, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AsyncValue<SalesStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _CompactStatCard(
              icon: Icons.shopping_bag_rounded,
              label: 'Today',
              value: stats.todayOrders.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompactStatCard(
              icon: Icons.pending_actions_rounded,
              label: 'Pending',
              value: stats.pendingOrders.toString(),
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompactStatCard(
              icon: Icons.currency_rupee_rounded,
              label: 'Revenue',
              value: '₹${_formatAmount(stats.todayRevenue)}',
              color: Colors.green,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: List.generate(3, (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: const _CompactStatCard(
              icon: Icons.hourglass_empty,
              label: 'Loading',
              value: '-',
              color: Colors.grey,
              isLoading: true,
            ),
          ),
        )),
      ),
      error: (error, _) => CompactErrorCard(message: error.toString()),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        ActionCard(
          icon: Icons.add_shopping_cart_rounded,
          title: 'Create Order',
          subtitle: 'Add new order',
          iconColor: Colors.green,
          isCompact: true,
          onTap: () => context.push('/sales/create-order'),
        ),
        ActionCard(
          icon: Icons.receipt_long_rounded,
          title: 'My Orders',
          subtitle: 'View all orders',
          iconColor: Colors.orange,
          isCompact: true,
          onTap: () => context.push('/sales/my-orders'),
        ),
        ActionCard(
          icon: Icons.store_rounded,
          title: 'View Shops',
          subtitle: 'Browse shops',
          iconColor: Colors.blue,
          isCompact: true,
          onTap: () => context.push('/sales/shops'),
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLoading;

  const _CompactStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value,
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
