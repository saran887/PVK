import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:pkv2/features/auth/providers/auth_provider.dart';
import 'package:pkv2/shared/widgets/animations.dart';

class OwnerUsersScreen extends ConsumerStatefulWidget {
  const OwnerUsersScreen({super.key});

  @override
  ConsumerState<OwnerUsersScreen> createState() => _OwnerUsersScreenState();
}

class _OwnerUsersScreenState extends ConsumerState<OwnerUsersScreen> {
  String _selectedRole = 'all';
  String _searchQuery = '';
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    if (authState.asData?.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             if (snapshot.error.toString().contains('permission-denied')) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
             }
             return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
          }

          final users = snapshot.data?.docs ?? [];

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsOverview(users),
                      const SizedBox(height: 24),
                      _buildFilters(),
                      const SizedBox(height: 20),
                      if (_showContent)
                      SlideFadeIn(
                        delay: const Duration(milliseconds: 250),
                        child: Text(
                          'Directory', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _buildUserSliverList(users),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/add-person'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.blue.shade800,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: const Text(
          'Employee Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.blue.shade600],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.people_alt_rounded, size: 120, color: Colors.white.withValues(alpha: 0.15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(List<QueryDocumentSnapshot> users) {
    if (!_showContent) return const SizedBox.shrink();

    final roleCount = <String, int>{};
    int activeUsers = 0;

    for (var user in users) {
      final data = user.data() as Map<String, dynamic>;
      final role = data['role'] ?? 'unknown';
      final isActive = data['isActive'] ?? true;
      
      roleCount[role] = (roleCount[role] ?? 0) + 1;
      if (isActive) activeUsers++;
    }

    return SlideFadeIn(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Staff',
                  users.length.toString(),
                  Icons.groups_rounded,
                  Colors.blue.shade700,
                  Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  activeUsers.toString(),
                  Icons.check_circle_rounded,
                  Colors.green.shade600,
                  Colors.green.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roleCount.entries.where((e) => e.key.toString().toLowerCase() != 'owner').map((e) {
              final color = _getRoleColor(e.key);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getRoleIcon(e.key), size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key.toUpperCase()} : ${e.value}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color mainColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mainColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: mainColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    if (!_showContent) return const SizedBox.shrink();
    return SlideFadeIn(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.blue.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                icon: Icon(Icons.tune_rounded, color: Colors.blue.shade700, size: 20),
                style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'sales', child: Text('Sales')),
                  DropdownMenuItem(value: 'billing', child: Text('Billing')),
                  DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value ?? 'all'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSliverList(List<QueryDocumentSnapshot> rawUsers) {
    if (!_showContent) return const SliverToBoxAdapter(child: SizedBox.shrink());

    var users = rawUsers.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? '').toString().toLowerCase();
      
      final matchesSearch = _searchQuery.isEmpty || 
          name.contains(_searchQuery) || 
          email.contains(_searchQuery);
      final matchesRole = _selectedRole == 'all' || role == _selectedRole;
      final isNotOwner = role != 'owner';
      
      return matchesSearch && matchesRole && isNotOwner;
    }).toList();

    if (users.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No employees found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final delayMs = 300 + (index * 50);
            return SlideFadeIn(
              delay: Duration(milliseconds: delayMs > 800 ? 800 : delayMs),
              child: _UserCard(userId: user.id, data: data),
            );
          },
          childCount: users.length,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red.shade600;
      case 'sales': return Colors.blue.shade600;
      case 'billing': return Colors.green.shade600;
      case 'delivery': return Colors.orange.shade600;
      default: return Colors.grey.shade600;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'sales': return Icons.storefront_rounded;
      case 'billing': return Icons.receipt_long_rounded;
      case 'delivery': return Icons.local_shipping_rounded;
      default: return Icons.person_rounded;
    }
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
    final roleColor = _getRoleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getRoleIcon(role), color: roleColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  role.toUpperCase(), 
                  style: TextStyle(fontSize: 11, color: roleColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                if (createdAt != null) ...[
                  const SizedBox(width: 8),
                  const Text('â€¢', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  Text(
                    'Joined ${createdAt.day}/${createdAt.month}/${createdAt.year}', 
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'details', 
              child: Row(children: [Icon(Icons.info_outline_rounded, size: 20, color: Colors.blue.shade600), const SizedBox(width: 12), const Text('View Details')]),
            ),
            PopupMenuItem(
              value: 'edit', 
              child: Row(children: [Icon(Icons.edit_rounded, size: 20, color: Colors.orange.shade600), const SizedBox(width: 12), const Text('Edit')]),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 20, color: isActive ? Colors.red.shade600 : Colors.green.shade600), 
                  const SizedBox(width: 12), 
                  Text(isActive ? 'Deactivate' : 'Activate', style: TextStyle(color: isActive ? Colors.red.shade700 : Colors.green.shade700)),
                ]
              ),
            ),
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

  void _showUserDetails(BuildContext context, String userId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_getRoleIcon(data['role'] ?? ''), color: _getRoleColor(data['role'] ?? '')),
            const SizedBox(width: 12),
            Expanded(child: Text(data['name'] ?? 'User Details', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(icon: Icons.email_rounded, label: 'Email', value: data['email'] ?? 'N/A'),
              _DetailRow(icon: Icons.badge_rounded, label: 'Role', value: (data['role'] ?? 'N/A').toString().toUpperCase()),
              _DetailRow(icon: Icons.phone_android_rounded, label: 'Phone', value: data['phone'] ?? 'N/A'),
              _DetailRow(icon: Icons.tag_rounded, label: 'Employee ID', value: data['code']?.toString() ?? 'N/A'),
              _DetailRow(icon: Icons.toggle_on_rounded, label: 'Status', value: (data['isActive'] ?? true) ? 'Active' : 'Inactive'),
              if (data['createdAt'] != null)
                _DetailRow(icon: Icons.calendar_today_rounded, label: 'Created', value: (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Close', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red.shade600;
      case 'sales': return Colors.blue.shade600;
      case 'billing': return Colors.green.shade600;
      case 'delivery': return Colors.orange.shade600;
      default: return Colors.grey.shade600;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'sales': return Icons.storefront_rounded;
      case 'billing': return Icons.receipt_long_rounded;
      case 'delivery': return Icons.local_shipping_rounded;
      default: return Icons.person_rounded;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey.shade400),
          const SizedBox(width: 12),
          SizedBox(
            width: 100, 
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.blueGrey.shade600))),
        ],
      ),
    );
  }
}
