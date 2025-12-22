import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedReportsScreen extends ConsumerStatefulWidget {
  const EnhancedReportsScreen({super.key});

  @override
  ConsumerState<EnhancedReportsScreen> createState() => _EnhancedReportsScreenState();
}

class _EnhancedReportsScreenState extends ConsumerState<EnhancedReportsScreen> {
  String? selectedLocationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profit Overview Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepPurple, Colors.purple],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Total Profit',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                      builder: (context, snapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('products').snapshots(),
                          builder: (context, productsSnapshot) {
                            if (!snapshot.hasData || !productsSnapshot.hasData) {
                              return const Text(
                                '₹0.00',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            // Create a map of product buying prices
                            final productBuyingPrices = {
                              for (var doc in productsSnapshot.data!.docs)
                                doc.id: ((doc.data() as Map<String, dynamic>)['buyingPrice'] as num?)?.toDouble() ?? 0.0
                            };
                            
                            double totalProfit = 0;
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
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
                                  
                                  // If buying price is missing in order, try to get from current product
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
                            
                            return Text(
                              '₹${totalProfit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Filter Section
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('locations').snapshots(),
                builder: (context, locationsSnapshot) {
                  if (!locationsSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final locations = locationsSnapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'name': data['name'] ?? 'Unknown',
                    };
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: selectedLocationId,
                    decoration: InputDecoration(
                      labelText: 'Filter by Location',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Locations'),
                      ),
                      ...locations.map((location) {
                        return DropdownMenuItem<String>(
                          value: location['id'],
                          child: Text(location['name']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedLocationId = value;
                      });
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Cards
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                    builder: (context, ordersSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, usersSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('products').snapshots(),
                            builder: (context, productsSnapshot) {
                              if (!ordersSnapshot.hasData || !usersSnapshot.hasData || !productsSnapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              var orders = ordersSnapshot.data!.docs;
                              var users = usersSnapshot.data!.docs;
                              var products = productsSnapshot.data!.docs;

                              // Apply location filter
                              if (selectedLocationId != null) {
                                orders = orders.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return data['shopLocationId'] == selectedLocationId;
                                }).toList();
                                
                                users = users.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return data['locationId'] == selectedLocationId;
                                }).toList();
                              }

                              // Create a map of product buying prices
                              final productBuyingPrices = {
                                for (var doc in products)
                                  doc.id: ((doc.data() as Map<String, dynamic>)['buyingPrice'] as num?)?.toDouble() ?? 0.0
                              };

                              final totalRevenue = orders.fold<double>(0, (sum, doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final items = data['items'] as List<dynamic>? ?? [];
                                double orderProfit = 0;
                                for (var item in items) {
                                  final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
                                  final profit = (item['profit'] as num?)?.toDouble();
                                  
                                  if (profit != null) {
                                    orderProfit += profit * quantity;
                                  } else {
                                    // Fallback calculation if profit field is missing
                                    final price = (item['price'] as num?)?.toDouble() ?? 0;
                                    var buyingPrice = (item['buyingPrice'] as num?)?.toDouble() ?? 0.0;
                                    
                                    // If buying price is missing in order, try to get from current product
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
                                return sum + orderProfit;
                              });

                              final totalOrders = orders.length;
                              final activeUsers = users.where((doc) => 
                                (doc.data() as Map<String, dynamic>)['isActive'] != false).length;
                              final totalProducts = products.length;

                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildStatCard(
                                    'Total Profit',
                                    '₹${totalRevenue.toStringAsFixed(2)}',
                                    Icons.attach_money,
                                    Colors.green,
                                    context,
                                  ),
                                  _buildStatCard(
                                    'Total Orders',
                                    totalOrders.toString(),
                                    Icons.shopping_cart,
                                    Colors.blue,
                                    context,
                                  ),
                                  _buildStatCard(
                                    'Active Users',
                                    activeUsers.toString(),
                                    Icons.people,
                                    Colors.orange,
                                    context,
                                  ),
                                  _buildStatCard(
                                    'Total Products',
                                    totalProducts.toString(),
                                    Icons.inventory,
                                    Colors.purple,
                                    context,
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // User Performance Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person_outline, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'User Performance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, ordersSnapshot) {
                            if (!ordersSnapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            var orders = ordersSnapshot.data!.docs;
                            if (selectedLocationId != null) {
                              orders = orders.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return data['shopLocationId'] == selectedLocationId;
                              }).toList();
                            }

                            // Group orders by user
                            Map<String, Map<String, dynamic>> userStats = {};
                            for (var doc in orders) {
                              final data = doc.data() as Map<String, dynamic>;
                              final userId = data['userId'] ?? 'Unknown';
                              final userName = data['userName'] ?? 'Unknown User';
                              final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;

                              if (!userStats.containsKey(userId)) {
                                userStats[userId] = {
                                  'name': userName,
                                  'orders': 0,
                                  'revenue': 0.0,
                                };
                              }
                              userStats[userId]!['orders']++;
                              userStats[userId]!['revenue'] = 
                                (userStats[userId]!['revenue'] as double) + amount;
                            }

                            final sortedUsers = userStats.entries.toList()
                              ..sort((a, b) => 
                                (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));

                            return Column(
                              children: sortedUsers.take(5).map((entry) {
                                final stats = entry.value;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo.withOpacity(0.1),
                                    child: Text(
                                      stats['name'].toString().substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(stats['name'].toString()),
                                  subtitle: Text('${stats['orders']} orders'),
                                  trailing: Text(
                                    '₹${(stats['revenue'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Shop Performance Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.store_outlined, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Shop Performance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, ordersSnapshot) {
                            if (!ordersSnapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            var orders = ordersSnapshot.data!.docs;
                            if (selectedLocationId != null) {
                              orders = orders.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return data['shopLocationId'] == selectedLocationId;
                              }).toList();
                            }

                            // Group orders by shop
                            Map<String, Map<String, dynamic>> shopStats = {};
                            for (var doc in orders) {
                              final data = doc.data() as Map<String, dynamic>;
                              final shopId = data['shopId'] ?? 'Unknown';
                              final shopName = data['shopName'] ?? 'Unknown Shop';
                              final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;

                              if (!shopStats.containsKey(shopId)) {
                                shopStats[shopId] = {
                                  'name': shopName,
                                  'orders': 0,
                                  'revenue': 0.0,
                                };
                              }
                              shopStats[shopId]!['orders']++;
                              shopStats[shopId]!['revenue'] = 
                                (shopStats[shopId]!['revenue'] as double) + amount;
                            }

                            final sortedShops = shopStats.entries.toList()
                              ..sort((a, b) => 
                                (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));

                            return Column(
                              children: sortedShops.take(5).map((entry) {
                                final stats = entry.value;
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Icon(Icons.store, color: Colors.white, size: 20),
                                  ),
                                  title: Text(stats['name'].toString()),
                                  subtitle: Text('${stats['orders']} orders'),
                                  trailing: Text(
                                    '₹${(stats['revenue'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Orders Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.receipt_outlined, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Recent Orders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .orderBy('createdAt', descending: true)
                              .limit(10)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            var orders = snapshot.data!.docs;
                            if (selectedLocationId != null) {
                              orders = orders.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return data['shopLocationId'] == selectedLocationId;
                              }).toList();
                            }

                            orders = orders.take(5).toList();

                            return Column(
                              children: orders.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final shopName = data['shopName'] ?? 'Unknown Shop';
                                final status = data['status'] ?? 'pending';
                                final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
                                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                                    child: Icon(
                                      _getStatusIcon(status),
                                      color: _getStatusColor(status),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(shopName),
                                  subtitle: Text(
                                    'Order #${doc.id.substring(0, 8)} • ${createdAt != null ? '${createdAt.day}/${createdAt.month}' : 'Unknown date'}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'billed':
        return Icons.receipt;
      case 'delivered':
        return Icons.local_shipping;
      default:
        return Icons.help_outline;
    }
  }
}