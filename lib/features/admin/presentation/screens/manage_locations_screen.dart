import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ManageLocationsScreen extends ConsumerWidget {
  const ManageLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () => context.push('/admin/add-location'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('locations')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = snapshot.data?.docs ?? [];

          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No locations found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/add-location'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Location'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index].data() as Map<String, dynamic>;
              final locationId = locations[index].id;
              final name = location['name'] ?? 'Unknown';
              final area = location['area'] ?? '';
              final description = location['description'] ?? '';
              final isActive = location['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Color.alphaBlend(Colors.blue.withAlpha((0.1 * 255).toInt()), Colors.white) : Color.alphaBlend(Colors.grey.withAlpha((0.1 * 255).toInt()), Colors.white),
                    child: Icon(
                      Icons.location_city,
                      color: isActive ? Colors.blue : Colors.grey,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (area.isNotEmpty) Text('📍 $area'),
                      if (description.isNotEmpty) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(isActive ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 12)),
                        backgroundColor: isActive ? Color.alphaBlend(Colors.green.withAlpha((0.1 * 255).toInt()), Colors.white) : Color.alphaBlend(Colors.grey.withAlpha((0.1 * 255).toInt()), Colors.white),
                        labelStyle: TextStyle(
                          color: isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(isActive ? Icons.toggle_on : Icons.toggle_off, size: 20),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
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
                      if (value == 'toggle') {
                        await FirebaseFirestore.instance.collection('locations').doc(locationId).update({
                          'isActive': !isActive,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name ${!isActive ? 'activated' : 'deactivated'}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else if (value == 'edit') {
                        context.push('/admin/edit-location/$locationId');
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Location'),
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
                          await FirebaseFirestore.instance.collection('locations').doc(locationId).delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$name deleted'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
