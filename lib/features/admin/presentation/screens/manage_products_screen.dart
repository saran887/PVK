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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              final name = product['name'] ?? 'Unknown';
              final price = product['price'] ?? 0;
              final imageUrl = product['imageUrl'] ?? '';
              final category = product['category'] ?? '';
              final weight = product['weight'] ?? 0;
              final weightUnit = product['weightUnit'] ?? '';
              final quantity = product['quantity'] ?? 0;
              final quantityUnit = product['quantityUnit'] ?? '';
              
              // Debug print
              debugPrint('Product: $name, ImageURL: $imageUrl');

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Image load error for $name: $error');
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('Image not found', style: TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                    ),
                    Padding(
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
                          if (category.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.category, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    category,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (weight > 0 && weightUnit.isNotEmpty)
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
                          if (quantity > 0 && quantityUnit.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.inventory_2, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '$quantity $quantityUnit',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Edit product - Coming soon!')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
              ),
            ],
          );
        },
      ),
    );
  }
}
