import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';

class BillingHomeScreen extends ConsumerWidget {
  const BillingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Dashboard'),
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
      body: Padding(
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
                      backgroundColor: Color.alphaBlend(Colors.orange.withAlpha((0.1 * 255).toInt()), Colors.white),
                      child: const Icon(Icons.receipt, size: 30, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome,', style: Theme.of(context).textTheme.bodySmall),
                        Text(user?.name ?? 'Billing', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _QuickActionCard(
                    icon: Icons.pending_actions,
                    title: 'Pending Orders',
                    color: Colors.orange,
                    onTap: () {
                      context.push('/billing/pending-orders');
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.edit,
                    title: 'Adjust Rates',
                    color: Colors.blue,
                    onTap: () {
                      context.push('/billing/adjust-rates');
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.check_circle,
                    title: 'Processed Orders',
                    color: Colors.green,
                    onTap: () {
                      context.push('/billing/processed-orders');
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.receipt_long,
                    title: 'Generate Bill',
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to processed orders where bills can be generated
                      context.push('/billing/processed-orders');
                    },
                  ),
                ],
              ),
            ),
          ],
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
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
