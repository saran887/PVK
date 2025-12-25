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
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          await ref.read(authRepositoryProvider).signOut();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.dashboard_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome back,',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      user?.name ?? 'Administrator',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
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
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications - Coming Soon!')),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
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
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_person',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 20),
                          SizedBox(width: 12),
                          Text('Add Person'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_shop',
                      child: Row(
                        children: [
                          Icon(Icons.add_business, size: 20),
                          SizedBox(width: 12),
                          Text('Add Shop'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_product',
                      child: Row(
                        children: [
                          Icon(Icons.add_shopping_cart, size: 20),
                          SizedBox(width: 12),
                          Text('Add Product'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_location',
                      child: Row(
                        children: [
                          Icon(Icons.add_location, size: 20),
                          SizedBox(width: 12),
                          Text('Add Location'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
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
                  icon: const Icon(Icons.logout, color: Colors.white),
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
                    // Statistics Cards with enhanced design
                    StreamBuilder<QuerySnapshot>(
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
                                            gradient: LinearGradient(
                                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            isLoading: isLoading,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _EnhancedStatCard(
                                            icon: Icons.store_rounded,
                                            label: 'Total Shops',
                                            value: shopsCount.toString(),
                                            gradient: LinearGradient(
                                              colors: [Colors.purple[400]!, Colors.purple[600]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
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
                                            gradient: LinearGradient(
                                              colors: [Colors.orange[400]!, Colors.orange[600]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            isLoading: isLoading,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _EnhancedStatCard(
                                            icon: Icons.trending_up_rounded,
                                            label: 'Active Now',
                                            value: '${(usersCount * 0.7).round()}',
                                            gradient: LinearGradient(
                                              colors: [Colors.green[400]!, Colors.green[600]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
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
                    ),
                    const SizedBox(height: 24),

                    // Section Title
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
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue[200]!, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Enhanced Action Cards Grid
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
                          gradient: LinearGradient(
                            colors: [Colors.deepOrange[400]!, Colors.deepOrange[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () => context.push('/admin/reports'),
                        ),
                        _EnhancedActionCard(
                          icon: Icons.people_rounded,
                          title: 'Users',
                          subtitle: 'Manage team members',
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () => context.push('/admin/manage-users'),
                        ),
                        _EnhancedActionCard(
                          icon: Icons.store_rounded,
                          title: 'Shops',
                          subtitle: 'Manage your shops',
                          gradient: LinearGradient(
                            colors: [Colors.purple[400]!, Colors.purple[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () => context.push('/admin/manage-shops'),
                        ),
                        _EnhancedActionCard(
                          icon: Icons.inventory_2_rounded,
                          title: 'Products',
                          subtitle: 'Manage inventory',
                          gradient: LinearGradient(
                            colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/add-person'),
          backgroundColor: Colors.blue[600],
          elevation: 4,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Person', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// Enhanced Statistics Card with gradient background
class _EnhancedStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;
  final bool isLoading;

  const _EnhancedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.isLoading = false,
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}

// Enhanced Action Card with full gradient background
class _EnhancedActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _EnhancedActionCard({
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
                    fontSize: 18,
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
                    fontSize: 13,
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
