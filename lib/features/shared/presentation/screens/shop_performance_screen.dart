import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ShopPerformanceScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ShopPerformanceScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopPerformanceScreen> createState() => _ShopPerformanceScreenState();
}

class _ShopPerformanceScreenState extends ConsumerState<ShopPerformanceScreen> {
  String _selectedPeriod = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Shop Performance'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('shops').doc(widget.shopId).get(),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (shopSnapshot.hasError || !shopSnapshot.hasData || !shopSnapshot.data!.exists) {
            return const Center(child: Text('Shop not found'));
          }

          final shopData = shopSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final shopName = shopData['name'] ?? 'Unknown Shop';
          final address = shopData['address'] ?? '';
          final locationName = shopData['locationName'] ?? '';
          final ownerName = shopData['ownerName'] ?? '';
          final phone = shopData['phone'] ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('shopId', isEqualTo: widget.shopId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, ordersSnapshot) {
              if (ordersSnapshot.hasError) {
                return Center(child: Text('Error loading orders: ${ordersSnapshot.error}'));
              }
              if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allOrders = ordersSnapshot.data?.docs ?? [];
              final orders = _filterOrdersByPeriod(allOrders);

              double totalPaid = 0;
              double totalPending = 0;
              int completedCount = 0;
              int repeatingDaysCount = 0;
              final orderDates = <String>{};

              for (var order in orders) {
                final data = order.data() as Map<String, dynamic>;
                final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
                final paymentStatus = data['paymentStatus'] ?? 'pending';
                final status = data['status'] ?? 'pending';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                if (paymentStatus == 'paid') {
                  totalPaid += total;
                } else {
                  totalPending += total;
                }

                if (status == 'delivered') {
                  completedCount++;
                }

                if (createdAt != null) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(createdAt);
                  orderDates.add(dateStr);
                }
              }

              repeatingDaysCount = orderDates.length;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShopInfoCard(shopName, ownerName, phone, address, locationName),
                          const SizedBox(height: 24),
                          const Text(
                            'Analytics',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildAnalyticsGrid(
                            orders.length,
                            completedCount,
                            totalPaid,
                            totalPending,
                            repeatingDaysCount,
                            orders.isEmpty ? 0 : orders.length / (repeatingDaysCount > 0 ? repeatingDaysCount : 1),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order History',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${orders.length} orders',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  _buildOrdersList(orders),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShopInfoCard(String name, String owner, String phone, String address, String location) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (owner.isNotEmpty)
                      Text(
                        'Owner: $owner',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (phone.isNotEmpty) _buildInfoRow(Icons.phone, phone),
          if (location.isNotEmpty || address.isNotEmpty)
            _buildInfoRow(Icons.location_on, [location, address].where((e) => e.isNotEmpty).join(', ')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(
    int totalOrders,
    int deliveredOrders,
    double totalPaid,
    double totalPending,
    int activeDays,
    double avgOrdersPerActiveDay,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Orders', totalOrders.toString(), Icons.shopping_bag, Colors.blue),
        _buildStatCard('Delivered', deliveredOrders.toString(), Icons.check_circle, Colors.green),
        _buildStatCard('Total Paid', '₹${totalPaid.toStringAsFixed(0)}', Icons.payments, Colors.teal),
        _buildStatCard('Pending Payment', '₹${totalPending.toStringAsFixed(0)}', Icons.pending_actions, Colors.orange),
        _buildStatCard('Active Days', activeDays.toString(), Icons.calendar_today, Colors.purple),
        _buildStatCard('Avg / Active Day', avgOrdersPerActiveDay.toStringAsFixed(1), Icons.repeat, Colors.indigo),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: color.shade800, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<QueryDocumentSnapshot> orders) {
    if (orders.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No orders placed in this period', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId;

            final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
            final status = order['status'] ?? 'pending';
            final paymentStatus = order['paymentStatus'] ?? 'pending';
            final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
            final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt) : 'Unknown Date';

            final isPaid = paymentStatus == 'paid';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    Text(
                      '#$shortId',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(dateStr, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(isPaid ? Icons.check_circle : Icons.pending, size: 14, color: isPaid ? Colors.green : Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          isPaid ? 'Paid' : 'Pending Payment',
                          style: TextStyle(
                            color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: orders.length,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'ready':
        return Colors.teal;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  List<QueryDocumentSnapshot> _filterOrdersByPeriod(List<QueryDocumentSnapshot> orders) {
    if (_selectedPeriod == 'all') return orders;

    final now = DateTime.now();
    final days = _selectedPeriod == '7days'
        ? 7
        : _selectedPeriod == '30days'
            ? 30
            : 90;
    final cutoff = now.subtract(Duration(days: days));

    return orders.where((order) {
      final createdAt = ((order.data() as Map)['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null && createdAt.isAfter(cutoff);
    }).toList();
  }
}
