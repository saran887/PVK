import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
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
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
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
        body: RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'A',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user?.name ?? "Administrator"}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Admin',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _QuickActionCard(
                      icon: Icons.person_add,
                      title: 'Add Person',
                      color: Colors.blue,
                      onTap: () => context.push('/admin/add-person'),
                    ),
                    _QuickActionCard(
                      icon: Icons.people,
                      title: 'Manage Users',
                      color: Colors.green,
                      onTap: () => context.push('/admin/manage-users'),
                    ),
                    _QuickActionCard(
                      icon: Icons.add_business,
                      title: 'Add Shop',
                      color: Colors.orange,
                      onTap: () => context.push('/admin/add-shop'),
                    ),
                    _QuickActionCard(
                      icon: Icons.store,
                      title: 'Manage Shops',
                      color: Colors.purple,
                      onTap: () => context.push('/admin/manage-shops'),
                    ),
                    _QuickActionCard(
                      icon: Icons.add_shopping_cart,
                      title: 'Add Product',
                      color: Colors.teal,
                      onTap: () => context.push('/admin/add-product'),
                    ),
                    _QuickActionCard(
                      icon: Icons.inventory,
                      title: 'Manage Products',
                      color: Colors.indigo,
                      onTap: () => context.push('/admin/manage-products'),
                    ),
                    _QuickActionCard(
                      icon: Icons.add_location,
                      title: 'Add Location',
                      color: Colors.red,
                      onTap: () => context.push('/admin/add-location'),
                    ),
                    _QuickActionCard(
                      icon: Icons.location_city,
                      title: 'Manage Locations',
                      color: Colors.pink,
                      onTap: () => context.push('/admin/manage-locations'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _QuickActionCard(
                      icon: Icons.analytics,
                      title: 'Reports',
                      color: Colors.deepOrange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reports screen - Coming soon!')),
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.settings,
                      title: 'Settings',
                      color: Colors.blueGrey,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings screen - Coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/add-person'),
          icon: const Icon(Icons.person_add),
          label: const Text('Add Person'),
        ),
      ),
    );
  }
}

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
