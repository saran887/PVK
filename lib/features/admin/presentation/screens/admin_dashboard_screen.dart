import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit admin?'),
            content: const Text('Do you want to leave the admin dashboard?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.dashboard_rounded, color: Colors.black87),
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
                                    user?.name ?? 'Administrator',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications - Coming Soon!')),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                switch (value) {
                                  case 'add_person':
                                    context.push('/admin/add-person');
                                    break;
                                  case 'add_shop':
                                    context.push('/admin/add-shop');
                                    break;
                                  case 'add_product':
                                    context.push('/admin/add-product');
                                    break;
                                  case 'add_location':
                                    context.push('/admin/add-location');
                                    break;
                                  case 'manage_locations':
                                    context.push('/admin/manage-locations');
                                    break;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'add_person',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_add, size: 20),
                                      SizedBox(width: 12),
                                      Text('Add Person'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'add_shop',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_business, size: 20),
                                      SizedBox(width: 12),
                                      Text('Add Shop'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'add_product',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_shopping_cart, size: 20),
                                      SizedBox(width: 12),
                                      Text('Add Product'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'add_location',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_location, size: 20),
                                      SizedBox(width: 12),
                                      Text('Add Location'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'manage_locations',
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_city, size: 20),
                                      SizedBox(width: 12),
                                      Text('Manage Locations'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.black87),
                              onPressed: () async {
                                await ref.read(authRepositoryProvider).signOut();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DashboardStats(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.auto_awesome, size: 14, color: Colors.black87),
                                SizedBox(width: 4),
                                Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                        children: [
                          _EnhancedActionCard(
                            icon: Icons.analytics_rounded,
                            title: 'Reports',
                            subtitle: 'View analytics & insights',
                            iconColor: Colors.deepOrange,
                            onTap: () => context.push('/admin/reports'),
                          ),
                          _EnhancedActionCard(
                            icon: Icons.people_rounded,
                            title: 'Users',
                            subtitle: 'Manage team members',
                            iconColor: Colors.green,
                            onTap: () => context.push('/admin/manage-users'),
                          ),
                          _EnhancedActionCard(
                            icon: Icons.store_rounded,
                            title: 'Shops',
                            subtitle: 'Manage your shops',
                            iconColor: Colors.purple,
                            onTap: () => context.push('/admin/manage-shops'),
                          ),
                          _EnhancedActionCard(
                            icon: Icons.inventory_2_rounded,
                            title: 'Products',
                            subtitle: 'Manage inventory',
                            iconColor: Colors.indigo,
                            onTap: () => context.push('/admin/manage-products'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/add-person'),
          backgroundColor: Colors.black,
          elevation: 2,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text(
            'Add Person',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('shops').snapshots(),
          builder: (context, shopsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, productsSnapshot) {
                final usersCount = usersSnapshot.data?.docs.length ?? 0;
                final shopsCount = shopsSnapshot.data?.docs.length ?? 0;
                final productsCount = productsSnapshot.data?.docs.length ?? 0;
                final isLoading = usersSnapshot.connectionState == ConnectionState.waiting ||
                    shopsSnapshot.connectionState == ConnectionState.waiting ||
                    productsSnapshot.connectionState == ConnectionState.waiting;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _EnhancedStatCard(
                            icon: Icons.people_rounded,
                            label: 'Total Users',
                            value: usersCount.toString(),
                            iconColor: Colors.blue,
                            isLoading: isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EnhancedStatCard(
                            icon: Icons.store_rounded,
                            label: 'Total Shops',
                            value: shopsCount.toString(),
                            iconColor: Colors.purple,
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EnhancedStatCard(
                            icon: Icons.inventory_2_rounded,
                            label: 'Products',
                            value: productsCount.toString(),
                            iconColor: Colors.orange,
                            isLoading: isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EnhancedStatCard(
                            icon: Icons.trending_up_rounded,
                            label: 'Active Now',
                            value: '${(usersCount * 0.7).round()}',
                            iconColor: Colors.green,
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EnhancedStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isLoading;

  const _EnhancedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        ],
      ),
    );
  }
}

class _EnhancedActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _EnhancedActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
