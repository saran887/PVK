import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            PopupMenuButton<String>(
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
                      SizedBox(width: 8),
                      Text('Add Person'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_shop',
                  child: Row(
                    children: [
                      Icon(Icons.add_business, size: 20),
                      SizedBox(width: 8),
                      Text('Add Shop'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_product',
                  child: Row(
                    children: [
                      Icon(Icons.add_shopping_cart, size: 20),
                      SizedBox(width: 8),
                      Text('Add Product'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_location',
                  child: Row(
                    children: [
                      Icon(Icons.add_location, size: 20),
                      SizedBox(width: 8),
                      Text('Add Location'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'manage_locations',
                  child: Row(
                    children: [
                      Icon(Icons.location_city, size: 25),
                      SizedBox(width: 8),
                      Text('Manage Locations'),
                    ],
                  ),
                ),
              ],
            ),
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
                          backgroundColor: Color.alphaBlend(Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()), Colors.white),
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
                const SizedBox(height: 16),
                Text(
                  'Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    _QuickActionCard(
                      icon: Icons.analytics,
                      title: 'Reports',
                      color: Colors.deepOrange,
                      onTap: () => context.push('/admin/reports'),
                    ),
                    _QuickActionCard(
                      icon: Icons.people,
                      title: 'Manage Users',
                      color: Colors.green,
                      onTap: () => context.push('/admin/manage-users'),
                    ),
                    _QuickActionCard(
                      icon: Icons.store,
                      title: 'Manage Shops',
                      color: Colors.purple,
                      onTap: () => context.push('/admin/manage-shops'),
                    ),
                    _QuickActionCard(
                      icon: Icons.inventory,
                      title: 'Manage Products',
                      color: Colors.indigo,
                      onTap: () => context.push('/admin/manage-products'),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
