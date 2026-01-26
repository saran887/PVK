import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// Provider for combined dashboard stats using rxdart for efficient stream combining
final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  final shopsStream = FirebaseFirestore.instance.collection('shops').snapshots();
  final productsStream = FirebaseFirestore.instance.collection('products').snapshots();
  final ordersStream = FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'pending')
      .snapshots();

  return Rx.combineLatest4(
    usersStream,
    shopsStream,
    productsStream,
    ordersStream,
    (QuerySnapshot users, QuerySnapshot shops, QuerySnapshot products, QuerySnapshot orders) {
      return DashboardStats(
        usersCount: users.docs.length,
        shopsCount: shops.docs.length,
        productsCount: products.docs.length,
        pendingOrdersCount: orders.docs.length,
      );
    },
  );
});

class DashboardStats {
  final int usersCount;
  final int shopsCount;
  final int productsCount;
  final int pendingOrdersCount;

  const DashboardStats({
    required this.usersCount,
    required this.shopsCount,
    required this.productsCount,
    required this.pendingOrdersCount,
  });
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Admin?'),
        content: const Text('Do you want to leave the admin dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final statsAsync = ref.watch(dashboardStatsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
                // --- HEADER ---
                SliverToBoxAdapter(
                  child: _buildHeader(context, ref, user?.name),
                ),

                // --- STATS GRID ---
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildStatsGrid(statsAsync),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // --- MANAGEMENT HUB ---
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildManagementSection(context),
                  ),
                ),

                // --- QUICK REGISTER ---
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: _buildQuickRegisterSection(context),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String? userName) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Console',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName ?? 'Administrator',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Logout',
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AsyncValue<DashboardStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          StatCard(
            icon: Icons.people_rounded,
            label: 'Total Users',
            value: stats.usersCount.toString(),
            iconColor: Colors.blue,
          ),
          StatCard(
            icon: Icons.store_rounded,
            label: 'Total Shops',
            value: stats.shopsCount.toString(),
            iconColor: Colors.purple,
          ),
          StatCard(
            icon: Icons.inventory_2_rounded,
            label: 'Products',
            value: stats.productsCount.toString(),
            iconColor: Colors.orange,
          ),
          StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pending Orders',
            value: stats.pendingOrdersCount.toString(),
            iconColor: Colors.amber.shade700,
          ),
        ],
      ),
      loading: () => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: List.generate(4, (_) => const StatCard(
          icon: Icons.hourglass_empty,
          label: 'Loading...',
          value: '-',
          iconColor: Colors.grey,
          isLoading: true,
        )),
      ),
      error: (error, _) => CompactErrorCard(message: error.toString()),
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Management Hub'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
          children: [
            ActionCard(
              icon: Icons.analytics_rounded,
              title: 'Reports',
              subtitle: 'Business Analytics',
              iconColor: Colors.deepOrange,
              onTap: () => context.push('/admin/reports'),
            ),
            ActionCard(
              icon: Icons.people_rounded,
              title: 'Users',
              subtitle: 'Staff & Drivers',
              iconColor: Colors.green,
              onTap: () => context.push('/admin/manage-users'),
            ),
            ActionCard(
              icon: Icons.store_rounded,
              title: 'Shops',
              subtitle: 'Retail Partners',
              iconColor: Colors.purple,
              onTap: () => context.push('/admin/manage-shops'),
            ),
            ActionCard(
              icon: Icons.inventory_2_rounded,
              title: 'Products',
              subtitle: 'Stock Inventory',
              iconColor: Colors.indigo,
              onTap: () => context.push('/admin/manage-products'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickRegisterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Register'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              QuickActionChip(
                icon: Icons.person_add_rounded,
                label: 'Person',
                onTap: () => context.push('/admin/add-person'),
              ),
              const SizedBox(width: 10),
              QuickActionChip(
                icon: Icons.add_business_rounded,
                label: 'Shop',
                onTap: () => context.push('/admin/add-shop'),
              ),
              const SizedBox(width: 10),
              QuickActionChip(
                icon: Icons.add_shopping_cart_rounded,
                label: 'Product',
                onTap: () => context.push('/admin/add-product'),
              ),
              const SizedBox(width: 10),
              QuickActionChip(
                icon: Icons.add_location_alt_rounded,
                label: 'Location',
                onTap: () => context.push('/admin/add-location'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
