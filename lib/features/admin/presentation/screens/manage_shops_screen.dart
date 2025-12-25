import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ManageShopsScreen extends ConsumerStatefulWidget {
  const ManageShopsScreen({super.key});

  @override
  ConsumerState<ManageShopsScreen> createState() => _ManageShopsScreenState();
}

class _ManageShopsScreenState extends ConsumerState<ManageShopsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Search Header with Purple Gradient
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[700]!, Colors.purple[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'Manage Shops',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search shops...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.purple),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.purple),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // Shops List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shops')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final shops = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final owner = (data['ownerName'] as String? ?? '').toLowerCase();
                  final location = (data['locationName'] as String? ?? '').toLowerCase();
                  final address = (data['address'] as String? ?? '').toLowerCase();
                  return _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      owner.contains(_searchQuery) ||
                      location.contains(_searchQuery) ||
                      address.contains(_searchQuery);
                }).toList();

                if (shops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No shops yet' : 'No shops found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shopDoc = shops[index];
                    final shop = shopDoc.data() as Map<String, dynamic>;
                    final shopId = shopDoc.id;
                    final isActive = shop['isActive'] ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showShopDetails(context, shopId, shop),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon with gradient
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Shop Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          shop['ownerName'] ?? 'Unknown',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (shop['locationName'] != null || shop['address'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              shop['locationName'] ?? shop['address'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green[50] : Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive ? Colors.green : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/add-shop'),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add),
        label: const Text('Add Shop'),
      ),
    );
  }

  void _showShopDetails(BuildContext context, String shopId, Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            shop['ownerName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Shop Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (shop['phone'] != null && shop['phone'].toString().isNotEmpty)
                      _buildDetailRow(Icons.phone, 'Phone', shop['phone']),
                    if (shop['locationName'] != null && shop['locationName'].toString().isNotEmpty)
                      _buildDetailRow(Icons.location_city, 'Location', shop['locationName']),
                    if (shop['address'] != null && shop['address'].toString().isNotEmpty)
                      _buildDetailRow(Icons.home, 'Address', shop['address']),
                    if (shop['gstNumber'] != null && shop['gstNumber'].toString().isNotEmpty)
                      _buildDetailRow(Icons.receipt_long, 'GST Number', shop['gstNumber']),
                    _buildDetailRow(
                      shop['isActive'] == true ? Icons.check_circle : Icons.cancel,
                      'Status',
                      shop['isActive'] == true ? 'Active' : 'Inactive',
                      valueColor: shop['isActive'] == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/admin/edit-shop/$shopId');
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final isActive = shop['isActive'] ?? true;
                              await FirebaseFirestore.instance
                                  .collection('shops')
                                  .doc(shopId)
                                  .update({
                                'isActive': !isActive,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Shop ${!isActive ? "activated" : "deactivated"}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              shop['isActive'] == true
                                  ? Icons.toggle_off
                                  : Icons.toggle_on,
                            ),
                            label: Text(
                              shop['isActive'] == true ? 'Deactivate' : 'Activate',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: shop['isActive'] == true
                                  ? Colors.orange
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Shop'),
                            content: Text(
                                'Are you sure you want to delete ${shop['name']}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('shops')
                              .doc(shopId)
                              .delete();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${shop['name']} deleted'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
