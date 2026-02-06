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
  String _selectedPeriod = 'all'; // all, today, week, month
  DateTimeRange? _customDateRange;
  
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
  
  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // Period Filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onSelected: (value) {
              if (value == 'custom') {
                _selectCustomDateRange();
              } else {
                setState(() {
                  _selectedPeriod = value;
                  _customDateRange = null;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Time')),
              const PopupMenuItem(value: 'today', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'custom', child: Text('Custom Range')),
            ],
          ),
          // More Options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'refresh') {
                setState(() {});
              } else if (value == 'export') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              tabs: const [
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
                Tab(icon: Icon(Icons.people), text: 'Staff'),
                Tab(icon: Icon(Icons.store), text: 'Shops'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Period Indicator
          if (_selectedPeriod != 'all')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.black87),
                  const SizedBox(width: 8),
                  Text(
                    _getPeriodText(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPeriod = 'all';
                        _customDateRange = null;
                      });
                    },
                    child: const Text('Clear Filter'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(),
                _buildBillsTab(),
                _buildUsersTab(),
                _buildShopsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'custom':
        if (_customDateRange != null) {
          return '${DateFormat('MMM dd').format(_customDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_customDateRange!.end)}';
        }
        return 'Custom Range';
      default:
        return 'All Time';
    }
  }
  
  bool _isOrderInPeriod(DateTime? orderDate) {
    if (orderDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedPeriod) {
      case 'today':
        return orderDate.isAfter(today);
      case 'week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return orderDate.isAfter(weekStart);
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        return orderDate.isAfter(monthStart);
      case 'custom':
        if (_customDateRange != null) {
          return orderDate.isAfter(_customDateRange!.start.subtract(const Duration(days: 1))) &&
                 orderDate.isBefore(_customDateRange!.end.add(const Duration(days: 1)));
        }
        return true;
      default:
        return true;
    }
  }

  // Reports Tab - Revenue Analytics
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Header
          const Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Revenue Overview Cards
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              // Check for errors in orders stream
              if (snapshot.hasError) {
                return Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading orders: ${snapshot.error}'),
                  ),
                );
              }
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, productsSnapshot) {
                  // Check for errors in products stream
                  if (productsSnapshot.hasError) {
                    return Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error loading products: ${productsSnapshot.error}'),
                      ),
                    );
                  }
                  
                  // Show loading state
                  if (!snapshot.hasData || !productsSnapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading data...'),
                          ],
                        ),
                      ),
                    );
                  }

                  final allOrders = snapshot.data!.docs;
                  final products = productsSnapshot.data!.docs;
                  
                  // Filter orders based on selected period
                  final orders = allOrders.where((order) {
                    final data = order.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    return _isOrderInPeriod(createdAt);
                  }).toList();
                  
                  // Create a map of product buying prices
                  final productBuyingPrices = {
                    for (var doc in products)
                      doc.id: ((doc.data() as Map<String, dynamic>)['buyingPrice'] as num?)?.toDouble() ?? 0.0
                  };

                  double totalProfit = 0;
                  double totalRevenue = 0;
                  double totalBuyingCost = 0;
                  int totalOrdersCount = orders.length;
                  int completedCount = 0;
                  int pendingCount = 0;
                  
                  for (final order in orders) {
                    final data = order.data() as Map<String, dynamic>;
                    final items = data['items'] as List<dynamic>? ?? [];
                    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                    final status = data['status'] as String? ?? 'pending';
                    final paymentStatus = data['paymentStatus'] as String? ?? 'pending';
                    
                    if (status == 'delivered') completedCount++;
                    if (status == 'pending') pendingCount++;
                    
                    // Only count paid orders in revenue and profit
                    if (paymentStatus != 'paid') continue;
                    
                    double orderProfit = 0;
                    double orderCost = 0;
                    
                    for (var item in items) {
                      final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
                      final profit = (item['profit'] as num?)?.toDouble();
                      
                      if (profit != null) {
                        orderProfit += profit * quantity;
                      } else {
                        final price = (item['price'] as num?)?.toDouble() ?? 0;
                        var buyingPrice = (item['buyingPrice'] as num?)?.toDouble() ?? 0.0;
                        
                        if (buyingPrice == 0) {
                          final productId = item['productId'] as String?;
                          if (productId != null) {
                            buyingPrice = productBuyingPrices[productId] ?? 0.0;
                          }
                        }
                        
                        if (buyingPrice == 0 && price > 0) {
                          buyingPrice = price / 1.1;
                        }

                        if (price > 0) {
                          orderProfit += (price - buyingPrice) * quantity;
                          orderCost += buyingPrice * quantity;
                        }
                      }
                    }
                    
                    totalProfit += orderProfit;
                    totalRevenue += totalAmount;
                    totalBuyingCost += orderCost;
                  }

                  final profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0;
                  final avgOrderValue = totalOrdersCount > 0 ? totalRevenue / totalOrdersCount : 0;

                  return Column(
                    children: [
                      // Main Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildRevenueCard(
                              'Total Revenue',
                              totalRevenue,
                              Icons.payments,
                              Colors.blue,
                              subtitle: '$totalOrdersCount orders',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRevenueCard(
                              'Net Profit',
                              totalProfit,
                              Icons.trending_up,
                              Colors.green,
                              subtitle: '${profitMargin.toStringAsFixed(1)}% margin',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Secondary Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard2(
                              'Avg Order',
                              '₹${avgOrderValue.toStringAsFixed(0)}',
                              Icons.shopping_cart,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard2(
                              'Completed',
                              '$completedCount',
                              Icons.check_circle,
                              Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard2(
                              'Pending',
                              '$pendingCount',
                              Icons.pending,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Detailed Analytics Section
          Text(
            'Detailed Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, color: Colors.indigo.shade600, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Performance Metrics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          
          const SizedBox(height: 24),
          
          // Top Products Section
          Text(
            'Top Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildTopProductsSection(),
        ],
      ),
    );
  }
  
  Widget _buildTopProductsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading products: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Show loading state
        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Loading products...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          );
        }

        final allOrders = snapshot.data!.docs;
        final orders = allOrders.where((order) {
          final data = order.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          return _isOrderInPeriod(createdAt);
        }).toList();

        // Aggregate product sales
        final Map<String, Map<String, dynamic>> productSales = {};
        
        for (final order in orders) {
          final data = order.data() as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];
          
          for (var item in items) {
            final productId = item['productId'] as String? ?? 'unknown';
            final productName = item['name'] ?? item['productName'] ?? 'Unknown';
            final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
            final price = (item['price'] as num?)?.toDouble() ?? 0;
            
            if (!productSales.containsKey(productId)) {
              productSales[productId] = {
                'name': productName,
                'quantity': 0.0,
                'revenue': 0.0,
              };
            }
            
            productSales[productId]!['quantity'] = 
                (productSales[productId]!['quantity'] as double) + quantity;
            productSales[productId]!['revenue'] = 
                (productSales[productId]!['revenue'] as double) + (price * quantity);
          }
        }

        // Sort by revenue and get top 5
        final sortedProducts = productSales.entries.toList()
          ..sort((a, b) => (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));
        
        final topProducts = sortedProducts.take(5).toList();
        
        if (topProducts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No product data available', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: topProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                final name = product.value['name'];
                final quantity = product.value['quantity'];
                final revenue = product.value['revenue'];
                
                return Column(
                  children: [
                    if (index > 0) const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.indigo.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Sold: ${quantity.toStringAsFixed(0)} units'),
                      trailing: Text(
                        '₹${revenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
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
        // Check for errors
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(fontSize: 18, color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // Show loading state
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading orders...'),
              ],
            ),
          );
        }

        final allOrders = snapshot.data!.docs;
        
        // Filter orders based on selected period
        final orders = allOrders.where((order) {
          final data = order.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          return _isOrderInPeriod(createdAt);
        }).toList();
        
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                if (_selectedPeriod != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPeriod = 'all';
                        _customDateRange = null;
                      });
                    },
                    child: const Text('View all orders'),
                  ),
              ],
            ),
          );
        }
        
        // Calculate summary stats
        final totalAmount = orders.fold<double>(0, (sum, order) {
          final data = order.data() as Map<String, dynamic>;
          final paymentStatus = data['paymentStatus'] as String? ?? 'pending';
          // Only count paid orders
          if (paymentStatus == 'paid') {
            return sum + ((data['totalAmount'] as num?)?.toDouble() ?? 0.0);
          }
          return sum;
        });
        
        final completedOrders = orders.where((order) {
          final data = order.data() as Map<String, dynamic>;
          return data['status'] == 'delivered';
        }).length;

        return Column(
          children: [
            // Summary Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.indigo.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: _buildMiniStat('Total Orders', '${orders.length}', Icons.receipt),
                  ),
                  Container(width: 1, height: 40, color: Colors.indigo.shade200),
                  Expanded(
                    child: _buildMiniStat('Completed', '$completedOrders', Icons.check_circle),
                  ),
                  Container(width: 1, height: 40, color: Colors.indigo.shade200),
                  Expanded(
                    child: _buildMiniStat('Revenue', '₹${totalAmount.toStringAsFixed(0)}', Icons.payments),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final data = order.data() as Map<String, dynamic>;
                  return _buildBillCard(order.id, data);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(orderId, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    child: Icon(
                      Icons.receipt_long,
                      color: _getStatusColor(status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Order #${orderId.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${items.length} items',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (createdAt != null)
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM, h:mm a').format(createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      _buildStatusChip('$status'),
                      const SizedBox(width: 8),
                      _buildStatusChip('₹ $paymentStatus'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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
        // Check for errors
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: TextStyle(fontSize: 18, color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // Show loading state
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading users...'),
              ],
            ),
          );
        }

        // Filter for Sales and Delivery roles only
        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] as String? ?? '').toLowerCase();
          return role.contains('sales') || role.contains('delivery');
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No Sales or Delivery staff found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Calculate summary stats
        int totalSalesStaff = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['role'] as String? ?? '').toLowerCase().contains('sales');
        }).length;
        
        int totalDeliveryStaff = users.length - totalSalesStaff;

        return Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.indigo.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: _buildMiniStat('Sales Staff', '$totalSalesStaff', Icons.point_of_sale),
                  ),
                  Container(width: 1, height: 40, color: Colors.indigo.shade200),
                  Expanded(
                    child: _buildMiniStat('Delivery Staff', '$totalDeliveryStaff', Icons.local_shipping),
                  ),
                  Container(width: 1, height: 40, color: Colors.indigo.shade200),
                  Expanded(
                    child: _buildMiniStat('Total Staff', '${users.length}', Icons.people),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;
                  return _buildUserCard(user.id, data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final name = userData['name'] as String? ?? 'Unknown User';
    final email = userData['email'] as String? ?? 'No email';
    final role = userData['role'] as String? ?? 'user';
    final isSales = role.toLowerCase().contains('sales');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isSales ? Colors.blue.shade100 : Colors.orange.shade100,
          child: Icon(
            isSales ? Icons.point_of_sale : Icons.local_shipping,
            color: isSales ? Colors.blue.shade800 : Colors.orange.shade800,
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSales ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSales ? Colors.blue.shade800 : Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
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
              int pendingOrders = 0;
              final Set<String> uniqueShops = {};
              final bool isDelivery = role.toLowerCase().contains('delivery');

              for (final order in orders) {
                final orderData = order.data() as Map<String, dynamic>;
                final paymentStatus = orderData['paymentStatus'] as String? ?? 'pending';
                // Only count paid orders in sales
                if (paymentStatus == 'paid') {
                  totalSales += (orderData['totalAmount'] as num?)?.toDouble() ?? 0;
                }
                final status = orderData['status'] as String? ?? '';
                if (status == 'delivered') {
                  deliveredOrders++;
                } else if (status == 'billed' || status == 'out_for_delivery' || status == 'ready_for_delivery') {
                  pendingOrders++;
                  if (status == 'billed') billedOrders++;
                }
                
                final shopId = orderData['shopId'] as String?;
                if (shopId != null) uniqueShops.add(shopId);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (isSales) ...[
                                Expanded(child: _buildStatTile('Total Sales', '₹${totalSales.toStringAsFixed(2)}', Colors.green)),
                                Expanded(child: _buildStatTile('Total Orders', '${orders.length}', Colors.blue)),
                              ] else ...[
                                Expanded(child: _buildStatTile('Total Orders', '${orders.length}', Colors.blue)),
                                Expanded(child: _buildStatTile('Shops Covered', '${uniqueShops.length}', Colors.purple)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (isSales) ...[
                                Expanded(child: _buildStatTile('Shops Covered', '${uniqueShops.length}', Colors.purple)),
                                Expanded(child: _buildStatTile('Delivered', '$deliveredOrders', Colors.orange)),
                              ] else if (isDelivery) ...[
                                Expanded(child: _buildStatTile('Completed', '$deliveredOrders', Colors.green)),
                                Expanded(child: _buildStatTile('Pending', '$pendingOrders', Colors.orange)),
                              ] else ...[
                                Expanded(child: _buildStatTile('Completed', '$deliveredOrders', Colors.green)),
                                Expanded(child: _buildStatTile('In Progress', '$billedOrders', Colors.orange)),
                              ],
                            ],
                          ),
                        ],
                      ),
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
        // Check for errors
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading shops',
                  style: TextStyle(fontSize: 18, color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // Show loading state
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading shops...'),
              ],
            ),
          );
        }

        final shops = snapshot.data!.docs;
        
        if (shops.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No shops found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        
        // Group shops by location
        final shopsByLocation = <String, List<QueryDocumentSnapshot>>{};
        int activeShops = 0;
        
        for (final shop in shops) {
          final data = shop.data() as Map<String, dynamic>;
          // Check multiple possible field names for location
          final location = data['locationName'] as String? ?? 
                          data['location'] as String?;
          final locationKey = (location == null || location.isEmpty) 
              ? 'Unassigned Location' 
              : location;
          shopsByLocation.putIfAbsent(locationKey, () => []).add(shop);
          if (data['isActive'] == true) activeShops++;
        }
        
        // Sort locations, but put "Unassigned Location" at the end
        final sortedLocations = shopsByLocation.keys.toList()..sort((a, b) {
          if (a == 'Unassigned Location') return 1;
          if (b == 'Unassigned Location') return -1;
          return a.compareTo(b);
        });

        return Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.indigo.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: _buildMiniStat('Locations', '${shopsByLocation.length}', Icons.location_on),
                  ),
                  Container(width: 1, height: 40, color: Colors.indigo.shade200),
                  Expanded(
                    child: _buildMiniStat('Total Shops', '${shops.length}', Icons.store),
                  ),
                  Container(width: 1, height: 40, color: Colors.indigo.shade200),
                  Expanded(
                    child: _buildMiniStat('Active', '$activeShops', Icons.check_circle),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedLocations.length,
                itemBuilder: (context, index) {
                  final location = sortedLocations[index];
                  final locationShops = shopsByLocation[location]!;
                  final activeCount = locationShops.where((shop) {
                    final data = shop.data() as Map<String, dynamic>;
                    return data['isActive'] == true;
                  }).length;
                  
                  final isUnassigned = location == 'Unassigned Location';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isUnassigned 
                            ? Colors.grey.shade200 
                            : Colors.indigo.shade100,
                        child: Icon(
                          isUnassigned ? Icons.location_off : Icons.location_city,
                          color: isUnassigned 
                              ? Colors.grey.shade700 
                              : Colors.indigo.shade800,
                        ),
                      ),
                      title: Text(
                        location,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isUnassigned ? Colors.grey.shade700 : null,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(Icons.store, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${locationShops.length} shops'),
                          const SizedBox(width: 12),
                          Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text('$activeCount active'),
                        ],
                      ),
                      children: locationShops.map((shop) {
                        final data = shop.data() as Map<String, dynamic>;
                        return _buildShopCard(shop.id, data);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade300,
          child: Icon(
            Icons.store,
            color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (phone.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
            ],
          ),
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
                  child: Center(child: CircularProgressIndicator()),
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
                final paymentStatus = orderData['paymentStatus'] as String? ?? 'pending';
                
                // Only count paid orders in total purchases
                if (paymentStatus == 'paid') {
                  totalPurchases += amount;
                }
                
                final status = orderData['status'] as String? ?? 'pending';
                
                if (status == 'pending' || paymentStatus == 'pending') {
                  pendingAmount += amount;
                  if (status == 'pending') pendingOrders++;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                        ],
                      ),
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
  Widget _buildRevenueCard(String title, double value, IconData icon, Color color, {String? subtitle}) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₹${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard2(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
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

            final allOrders = snapshot.data!.docs;
            final products = productsSnapshot.data!.docs;
            
            // Filter orders based on selected period
            final orders = allOrders.where((order) {
              final data = order.data() as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              return _isOrderInPeriod(createdAt);
            }).toList();
            
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
            final cancelledOrders = orders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'cancelled';
            }).length;
            
            // Count unique shops and customers
            final uniqueShops = orders.map((order) {
              final data = order.data() as Map<String, dynamic>;
              return data['shopId'] as String? ?? '';
            }).where((id) => id.isNotEmpty).toSet().length;
            
            final uniqueCustomers = orders.map((order) {
              final data = order.data() as Map<String, dynamic>;
              return data['userId'] as String? ?? '';
            }).where((id) => id.isNotEmpty).toSet().length;
            
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
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  var buyingPrice = (item['buyingPrice'] as num?)?.toDouble() ?? 0.0;
                  
                  if (buyingPrice == 0) {
                    final productId = item['productId'] as String?;
                    if (productId != null) {
                      buyingPrice = productBuyingPrices[productId] ?? 0.0;
                    }
                  }
                  
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
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.88,
              children: [
                _buildStatCard('Orders', totalOrders.toString(), Icons.shopping_bag, Colors.blue),
                _buildStatCard('Completed', completedOrders.toString(), Icons.check_circle, Colors.green),
                _buildStatCard('Pending', pendingOrders.toString(), Icons.pending, Colors.orange),
                _buildStatCard('Cancelled', cancelledOrders.toString(), Icons.cancel, Colors.red),
                _buildStatCard('Shops', uniqueShops.toString(), Icons.store, Colors.purple),
                _buildStatCard('Customers', uniqueCustomers.toString(), Icons.people, Colors.teal),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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