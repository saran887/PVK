import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Bills'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.store), text: 'Shops'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildBillsTab(),
          _buildUsersTab(),
          _buildShopsTab(),
        ],
      ),
    );
  }

  // Reports Tab - Revenue Analytics
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Revenue Overview Cards
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, productsSnapshot) {
                  if (!snapshot.hasData || !productsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = snapshot.data!.docs;
                  final products = productsSnapshot.data!.docs;
                  
                  // Create a map of product buying prices
                  final productBuyingPrices = {
                    for (var doc in products)
                      doc.id: ((doc.data() as Map<String, dynamic>)['buyingPrice'] as num?)?.toDouble() ?? 0.0
                  };

                  double totalProfit = 0;
                  double todayProfit = 0;
                  double weekProfit = 0;
                  double monthProfit = 0;
                  
                  double totalRevenue = 0;
                  double todayRevenue = 0;
                  double weekRevenue = 0;
                  double monthRevenue = 0;
                  
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final weekStart = today.subtract(Duration(days: today.weekday - 1));
                  final monthStart = DateTime(now.year, now.month, 1);

                  for (final order in orders) {
                    final data = order.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final items = data['items'] as List<dynamic>? ?? [];
                    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                    
                    double orderProfit = 0;
                    for (var item in items) {
                      final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
                      final profit = (item['profit'] as num?)?.toDouble();
                      
                      if (profit != null) {
                        orderProfit += profit * quantity;
                      } else {
                        // Fallback calculation
                        final price = (item['price'] as num?)?.toDouble() ?? 0;
                        var buyingPrice = (item['buyingPrice'] as num?)?.toDouble() ?? 0.0;
                        
                        if (buyingPrice == 0) {
                          final productId = item['productId'] as String?;
                          if (productId != null) {
                            buyingPrice = productBuyingPrices[productId] ?? 0.0;
                          }
                        }
                        
                        // Final fallback: assume standard margin (Selling = 1.1 * Buying)
                        if (buyingPrice == 0 && price > 0) {
                          buyingPrice = price / 1.1;
                        }

                        if (price > 0) {
                          orderProfit += (price - buyingPrice) * quantity;
                        }
                      }
                    }
                    
                    totalProfit += orderProfit;
                    totalRevenue += totalAmount;
                    
                    if (createdAt != null) {
                      if (createdAt.isAfter(today)) {
                        todayProfit += orderProfit;
                        todayRevenue += totalAmount;
                      }
                      if (createdAt.isAfter(weekStart)) {
                        weekProfit += orderProfit;
                        weekRevenue += totalAmount;
                      }
                      if (createdAt.isAfter(monthStart)) {
                        monthProfit += orderProfit;
                        monthRevenue += totalAmount;
                      }
                    }
                  }

                  return Column(
                    children: [
                      // Revenue Section
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('Revenue (Sales)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildRevenueCard('Total Revenue', totalRevenue, Icons.attach_money, Colors.indigo)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRevenueCard('Today Revenue', todayRevenue, Icons.today, Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Profit Section
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Profit (Net)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildRevenueCard('Total Profit', totalProfit, Icons.currency_rupee, Colors.green)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRevenueCard('Today Profit', todayProfit, Icons.today, Colors.teal)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildRevenueCard('Week Profit', weekProfit, Icons.date_range, Colors.orange)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRevenueCard('Month Profit', monthProfit, Icons.calendar_month, Colors.purple)),
                        ],
                      ),
                    ],
                  );
                }
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Quick Analytics
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.indigo.shade600, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Profit Analytics',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAnalyticsGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bills Tab - Orders with Status
  Widget _buildBillsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;
            return _buildBillCard(order.id, data);
          },
        );
      },
    );
  }

  Widget _buildBillCard(String orderId, Map<String, dynamic> data) {
    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = data['status'] as String? ?? 'pending';
    final paymentStatus = data['paymentStatus'] as String? ?? 'pending';
    final shopName = data['shopName'] as String? ?? 'Unknown Shop';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final items = data['items'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showOrderDetails(orderId, data),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(
            Icons.receipt_long,
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          '$shopName - Order #${orderId.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items: ${items.length} • Amount: ₹${totalAmount.toStringAsFixed(2)}'),
            if (createdAt != null)
              Text('Date: ${DateFormat('dd MMM yyyy, h:mm a').format(createdAt)}'),
            Row(
              children: [
                _buildStatusChip('Order: $status'),
                const SizedBox(width: 8),
                _buildStatusChip('Payment: $paymentStatus'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  void _showOrderDetails(String orderId, Map<String, dynamic> orderData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return OrderDetailsSheet(
            orderId: orderId,
            orderData: orderData,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  // Users Tab - User Work Details
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter for Sales and Delivery roles only
        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] as String? ?? '').toLowerCase();
          return role.contains('sales') || role.contains('delivery');
        }).toList();

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No Sales or Delivery staff found', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            return _buildUserCard(user.id, data);
          },
        );
      },
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final name = userData['name'] as String? ?? 'Unknown User';
    final email = userData['email'] as String? ?? 'No email';
    final role = userData['role'] as String? ?? 'user';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: role.toLowerCase().contains('sales') 
              ? Colors.blue.shade100 
              : Colors.orange.shade100,
          child: Icon(
            role.toLowerCase().contains('sales') ? Icons.point_of_sale : Icons.local_shipping,
            color: role.toLowerCase().contains('sales') ? Colors.blue.shade800 : Colors.orange.shade800,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$email • ${role.toUpperCase()}'),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (!orderSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final orders = orderSnapshot.data!.docs.toList();
              // Sort locally to avoid index requirements
              orders.sort((a, b) {
                final aDate = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bDate = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return bDate.compareTo(aDate); // Descending
              });

              double totalSales = 0;
              int deliveredOrders = 0;
              int billedOrders = 0;
              final Set<String> uniqueShops = {};

              for (final order in orders) {
                final orderData = order.data() as Map<String, dynamic>;
                totalSales += (orderData['totalAmount'] as num?)?.toDouble() ?? 0;
                final status = orderData['status'] as String? ?? '';
                if (status == 'delivered') deliveredOrders++;
                if (status == 'billed') billedOrders++;
                
                final shopId = orderData['shopId'] as String?;
                if (shopId != null) uniqueShops.add(shopId);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatTile('Total Sales', '₹${totalSales.toStringAsFixed(2)}', Colors.green)),
                        Expanded(child: _buildStatTile('Total Orders', '${orders.length}', Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatTile('Shops Covered', '${uniqueShops.length}', Colors.purple)),
                        Expanded(child: _buildStatTile('Delivered', '$deliveredOrders', Colors.orange)),
                      ],
                    ),
                    if (orders.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Recent Activity:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...orders.take(5).map((order) {
                        final data = order.data() as Map<String, dynamic>;
                        final date = (data['createdAt'] as Timestamp?)?.toDate();
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long, size: 20, color: Colors.grey),
                          title: Text('${data['shopName'] ?? 'Unknown Shop'}'),
                          subtitle: Text(date != null ? DateFormat('dd MMM, h:mm a').format(date) : ''),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${(data['totalAmount'] ?? 0).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              _buildStatusText(data['status'] ?? 'pending'),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusText(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered': color = Colors.green; break;
      case 'billed': color = Colors.orange; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Text(
      status.toUpperCase(),
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
    );
  }

  // Shops Tab - Shop Details by Location
  Widget _buildShopsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final shops = snapshot.data!.docs;
        // Group shops by location
        final shopsByLocation = <String, List<QueryDocumentSnapshot>>{};
        
        for (final shop in shops) {
          final data = shop.data() as Map<String, dynamic>;
          final location = data['location'] as String? ?? 'Unknown Location';
          shopsByLocation.putIfAbsent(location, () => []).add(shop);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shopsByLocation.length,
          itemBuilder: (context, index) {
            final location = shopsByLocation.keys.elementAt(index);
            final locationShops = shopsByLocation[location]!;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(
                  location,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text('${locationShops.length} shops'),
                children: locationShops.map((shop) {
                  final data = shop.data() as Map<String, dynamic>;
                  return _buildShopCard(shop.id, data);
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopCard(String shopId, Map<String, dynamic> shopData) {
    final name = shopData['name'] as String? ?? 'Unknown Shop';
    final address = shopData['address'] as String? ?? 'No address';
    final phone = shopData['phone'] as String? ?? 'No phone';
    final isActive = shopData['isActive'] as bool? ?? true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            Icons.store,
            color: isActive ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address.isNotEmpty) Text(address),
            if (phone.isNotEmpty) Text(phone),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('shopId', isEqualTo: shopId)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (!orderSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final orders = orderSnapshot.data!.docs.toList();
              // Sort locally to avoid index requirements
              orders.sort((a, b) {
                final aDate = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bDate = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return bDate.compareTo(aDate); // Descending
              });

              double totalPurchases = 0;
              double pendingAmount = 0;
              int pendingOrders = 0;

              for (final order in orders) {
                final orderData = order.data() as Map<String, dynamic>;
                final amount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0;
                totalPurchases += amount;
                
                final status = orderData['status'] as String? ?? 'pending';
                final paymentStatus = orderData['paymentStatus'] as String? ?? 'pending';
                
                if (status == 'pending' || paymentStatus == 'pending') {
                  pendingAmount += amount;
                  if (status == 'pending') pendingOrders++;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatTile('Total Purchases', '₹${totalPurchases.toStringAsFixed(2)}', Colors.green)),
                        Expanded(child: _buildStatTile('Total Orders', '${orders.length}', Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatTile('Pending Amount', '₹${pendingAmount.toStringAsFixed(2)}', Colors.orange)),
                        Expanded(child: _buildStatTile('Pending Orders', '$pendingOrders', Colors.red)),
                      ],
                    ),
                    if (orders.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Recent Orders:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...orders.take(3).map((order) {
                        final data = order.data() as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          title: Text('Order #${order.id.substring(0, 8)}'),
                          subtitle: Text('₹${(data['totalAmount'] ?? 0).toStringAsFixed(2)}'),
                          trailing: _buildStatusChip(data['status'] ?? 'pending'),
                          onTap: () => _showOrderDetails(order.id, data),
                        );
                      }),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildRevenueCard(String title, double value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${value.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productsSnapshot) {
            if (!snapshot.hasData || !productsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!.docs;
            final products = productsSnapshot.data!.docs;
            
            // Create a map of product buying prices
            final productBuyingPrices = {
              for (var doc in products)
                doc.id: ((doc.data() as Map<String, dynamic>)['buyingPrice'] as num?)?.toDouble() ?? 0.0
            };

            final totalOrders = orders.length;
            final pendingOrders = orders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'pending';
            }).length;
            final completedOrders = orders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'delivered';
            }).length;
            
            double totalProfit = 0;
            for (final order in orders) {
              final data = order.data() as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>? ?? [];
              
              for (var item in items) {
                final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
                final profit = (item['profit'] as num?)?.toDouble();
                
                if (profit != null) {
                  totalProfit += profit * quantity;
                } else {
                  // Fallback calculation
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  var buyingPrice = (item['buyingPrice'] as num?)?.toDouble() ?? 0.0;
                  
                  if (buyingPrice == 0) {
                    final productId = item['productId'] as String?;
                    if (productId != null) {
                      buyingPrice = productBuyingPrices[productId] ?? 0.0;
                    }
                  }
                  
                  // Final fallback: assume standard margin (Selling = 1.1 * Buying)
                  if (buyingPrice == 0 && price > 0) {
                    buyingPrice = price / 1.1;
                  }

                  if (price > 0) {
                    totalProfit += (price - buyingPrice) * quantity;
                  }
                }
              }
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total Orders', totalOrders.toString(), Icons.shopping_bag),
                _buildStatCard('Pending', pendingOrders.toString(), Icons.pending),
                _buildStatCard('Completed', completedOrders.toString(), Icons.check_circle),
                _buildStatCard('Profit', '₹${totalProfit.toStringAsFixed(2)}', Icons.monetization_on),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.indigo.shade600),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    final statusText = status.toLowerCase();
    
    if (statusText.contains('paid') || statusText.contains('delivered')) {
      color = Colors.green;
    } else if (statusText.contains('pending')) {
      color = Colors.orange;
    } else if (statusText.contains('cancelled') || statusText.contains('failed')) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'billed':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Order Details Sheet Widget
class OrderDetailsSheet extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final ScrollController scrollController;

  const OrderDetailsSheet({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List? ?? [];
    final totalAmount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = orderData['status'] as String? ?? 'pending';
    final paymentStatus = orderData['paymentStatus'] as String? ?? 'pending';
    final paymentMode = orderData['paymentMode'] as String? ?? 'cash';
    final shopName = orderData['shopName'] as String? ?? 'Unknown Shop';
    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Order Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${orderId.substring(0, 8)}', 
                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Shop: $shopName'),
                        if (createdAt != null)
                          Text('Date: ${DateFormat('dd MMM yyyy, h:mm a').format(createdAt)}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusChip('Order: $status'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Payment: $paymentStatus'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Payment Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Information', 
                                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Mode:'),
                            Text(paymentMode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Status:'),
                            _buildStatusChip(paymentStatus),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('₹${totalAmount.toStringAsFixed(2)}', 
                                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Items
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items (${items.length})', 
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          const Text('No items found')
                        else
                          ...items.map((item) {
                            final itemData = item as Map<String, dynamic>;
                            // Handle both 'name' and 'productName' field variations
                            final itemName = itemData['name'] ?? itemData['productName'] ?? 'Unknown Item';
                            final quantity = itemData['quantity'] ?? 1;
                            final price = itemData['price'] ?? 0;
                            final totalPrice = (price * quantity);
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(itemName),
                                  ),
                                  Text('Qty: $quantity'),
                                  const SizedBox(width: 8),
                                  Text('₹${totalPrice.toStringAsFixed(2)}'),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    final statusText = status.toLowerCase();
    
    if (statusText.contains('paid') || statusText.contains('delivered')) {
      color = Colors.green;
    } else if (statusText.contains('pending')) {
      color = Colors.orange;
    } else if (statusText.contains('cancelled') || statusText.contains('failed')) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}