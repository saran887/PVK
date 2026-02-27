import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerProductsScreen extends ConsumerStatefulWidget {
  const OwnerProductsScreen({super.key});

  @override
  ConsumerState<OwnerProductsScreen> createState() => _OwnerProductsScreenState();
}

class _OwnerProductsScreenState extends ConsumerState<OwnerProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Analytics & Inventory'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildLowStockAlert()),
          SliverToBoxAdapter(child: _buildInventoryOverview()),
          SliverToBoxAdapter(child: _buildFilters()),
          _buildProductList(),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final products = snapshot.data!.docs;
        final lowStockProducts = products.where((p) {
          final data = p.data() as Map;
          final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
          final isActive = data['isActive'] ?? true;
          return quantity < 10 && isActive;
        }).toList();

        if (lowStockProducts.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'âš ï¸ LOW STOCK ALERT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '${lowStockProducts.length} product(s) need restocking',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.orange),
              const SizedBox(height: 8),
              ...lowStockProducts.take(3).map((product) {
                final data = product.data() as Map;
                final name = data['name'] ?? 'Unknown';
                final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: quantity == 0 ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: quantity == 0 ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quantity == 0 ? 'OUT OF STOCK' : '$quantity left',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (lowStockProducts.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${lowStockProducts.length - 3} more items with low stock',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, productsSnapshot) {
        if (!productsSnapshot.hasData) {
          return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, ordersSnapshot) {
            final products = productsSnapshot.data!.docs;
            final categoryCount = <String, int>{};
            final activeProducts = products.where((p) => (p.data() as Map)['isActive'] ?? true).length;
            int lowStockCount = 0;
            
            double totalInventoryValue = 0;
            for (var product in products) {
              final data = product.data() as Map;
              final category = data['category'] ?? 'Uncategorized';
              categoryCount[category] = (categoryCount[category] ?? 0) + 1;
              
              final price = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
              totalInventoryValue += price;
              
              final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
              if (quantity < 10 && (data['isActive'] ?? true)) {
                lowStockCount++;
              }
            }

            // Calculate product sales
            final orders = ordersSnapshot.data?.docs ?? [];
            final productSales = <String, int>{};
            final productRevenue = <String, double>{};
            
            for (var order in orders) {
              final orderData = order.data() as Map;
              final paymentStatus = orderData['paymentStatus'] ?? 'pending';
              final items = orderData['items'] as List? ?? [];
              for (var item in items) {
                final productId = item['productId'];
                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                final price = (item['price'] as num?)?.toDouble() ?? 0;
                
                if (productId != null) {
                  productSales[productId] = (productSales[productId] ?? 0) + quantity;
                  // Only count paid orders in revenue
                  if (paymentStatus == 'paid') {
                    productRevenue[productId] = (productRevenue[productId] ?? 0) + (price * quantity);
                  }
                }
              }
            }

            QueryDocumentSnapshot? topProduct;
            if (productSales.isNotEmpty && products.isNotEmpty) {
              final topProductId = productSales.entries.reduce((a, b) => a.value > b.value ? a : b).key;
              try {
                topProduct = products.firstWhere((p) => p.id == topProductId);
              } catch (e) {
                topProduct = null;
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory Insights', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.inventory_2,
                          title: 'Total Products',
                          value: products.length.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.check_circle,
                          title: 'Active',
                          value: activeProducts.toString(),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.attach_money,
                          title: 'Inventory Value',
                          value: '₹${totalInventoryValue.toStringAsFixed(0)}',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.trending_up,
                          title: 'Top Seller',
                          value: topProduct != null
                              ? ((topProduct.data() as Map)['name'] ?? 'N/A').toString().split(' ')[0]
                              : 'N/A',
                          color: Colors.purple,
                          subtitle: topProduct != null && productSales[topProduct.id] != null
                              ? '${productSales[topProduct.id]} sold'
                              : '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Categories: ${categoryCount.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (lowStockCount > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('$lowStockCount Low Stock Items', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
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
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              final products = snapshot.data?.docs ?? [];
              final categories = products.map((p) => (p.data() as Map)['category'] ?? 'Uncategorized').toSet().toList();
              categories.sort();
              
              return DropdownButton<String>(
                value: _selectedCategory,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                  ...categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value!),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, productsSnapshot) {
          if (productsSnapshot.hasError) {
            return Center(child: Text('Error: ${productsSnapshot.error}'));
          }

          if (!productsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, ordersSnapshot) {
              var products = productsSnapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final category = data['category'] ?? 'Uncategorized';
                
                final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
                final matchesCategory = _selectedCategory == 'all' || category == _selectedCategory;
                
                return matchesSearch && matchesCategory;
              }).toList();

              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No products found')),
                );
              }

              // Calculate sales data
              final orders = ordersSnapshot.data?.docs ?? [];
              final productSales = <String, int>{};
              final productRevenue = <String, double>{};
              
              for (var order in orders) {
                final orderData = order.data() as Map;
                final paymentStatus = orderData['paymentStatus'] ?? 'pending';
                final items = orderData['items'] as List? ?? [];
                for (var item in items) {
                  final productId = item['productId'];
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  
                  if (productId != null) {
                    productSales[productId] = (productSales[productId] ?? 0) + quantity;
                    // Only count paid orders in revenue
                    if (paymentStatus == 'paid') {
                      productRevenue[productId] = (productRevenue[productId] ?? 0) + (price * quantity);
                    }
                  }
                }
              }

              // Sort by sales (high to low)
              products.sort((a, b) {
                final aSales = productSales[a.id] ?? 0;
                final bSales = productSales[b.id] ?? 0;
                return bSales.compareTo(aSales);
              });

              // Group by category
              final Map<String, List<QueryDocumentSnapshot>> groupedProducts = {};
              for (var doc in products) {
                final data = doc.data() as Map<String, dynamic>;
                final category = data['category'] as String? ?? 'Uncategorized';
                if (!groupedProducts.containsKey(category)) {
                  groupedProducts[category] = [];
                }
                groupedProducts[category]!.add(doc);
              }

              final sortedCategories = groupedProducts.keys.toList()..sort();

              // Build a flat list of widgets
              final List<Widget> productWidgets = [];
              
              for (final category in sortedCategories) {
                final categoryProducts = groupedProducts[category]!;
                
                final categoryTotalSales = categoryProducts.fold<int>(0, (total, p) => total + (productSales[p.id] ?? 0));
                final categoryRevenue = categoryProducts.fold<double>(0, (total, p) => total + (productRevenue[p.id] ?? 0));

                // Add category header
                productWidgets.add(
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    color: Colors.blue.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('${categoryProducts.length} products â€¢ $categoryTotalSales sold â€¢ ₹${categoryRevenue.toStringAsFixed(0)} revenue',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                // Add products in this category
                for (var product in categoryProducts) {
                  final data = product.data() as Map<String, dynamic>;
                  final sales = productSales[product.id] ?? 0;
                  final revenue = productRevenue[product.id] ?? 0;
                  
                  productWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ProductCard(
                        productId: product.id,
                        data: data,
                        salesCount: sales,
                        revenue: revenue,
                      ),
                    ),
                  );
                }
                
                // Add spacing after category
                productWidgets.add(const SizedBox(height: 8));
              }

              return Column(
                children: productWidgets,
              );
            },
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String subtitle;

  const _InsightCard({
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
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;
  final int salesCount;
  final double revenue;

  const _ProductCard({
    required this.productId,
    required this.data,
    required this.salesCount,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['name'] ?? 'Unknown';
    final price = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
    final isActive = data['isActive'] ?? true;
    final imageUrl = (data['imageUrls'] as List?)?.firstOrNull ?? '';
    final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
    final isLowStock = quantity < 10;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover))
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (isLowStock && isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, size: 10, color: Colors.orange),
                    const SizedBox(width: 2),
                    Text('Low Stock ($quantity)', style: const TextStyle(fontSize: 9, color: Colors.orange)),
                  ],
                ),
              ),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Inactive', style: TextStyle(fontSize: 9, color: Colors.red)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹$price', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 12, color: Colors.blue),
                const SizedBox(width: 4),
                Text('$salesCount sold', style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 12),
                const Icon(Icons.attach_money, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () => _showProductAnalytics(context, productId, data, salesCount, revenue),
          tooltip: 'View Analytics',
        ),
      ),
    );
  }

  void _showProductAnalytics(BuildContext context, String productId, Map<String, dynamic> data, int sales, double revenue) {
    final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'Product Analytics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnalyticRow(label: 'Price', value: '₹${data['sellingPrice'] ?? 0}'),
              _AnalyticRow(label: 'Current Stock', value: '$quantity ${data['quantityUnit'] ?? 'units'}'),
              if (quantity < 10)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          quantity == 0 ? 'OUT OF STOCK!' : 'LOW STOCK WARNING!\nPlease reorder soon.',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              _AnalyticRow(label: 'Total Sales', value: '$sales units'),
              _AnalyticRow(label: 'Total Revenue', value: '₹${revenue.toStringAsFixed(2)}'),
              _AnalyticRow(label: 'Avg Revenue/Sale', value: sales > 0 ? '₹${(revenue / sales).toStringAsFixed(2)}' : 'N/A'),
              _AnalyticRow(label: 'Status', value: (data['isActive'] ?? true) ? 'Active' : 'Inactive'),
              _AnalyticRow(label: 'Category', value: data['category'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _AnalyticRow extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
