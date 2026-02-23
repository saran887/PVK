import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:pkv2/shared/widgets/animations.dart';

class OwnerAnalyticsScreen extends ConsumerStatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  ConsumerState<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends ConsumerState<OwnerAnalyticsScreen> {
  String _selectedPeriod = '7days';
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 100),
                    child: _buildFinancialOverview(),
                  ),
                  const SizedBox(height: 32),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 200),
                    child: _buildOrderMetrics(),
                  ),
                  const SizedBox(height: 32),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 300),
                    child: _buildTopPerformers(),
                  ),
                  const SizedBox(height: 32),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 400),
                    child: _buildSystemHealth(),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Dev Wipe'),
              content: const Text('Delete all expenses, salary values, and advances?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('WIPE DATA')),
              ],
            ),
          );
          if (confirm == true) {
            try {
              final expenses = await FirebaseFirestore.instance.collection('expenses').get();
              for (var doc in expenses.docs) {
                await doc.reference.delete();
              }
              final users = await FirebaseFirestore.instance.collection('users').get();
              for (var doc in users.docs) {
                await doc.reference.update({'salary': 0});
              }
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wipe Complete!')));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wipe Error: $e')));
            }
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade800, Colors.deepPurple.shade900],
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reports',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, letterSpacing: 1),
                            ),
                            const Text(
                              'Sales & Analytics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                            dropdownColor: Colors.deepPurple.shade900,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: '7days', child: Text('7 Days')),
                              DropdownMenuItem(value: '30days', child: Text('30 Days')),
                              DropdownMenuItem(value: '90days', child: Text('90 Days')),
                              DropdownMenuItem(value: 'all', child: Text('All Time')),
                            ],
                            onChanged: (value) => setState(() => _selectedPeriod = value!),
                          ),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Revenue', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${totalRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat('Paid', '₹${totalPaid.toStringAsFixed(0)}', Colors.greenAccent),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildMiniStat('Pending', '₹${totalPending.toStringAsFixed(0)}', Colors.orangeAccent),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildMiniStat('Completed', '$completedOrders', Colors.purpleAccent.shade100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildOrderMetrics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final orders = _filterOrdersByPeriod(snapshot.data!.docs);
        final statusCount = <String, int>{};
        for (var order in orders) {
          final status = (order.data() as Map)['status'] ?? 'pending';
          statusCount[status] = (statusCount[status] ?? 0) + 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _MetricBox(label: 'Total', value: '${orders.length}', icon: Icons.shopping_cart_rounded, color: Colors.blue.shade600),
                _MetricBox(label: 'Pending', value: '${statusCount['pending'] ?? 0}', icon: Icons.hourglass_top_rounded, color: Colors.orange.shade600),
                _MetricBox(label: 'Processing', value: '${statusCount['processing'] ?? 0}', icon: Icons.autorenew_rounded, color: Colors.amber.shade600),
                _MetricBox(label: 'Ready', value: '${statusCount['ready'] ?? 0}', icon: Icons.inventory_2_rounded, color: Colors.teal.shade600),
                _MetricBox(label: 'Delivering', value: '${statusCount['out_for_delivery'] ?? 0}', icon: Icons.local_shipping_rounded, color: Colors.indigo.shade600),
                _MetricBox(label: 'Delivered', value: '${statusCount['delivered'] ?? 0}', icon: Icons.check_circle_rounded, color: Colors.green.shade600),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopPerformers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, ordersSnapshot) {
        if (!ordersSnapshot.hasData) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('shops').snapshots(),
          builder: (context, shopsSnapshot) {
            if (!shopsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Top Performing Shops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text('Top 5', style: TextStyle(color: Colors.amber.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (top5Shops.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        Icon(Icons.store, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No shop data available for this period', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: top5Shops.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final shopEntry = top5Shops[index];
                        QueryDocumentSnapshot? shop;
                        try {
                          shop = shops.firstWhere((s) => s.id == shopEntry.key);
                        } catch (e) {}
                        if (shop == null) return const SizedBox.shrink();
                        
                        final shopData = shop.data() as Map;
                        final shopName = shopData['name'] ?? 'Unknown';
                        final revenue = shopEntry.value;
                        final orderCount = shopOrders[shopEntry.key] ?? 0;
                        final isFirst = index == 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isFirst ? Colors.amber.shade50 : Colors.grey.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(color: isFirst ? Colors.amber.shade300 : Colors.grey.shade200),
                            ),
                            child: Center(
                              child: isFirst
                                  ? Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 20)
                                  : Text('${index + 1}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          title: Text(shopName, style: TextStyle(fontWeight: isFirst ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_bag_rounded, size: 12, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text('$orderCount orders', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          trailing: Text(
                            '₹${revenue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFirst ? Colors.amber.shade700 : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
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
        if (!snapshot.hasData) return const SizedBox.shrink();

        final users = snapshot.data![0].docs;
        final shops = snapshot.data![1].docs;
        final products = snapshot.data![2].docs;
        final orders = snapshot.data![3].docs;

        final activeUsers = users.where((u) => (u.data() as Map)['isActive'] ?? true).length;
        final activeShops = shops.where((s) => (s.data() as Map)['isActive'] ?? true).length;
        final activeProducts = products.where((p) => (p.data() as Map)['isActive'] ?? true).length;
        final pendingOrders = orders.where((o) => (o.data() as Map)['status'] == 'pending').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _HealthItem(icon: Icons.groups_rounded, label: 'Active Users', value: '$activeUsers/${users.length}', percentage: users.isNotEmpty ? activeUsers / users.length : 0),
                  const Divider(height: 24),
                  _HealthItem(icon: Icons.store_rounded, label: 'Active Shops', value: '$activeShops/${shops.length}', percentage: shops.isNotEmpty ? activeShops / shops.length : 0),
                  const Divider(height: 24),
                  _HealthItem(icon: Icons.inventory_2_rounded, label: 'Active Products', value: '$activeProducts/${products.length}', percentage: products.isNotEmpty ? activeProducts / products.length : 0),
                  const Divider(height: 24),
                  _HealthItem(icon: Icons.pending_actions_rounded, label: 'Pending Orders', value: '$pendingOrders/${orders.length}', percentage: orders.isNotEmpty ? pendingOrders / orders.length : 0, isWarning: true),
                ],
              ),
            ),
          ],
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

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
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
        ? (percentage > 0.3 ? Colors.red.shade500 : Colors.orange.shade500)
        : (percentage > 0.7 ? Colors.green.shade500 : percentage > 0.4 ? Colors.orange.shade500 : Colors.red.shade500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
