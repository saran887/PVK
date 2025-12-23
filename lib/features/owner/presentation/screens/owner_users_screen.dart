import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class OwnerUsersScreen extends ConsumerStatefulWidget {
  const OwnerUsersScreen({super.key});

  @override
  ConsumerState<OwnerUsersScreen> createState() => _OwnerUsersScreenState();
}

class _OwnerUsersScreenState extends ConsumerState<OwnerUsersScreen> {
  String _selectedRole = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/admin/add-person'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(),
          
          // Filters
          _buildFilters(),
          
          // User List with Analytics
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }

        final users = snapshot.data!.docs;
        final roleCount = <String, int>{};
        final activeUsers = users.where((u) => (u.data() as Map)['isActive'] ?? true).length;

        for (var user in users) {
          final role = (user.data() as Map)['role'] ?? 'unknown';
          roleCount[role] = (roleCount[role] ?? 0) + 1;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.people,
                      title: 'Total Users',
                      value: users.length.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.check_circle,
                      title: 'Active Users',
                      value: activeUsers.toString(),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: roleCount.entries.map((e) {
                  return Chip(
                    avatar: const Icon(Icons.person, size: 16),
                    label: Text('${e.key}: ${e.value}'),
                    backgroundColor: _getRoleColor(e.key).withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ),
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
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedRole,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Roles')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'sales', child: Text('Sales')),
              DropdownMenuItem(value: 'billing', child: Text('Billing')),
              DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
            ],
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final role = data['role'] ?? '';
          
          final matchesSearch = _searchQuery.isEmpty || 
              name.contains(_searchQuery) || 
              email.contains(_searchQuery);
          final matchesRole = _selectedRole == 'all' || role == _selectedRole;
          
          return matchesSearch && matchesRole;
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            return _UserCard(userId: user.id, data: data);
          },
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red;
      case 'sales': return Colors.blue;
      case 'billing': return Colors.green;
      case 'delivery': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _UserCard({required this.userId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '';
    final role = data['role'] ?? 'unknown';
    final isActive = data['isActive'] ?? true;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role).withOpacity(0.1),
          child: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.red)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(_getRoleIcon(role), size: 14, color: _getRoleColor(role)),
                const SizedBox(width: 4),
                Text(role.toUpperCase(), style: TextStyle(fontSize: 12, color: _getRoleColor(role), fontWeight: FontWeight.bold)),
                if (createdAt != null) ...[
                  const SizedBox(width: 12),
                  Text('Joined: ${createdAt.day}/${createdAt.month}/${createdAt.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
            PopupMenuItem(
              value: 'toggle',
              child: Row(children: [Icon(isActive ? Icons.block : Icons.check_circle), const SizedBox(width: 8), Text(isActive ? 'Deactivate' : 'Activate')]),
            ),
            const PopupMenuItem(value: 'details', child: Row(children: [Icon(Icons.info), SizedBox(width: 8), Text('View Details')])),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                context.push('/admin/edit-person/$userId');
                break;
              case 'toggle':
                FirebaseFirestore.instance.collection('users').doc(userId).update({'isActive': !isActive});
                break;
              case 'details':
                _showUserDetails(context, userId, data);
                break;
            }
          },
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red;
      case 'sales': return Colors.blue;
      case 'billing': return Colors.green;
      case 'delivery': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings;
      case 'sales': return Icons.shopping_cart;
      case 'billing': return Icons.receipt_long;
      case 'delivery': return Icons.local_shipping;
      default: return Icons.person;
    }
  }

  void _showUserDetails(BuildContext context, String userId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Email', value: data['email'] ?? 'N/A'),
              _DetailRow(label: 'Role', value: data['role'] ?? 'N/A'),
              _DetailRow(label: 'Phone', value: data['phone'] ?? 'N/A'),
              _DetailRow(label: 'Employee ID', value: data['employeeId'] ?? 'N/A'),
              _DetailRow(label: 'Status', value: (data['isActive'] ?? true) ? 'Active' : 'Inactive'),
              if (data['createdAt'] != null)
                _DetailRow(label: 'Created', value: (data['createdAt'] as Timestamp).toDate().toString()),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
