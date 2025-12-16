import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/admin/add-person'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id.trim();
              final name = user['name'] ?? 'Unknown';
              final email = user['email'] ?? '';
              final role = user['role'] ?? 'USER';
              final phone = user['phone'] ?? '';
              final code = user['code']?.toString() ?? '';
              final isActive = user['isActive'] ?? true;

              Color getRoleColor() {
                switch (role.toLowerCase()) {
                  case 'owner':
                    return Colors.purple;
                  case 'admin':
                    return Colors.blue;
                  case 'sales':
                    return Colors.green;
                  case 'billing':
                    return Colors.orange;
                  case 'delivery':
                    return Colors.teal;
                  default:
                    return Colors.grey;
                }
              }

              IconData getRoleIcon() {
                switch (role.toLowerCase()) {
                  case 'owner':
                    return Icons.business_center;
                  case 'admin':
                    return Icons.admin_panel_settings;
                  case 'sales':
                    return Icons.shopping_cart;
                  case 'billing':
                    return Icons.receipt;
                  case 'delivery':
                    return Icons.local_shipping;
                  default:
                    return Icons.person;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color.alphaBlend(getRoleColor().withAlpha((0.1 * 255).toInt()), Colors.white),
                    child: Icon(getRoleIcon(), color: getRoleColor()),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (email.isNotEmpty) Text('📧 $email'),
                      if (phone.isNotEmpty) Text('📱 $phone'),
                      if (code.isNotEmpty) Text('🔑 Login Code: $code'),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(role, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Color.alphaBlend(getRoleColor().withAlpha((0.1 * 255).toInt()), Colors.white),
                        labelStyle: TextStyle(
                          color: getRoleColor(),
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
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({
                          'isActive': !isActive,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                      } else if (value == 'edit') {
                        context.push('/admin/edit-person/$userId');
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete User'),
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
                          await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$name deleted'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      } else if (value == 'edit') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit user - Coming soon!')),
                        );
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
