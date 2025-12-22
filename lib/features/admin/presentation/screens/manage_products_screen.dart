import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => context.push('/admin/add-product'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data?.docs ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No products found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          // Group products by category
          final Map<String, List<QueryDocumentSnapshot>> groupedProducts = {};
          for (var doc in products) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] as String? ?? 'Uncategorized';
            if (!groupedProducts.containsKey(category)) {
              groupedProducts[category] = [];
            }
            groupedProducts[category]!.add(doc);
          }

          // Sort categories
          final sortedCategories = groupedProducts.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedCategories.length,
            itemBuilder: (context, categoryIndex) {
              final category = sortedCategories[categoryIndex];
              final categoryProducts = groupedProducts[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${categoryProducts.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: categoryProducts.length,
                    itemBuilder: (context, index) {
                      final productDoc = categoryProducts[index];
                      final product = productDoc.data() as Map<String, dynamic>;
                      final productId = productDoc.id;
                      final name = product['name'] ?? 'Unknown';
                      // Use sellingPrice if available, otherwise price
                      final price = product['sellingPrice'] ?? product['price'] ?? 0;
                      final buyingPrice = product['buyingPrice'] ?? 0;
                      final imageUrl = product['imageUrl'] ?? '';
                      final weight = product['weight'] ?? '';
                      final weightUnit = product['weightUnit'] ?? '';
                      final quantity = product['quantity'] ?? '';
                      final quantityUnit = product['quantityUnit'] ?? '';
                      
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if ((weight != null && weight != '' && weight != 0) && weightUnit.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(Icons.monitor_weight, size: 12, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$weight $weightUnit',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (buyingPrice > 0)
                                          Text(
                                            'Buy: ₹${buyingPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 15,
                                              ),
                                            ),
                                            PopupMenuButton(
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) async {
                                            if (value == 'delete') {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Delete Product'),
                                                  content: Text('Are you sure you want to delete $name?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                await FirebaseFirestore.instance
                                                    .collection('products')
                                                    .doc(productId)
                                                    .delete();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('$name deleted'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              }
                                            } else if (value == 'edit') {
                                              context.push('/admin/edit-product/$productId');
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24), // Spacing between categories
                ],
              );
            },
          );
        },
      ),
    );
  }
}
