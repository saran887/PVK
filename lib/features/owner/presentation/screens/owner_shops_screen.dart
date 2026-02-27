import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class OwnerShopsScreen extends ConsumerStatefulWidget {
  const OwnerShopsScreen({super.key});

  @override
  ConsumerState<OwnerShopsScreen> createState() => _OwnerShopsScreenState();
}

class _OwnerShopsScreenState extends ConsumerState<OwnerShopsScreen> {
  String _searchQuery = '';
  String _selectedLocation = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Performance & Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () => context.push('/admin/add-shop'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPerformanceOverview(),
          _buildFilters(),
          Expanded(child: _buildShopList()),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').snapshots(),
      builder: (context, shopsSnapshot) {
        if (!shopsSnapshot.hasData) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, ordersSnapshot) {
            final shops = shopsSnapshot.data!.docs;
            final orders = ordersSnapshot.data?.docs ?? [];
            
            final activeShops = shops.where((s) => (s.data() as Map)['isActive'] ?? true).length;
            final totalOrders = orders.length;
            final shopOrderCount = <String, int>{};
            
            for (var order in orders) {
              final shopId = (order.data() as Map)['shopId'];
              if (shopId != null) {
                shopOrderCount[shopId] = (shopOrderCount[shopId] ?? 0) + 1;
              }
            }

            QueryDocumentSnapshot? topShop;
            if (shopOrderCount.isNotEmpty && shops.isNotEmpty) {
              final topShopId = shopOrderCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
              try {
                topShop = shops.firstWhere((s) => s.id == topShopId);
              } catch (e) {
                topShop = null;
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Business Metrics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.store,
                          title: 'Total Shops',
                          value: shops.length.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.store_mall_directory,
                          title: 'Active Shops',
                          value: activeShops.toString(),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.shopping_bag,
                          title: 'Total Orders',
                          value: totalOrders.toString(),
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.star,
                          title: 'Top Shop',
                          value: topShop != null ? ((topShop.data() as Map)['name'] ?? 'N/A').toString().split(' ')[0] : 'N/A',
                          color: Colors.purple,
                          subtitle: topShop != null ? '${shopOrderCount[topShop.id]} orders' : '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search shops...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('locations').snapshots(),
            builder: (context, snapshot) {
              final locations = snapshot.data?.docs ?? [];
              return DropdownButton<String>(
                value: _selectedLocation,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Locations')),
                  ...locations.map((loc) {
                    final name = (loc.data() as Map)['name'] ?? 'Unknown';
                    return DropdownMenuItem(value: loc.id, child: Text(name));
                  }),
                ],
                onChanged: (value) => setState(() => _selectedLocation = value!),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShopList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').snapshots(),
      builder: (context, shopsSnapshot) {
        if (shopsSnapshot.hasError) {
          return Center(child: Text('Error: ${shopsSnapshot.error}'));
        }

        if (!shopsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, ordersSnapshot) {
            var shops = shopsSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final location = data['locationId'] ?? '';
              
              final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
              final matchesLocation = _selectedLocation == 'all' || location == _selectedLocation;
              
              return matchesSearch && matchesLocation;
            }).toList();

            if (shops.isEmpty) {
              return const Center(child: Text('No shops found'));
            }

            final orders = ordersSnapshot.data?.docs ?? [];
            final shopOrderCount = <String, int>{};
            final shopRevenue = <String, double>{};
            
            for (var order in orders) {
              final orderData = order.data() as Map;
              final shopId = orderData['shopId'];
              final paymentStatus = orderData['paymentStatus'] ?? 'pending';
              if (shopId != null) {
                shopOrderCount[shopId] = (shopOrderCount[shopId] ?? 0) + 1;
                // Only count paid orders in revenue
                if (paymentStatus == 'paid') {
                  final total = (orderData['totalAmount'] as num?)?.toDouble() ?? 0;
                  shopRevenue[shopId] = (shopRevenue[shopId] ?? 0) + total;
                }
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                final data = shop.data() as Map<String, dynamic>;
                final orderCount = shopOrderCount[shop.id] ?? 0;
                final revenue = shopRevenue[shop.id] ?? 0;
                
                return _ShopCard(
                  shopId: shop.id,
                  data: data,
                  orderCount: orderCount,
                  revenue: revenue,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String subtitle;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final String shopId;
  final Map<String, dynamic> data;
  final int orderCount;
  final double revenue;

  const _ShopCard({
    required this.shopId,
    required this.data,
    required this.orderCount,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final address = data['address'] ?? '';
    final ownerName = data['ownerName'] ?? '';
    final isActive = data['isActive'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Icon(Icons.store, color: isActive ? Colors.green : Colors.red),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.red)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address.isNotEmpty) Text(address, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text('$orderCount orders', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push('/admin/edit-shop/$shopId'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ownerName.isNotEmpty) _InfoRow(icon: Icons.person, label: 'Owner', value: ownerName),
                if (address.isNotEmpty) _InfoRow(icon: Icons.location_on, label: 'Address', value: address),
                _InfoRow(icon: Icons.shopping_cart, label: 'Total Orders', value: orderCount.toString()),
                _InfoRow(icon: Icons.attach_money, label: 'Total Revenue', value: '₹${revenue.toStringAsFixed(2)}'),
                _InfoRow(icon: Icons.trending_up, label: 'Avg Order Value', value: orderCount > 0 ? '₹${(revenue / orderCount).toStringAsFixed(2)}' : 'N/A'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Orders'),
                        onPressed: () {
                          context.push('/owner/shop-performance/$shopId');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(isActive ? Icons.block : Icons.check_circle),
                        label: Text(isActive ? 'Deactivate' : 'Activate'),
                        onPressed: () {
                          FirebaseFirestore.instance.collection('shops').doc(shopId).update({'isActive': !isActive});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
