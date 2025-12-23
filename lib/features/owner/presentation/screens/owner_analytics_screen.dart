import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerAnalyticsScreen extends ConsumerStatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  ConsumerState<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends ConsumerState<OwnerAnalyticsScreen> {
  String _selectedPeriod = '7days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Analytics'),
        actions: [
          DropdownButton<String>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: '7days', child: Text('Last 7 Days')),
              DropdownMenuItem(value: '30days', child: Text('Last 30 Days')),
              DropdownMenuItem(value: '90days', child: Text('Last 90 Days')),
              DropdownMenuItem(value: 'all', child: Text('All Time')),
            ],
            onChanged: (value) => setState(() => _selectedPeriod = value!),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialOverview(),
            const SizedBox(height: 24),
            _buildOrderMetrics(),
            const SizedBox(height: 24),
            _buildTopPerformers(),
            const SizedBox(height: 24),
            _buildSystemHealth(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
        }

        final orders = _filterOrdersByPeriod(snapshot.data!.docs);
        
        double totalRevenue = 0;
        double totalPending = 0;
        double totalPaid = 0;
        int completedOrders = 0;

        for (var order in orders) {
          final data = order.data() as Map;
          final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final paymentStatus = data['paymentStatus'] ?? 'pending';
          final status = data['status'] ?? 'pending';
          
          totalRevenue += total;
          
          if (paymentStatus == 'paid') {
            totalPaid += total;
          } else {
            totalPending += total;
          }
          
          if (status == 'delivered') {
            completedOrders++;
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _FinancialCard(
                        icon: Icons.account_balance_wallet,
                        title: 'Total Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(2)}',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FinancialCard(
                        icon: Icons.check_circle,
                        title: 'Paid',
                        value: '₹${totalPaid.toStringAsFixed(2)}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FinancialCard(
                        icon: Icons.pending_actions,
                        title: 'Outstanding',
                        value: '₹${totalPending.toStringAsFixed(2)}',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FinancialCard(
                        icon: Icons.local_shipping,
                        title: 'Completed',
                        value: '$completedOrders',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderMetrics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
        }

        final orders = _filterOrdersByPeriod(snapshot.data!.docs);
        
        final statusCount = <String, int>{};
        for (var order in orders) {
          final status = (order.data() as Map)['status'] ?? 'pending';
          statusCount[status] = (statusCount[status] ?? 0) + 1;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Metrics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
                  children: [
                    _MetricBox(label: 'Total', value: '${orders.length}', color: Colors.blue),
                    _MetricBox(label: 'Pending', value: '${statusCount['pending'] ?? 0}', color: Colors.orange),
                    _MetricBox(label: 'Processing', value: '${statusCount['processing'] ?? 0}', color: Colors.amber),
                    _MetricBox(label: 'Ready', value: '${statusCount['ready'] ?? 0}', color: Colors.teal),
                    _MetricBox(label: 'Delivering', value: '${statusCount['out_for_delivery'] ?? 0}', color: Colors.indigo),
                    _MetricBox(label: 'Delivered', value: '${statusCount['delivered'] ?? 0}', color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopPerformers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, ordersSnapshot) {
        if (!ordersSnapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('shops').snapshots(),
          builder: (context, shopsSnapshot) {
            if (!shopsSnapshot.hasData) {
              return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
            }

            final orders = _filterOrdersByPeriod(ordersSnapshot.data!.docs);
            final shops = shopsSnapshot.data!.docs;
            
            final shopRevenue = <String, double>{};
            final shopOrders = <String, int>{};
            
            for (var order in orders) {
              final data = order.data() as Map;
              final shopId = data['shopId'];
              final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
              
              if (shopId != null) {
                shopRevenue[shopId] = (shopRevenue[shopId] ?? 0) + total;
                shopOrders[shopId] = (shopOrders[shopId] ?? 0) + 1;
              }
            }

            final topShops = shopRevenue.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final top5Shops = topShops.take(5).toList();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Performing Shops', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (top5Shops.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No data available')),
                      )
                    else
                      ...top5Shops.asMap().entries.map((entry) {
                        final index = entry.key;
                        final shopEntry = entry.value;
                        QueryDocumentSnapshot? shop;
                        try {
                          shop = shops.firstWhere((s) => s.id == shopEntry.key);
                        } catch (e) {
                          shop = shops.isNotEmpty ? shops.first : null;
                        }
                        if (shop == null) return const SizedBox.shrink();
                        final shopData = shop.data() as Map;
                        final shopName = shopData['name'] ?? 'Unknown';
                        final revenue = shopEntry.value;
                        final orderCount = shopOrders[shopEntry.key] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: index == 0 ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: index == 0 ? Colors.amber : Colors.grey.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.amber : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('$orderCount orders', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSystemHealth() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _combineStreams([
        FirebaseFirestore.instance.collection('users').snapshots(),
        FirebaseFirestore.instance.collection('shops').snapshots(),
        FirebaseFirestore.instance.collection('products').snapshots(),
        FirebaseFirestore.instance.collection('orders').snapshots(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
        }

        final users = snapshot.data![0].docs;
        final shops = snapshot.data![1].docs;
        final products = snapshot.data![2].docs;
        final orders = snapshot.data![3].docs;

        final activeUsers = users.where((u) => (u.data() as Map)['isActive'] ?? true).length;
        final activeShops = shops.where((s) => (s.data() as Map)['isActive'] ?? true).length;
        final activeProducts = products.where((p) => (p.data() as Map)['isActive'] ?? true).length;
        final pendingOrders = orders.where((o) => (o.data() as Map)['status'] == 'pending').length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Health', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _HealthItem(icon: Icons.people, label: 'Active Users', value: '$activeUsers/${users.length}', percentage: users.isNotEmpty ? activeUsers / users.length : 0),
                _HealthItem(icon: Icons.store, label: 'Active Shops', value: '$activeShops/${shops.length}', percentage: shops.isNotEmpty ? activeShops / shops.length : 0),
                _HealthItem(icon: Icons.inventory, label: 'Active Products', value: '$activeProducts/${products.length}', percentage: products.isNotEmpty ? activeProducts / products.length : 0),
                _HealthItem(icon: Icons.pending, label: 'Pending Orders', value: '$pendingOrders/${orders.length}', percentage: orders.isNotEmpty ? pendingOrders / orders.length : 0, isWarning: true),
              ],
            ),
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterOrdersByPeriod(List<QueryDocumentSnapshot> orders) {
    if (_selectedPeriod == 'all') return orders;

    final now = DateTime.now();
    final days = _selectedPeriod == '7days' ? 7 : _selectedPeriod == '30days' ? 30 : 90;
    final cutoff = now.subtract(Duration(days: days));

    return orders.where((order) {
      final createdAt = ((order.data() as Map)['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null && createdAt.isAfter(cutoff);
    }).toList();
  }

  Stream<List<QuerySnapshot>> _combineStreams(List<Stream<QuerySnapshot>> streams) {
    return Stream.periodic(const Duration(milliseconds: 500))
        .asyncMap((_) => Future.wait(streams.map((s) => s.first)));
  }
}

class _FinancialCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _FinancialCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double percentage;
  final bool isWarning;

  const _HealthItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.percentage,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? (percentage > 0.3 ? Colors.red : Colors.orange)
        : (percentage > 0.7 ? Colors.green : percentage > 0.4 ? Colors.orange : Colors.red);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
