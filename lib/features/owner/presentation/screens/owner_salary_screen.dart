import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class OwnerSalaryScreen extends ConsumerStatefulWidget {
  const OwnerSalaryScreen({super.key});

  @override
  ConsumerState<OwnerSalaryScreen> createState() => _OwnerSalaryScreenState();
}

class _OwnerSalaryScreenState extends ConsumerState<OwnerSalaryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Salary Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Employee',
            onPressed: () {
              GoRouter.of(context).push('/admin/add-person');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSalarySummary(),
          _buildSearchBar(),
          Expanded(child: _buildEmployeeList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GoRouter.of(context).push('/admin/add-person');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }

  Widget _buildSalarySummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
        }

        final users = snapshot.data!.docs.where((u) {
          final data = u.data() as Map;
          return (data['isActive'] ?? true) && data['role'] != 'owner';
        }).toList();

        double totalSalaries = 0;
        int employeesWithSalary = 0;
        int employeesWithoutSalary = 0;

        for (var user in users) {
          final data = user.data() as Map;
          final salary = (data['salary'] as num?)?.toDouble() ?? 0;
          if (salary > 0) {
            totalSalaries += salary;
            employeesWithSalary++;
          } else {
            employeesWithoutSalary++;
          }
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Total Monthly Salary',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${totalSalaries.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white30),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    icon: Icons.people,
                    label: 'Total Employees',
                    value: '${users.length}',
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _SummaryItem(
                    icon: Icons.check_circle,
                    label: 'With Salary',
                    value: '$employeesWithSalary',
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _SummaryItem(
                    icon: Icons.warning,
                    label: 'Pending',
                    value: '$employeesWithoutSalary',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search employees...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildEmployeeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var employees = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final role = data['role'] ?? '';
          final isActive = data['isActive'] ?? true;

          final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
          final isNotOwner = role != 'owner';

          return matchesSearch && isNotOwner && isActive;
        }).toList();

        // Sort by salary (no salary first, then by amount)
        employees.sort((a, b) {
          final salaryA = ((a.data() as Map)['salary'] as num?)?.toDouble() ?? 0;
          final salaryB = ((b.data() as Map)['salary'] as num?)?.toDouble() ?? 0;
          
          if (salaryA == 0 && salaryB > 0) return -1;
          if (salaryB == 0 && salaryA > 0) return 1;
          return salaryB.compareTo(salaryA);
        });

        if (employees.isEmpty) {
          return const Center(child: Text('No employees found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            final data = employee.data() as Map<String, dynamic>;
            return _EmployeeCard(
              employeeId: employee.id,
              data: data,
              onSalaryUpdated: () => setState(() {}),
            );
          },
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final String employeeId;
  final Map<String, dynamic> data;
  final VoidCallback onSalaryUpdated;

  const _EmployeeCard({
    required this.employeeId,
    required this.data,
    required this.onSalaryUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final role = data['role'] ?? 'N/A';
    final salary = (data['salary'] as num?)?.toDouble() ?? 0;
    final employeeCode = data['code'] ?? data['employeeId'] ?? '';
    final hasSalary = salary > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasSalary ? 2 : 0,
      color: hasSalary ? null : Colors.orange.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role).withOpacity(0.1),
          child: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (!hasSalary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 12, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('No Salary', style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  role.toUpperCase(),
                  style: TextStyle(fontSize: 11, color: _getRoleColor(role), fontWeight: FontWeight.bold),
                ),
                if (employeeCode.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('• $employeeCode', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
            if (hasSalary) ...[
              const SizedBox(height: 4),
              Text(
                '₹${salary.toStringAsFixed(2)}/month',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(hasSalary ? Icons.edit : Icons.add),
          color: hasSalary ? Colors.blue : Colors.orange,
          onPressed: () => _showSalaryDialog(context),
        ),
      ),
    );
  }

  void _showSalaryDialog(BuildContext context) {
    final salaryController = TextEditingController(
      text: (data['salary'] ?? 0) > 0 ? (data['salary'] ?? 0).toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${(data['salary'] ?? 0) > 0 ? 'Update' : 'Set'} Salary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              (data['role'] ?? 'N/A').toUpperCase(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: salaryController,
              decoration: const InputDecoration(
                labelText: 'Monthly Salary',
                prefixText: '₹',
                border: OutlineInputBorder(),
                helperText: 'Enter the monthly salary amount',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if ((data['salary'] ?? 0) > 0)
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(employeeId)
                    .update({'salary': 0});
                Navigator.pop(context);
                onSalaryUpdated();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salary removed')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ElevatedButton(
            onPressed: () async {
              final salary = double.tryParse(salaryController.text);
              if (salary == null || salary <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid salary amount')),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(employeeId)
                  .update({
                'salary': salary,
                'salaryUpdatedAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              onSalaryUpdated();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Salary ${(data['salary'] ?? 0) > 0 ? 'updated' : 'set'} successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'sales':
        return Colors.blue;
      case 'billing':
        return Colors.green;
      case 'delivery':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'sales':
        return Icons.shopping_cart;
      case 'billing':
        return Icons.receipt_long;
      case 'delivery':
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }
}
