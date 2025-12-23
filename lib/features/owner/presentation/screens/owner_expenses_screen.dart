import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class OwnerExpensesScreen extends ConsumerStatefulWidget {
  const OwnerExpensesScreen({super.key});

  @override
  ConsumerState<OwnerExpensesScreen> createState() => _OwnerExpensesScreenState();
}

class _OwnerExpensesScreenState extends ConsumerState<OwnerExpensesScreen> {
  String _selectedPeriod = 'current_month';
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary & Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExpenseDialog(),
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildExpenseSummary(),
            const SizedBox(height: 24),
            _buildSalaryBreakdown(),
            const SizedBox(height: 24),
            _buildOtherExpenses(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'current_month', child: Text('Current Month')),
                      DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom Month')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                        if (value == 'last_month') {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                        } else if (value == 'current_month') {
                          _selectedMonth = DateTime.now();
                        }
                      });
                    },
                  ),
                ),
                if (_selectedPeriod == 'custom') ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text('${_selectedMonth.month}/${_selectedMonth.year}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedMonth = picked);
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSummary() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _combineStreams([
        FirebaseFirestore.instance.collection('users').snapshots(),
        FirebaseFirestore.instance.collection('expenses')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartDate()))
            .where('date', isLessThan: Timestamp.fromDate(_getEndDate()))
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
        }

        final users = snapshot.data![0].docs;
        final expenses = snapshot.data![1].docs;

        // Calculate total salaries
        double totalSalaries = 0;
        int activeEmployees = 0;
        for (var user in users) {
          final data = user.data() as Map;
          final isActive = data['isActive'] ?? true;
          if (isActive && data['role'] != 'owner') {
            final salary = (data['salary'] as num?)?.toDouble() ?? 0;
            totalSalaries += salary;
            activeEmployees++;
          }
        }

        // Calculate other expenses
        double otherExpenses = 0;
        for (var expense in expenses) {
          final data = expense.data() as Map;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          otherExpenses += amount;
        }

        final totalExpenses = totalSalaries + otherExpenses;

        return Card(
          elevation: 3,
          color: Colors.blue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet, size: 48, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  'Total Expenses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${totalExpenses.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ExpenseItem(
                      icon: Icons.people,
                      label: 'Salaries',
                      value: '₹${totalSalaries.toStringAsFixed(0)}',
                      subtitle: '$activeEmployees employees',
                      color: Colors.green,
                    ),
                    Container(width: 1, height: 50, color: Colors.grey[300]),
                    _ExpenseItem(
                      icon: Icons.receipt_long,
                      label: 'Other',
                      value: '₹${otherExpenses.toStringAsFixed(0)}',
                      subtitle: '${expenses.length} items',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalaryBreakdown() {
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

        // Sort by salary (highest first)
        users.sort((a, b) {
          final salaryA = ((a.data() as Map)['salary'] as num?)?.toDouble() ?? 0;
          final salaryB = ((b.data() as Map)['salary'] as num?)?.toDouble() ?? 0;
          return salaryB.compareTo(salaryA);
        });

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Employee Salaries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${users.length} employees', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No active employees found')),
                  )
                else
                  ...users.map((user) {
                    final data = user.data() as Map;
                    final name = data['name'] ?? 'Unknown';
                    final role = data['role'] ?? 'N/A';
                    final salary = (data['salary'] as num?)?.toDouble() ?? 0;
                    final employeeId = data['employeeId'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getRoleColor(role).withOpacity(0.1),
                            child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    Text(role.toUpperCase(), style: TextStyle(fontSize: 11, color: _getRoleColor(role))),
                                    if (employeeId.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text('• $employeeId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${salary.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtherExpenses() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartDate()))
          .where('date', isLessThan: Timestamp.fromDate(_getEndDate()))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
        }

        final expenses = snapshot.data!.docs;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text('Other Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${expenses.length} items', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No expenses recorded for this period')),
                  )
                else
                  ...expenses.map((expense) {
                    final data = expense.data() as Map;
                    final title = data['title'] ?? 'Unnamed Expense';
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    final category = data['category'] ?? 'General';
                    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final description = data['description'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  category,
                                  style: TextStyle(fontSize: 11, color: _getCategoryColor(category)),
                                ),
                                if (description.isNotEmpty)
                                  Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _deleteExpense(expense.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'General';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                    DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                    DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(value: 'Office Supplies', child: Text('Office Supplies')),
                    DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('expenses').add({
                  'title': titleController.text,
                  'amount': double.parse(amountController.text),
                  'category': selectedCategory,
                  'date': Timestamp.fromDate(selectedDate),
                  'description': descriptionController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense added successfully')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('expenses').doc(expenseId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }
  }

  DateTime _getStartDate() {
    return DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  }

  DateTime _getEndDate() {
    return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'rent': return Colors.purple;
      case 'utilities': return Colors.blue;
      case 'transport': return Colors.orange;
      case 'maintenance': return Colors.red;
      case 'office supplies': return Colors.teal;
      case 'marketing': return Colors.pink;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent': return Icons.home;
      case 'utilities': return Icons.bolt;
      case 'transport': return Icons.directions_car;
      case 'maintenance': return Icons.build;
      case 'office supplies': return Icons.inventory_2;
      case 'marketing': return Icons.campaign;
      default: return Icons.receipt;
    }
  }

  Stream<List<QuerySnapshot>> _combineStreams(List<Stream<QuerySnapshot>> streams) {
    return Stream.periodic(const Duration(milliseconds: 500))
        .asyncMap((_) => Future.wait(streams.map((s) => s.first)));
  }
}

class _ExpenseItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _ExpenseItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
