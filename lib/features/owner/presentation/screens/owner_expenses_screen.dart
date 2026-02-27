import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:pkv2/shared/widgets/animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rxdart/rxdart.dart';

class OwnerExpensesScreen extends ConsumerStatefulWidget {
  const OwnerExpensesScreen({super.key});

  @override
  ConsumerState<OwnerExpensesScreen> createState() => _OwnerExpensesScreenState();
}

class _OwnerExpensesScreenState extends ConsumerState<OwnerExpensesScreen> {
  String _selectedPeriod = 'current_month';
  DateTime _selectedMonth = DateTime.now();
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showContent = true);
    });
  }

  DateTime _getStartDate() {
    return DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  }

  DateTime _getEndDate() {
    return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
  }

  void _onPeriodChanged(String value) {
    setState(() {
      _selectedPeriod = value;
      if (value == 'last_month') {
        _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);
      } else if (value == 'current_month') {
        _selectedMonth = DateTime.now();
      }
    });
  }

  void _onCustomMonthSelected(DateTime date) {
    setState(() => _selectedMonth = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const _ExpensesSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 100),
                    child: _PeriodSelector(
                      selectedPeriod: _selectedPeriod,
                      selectedMonth: _selectedMonth,
                      onPeriodChanged: _onPeriodChanged,
                      onCustomMonthSelected: _onCustomMonthSelected,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 200),
                    child: _ExpenseSummary(
                      startDate: _getStartDate(),
                      endDate: _getEndDate(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 300),
                    child: _SalaryBreakdown(
                      startDate: _getStartDate(),
                      endDate: _getEndDate(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 400),
                    child: _OtherExpensesList(
                      startDate: _getStartDate(),
                      endDate: _getEndDate(),
                    ),
                  ),
                  const SizedBox(height: 140), // bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SlideFadeIn(
            show: _showContent,
            delay: const Duration(milliseconds: 500),
            child: FloatingActionButton.extended(
              heroTag: 'advance_btn',
              onPressed: () => _ExpenseDialogs.showGiveAdvanceDialog(context),
              icon: const Icon(Icons.currency_rupee_rounded),
              label: const Text('Give Advance'),
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SlideFadeIn(
            show: _showContent,
            delay: const Duration(milliseconds: 600),
            child: FloatingActionButton.extended(
              heroTag: 'expense_btn',
              onPressed: () => _ExpenseDialogs.showAddExpenseDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesSliverAppBar extends StatelessWidget {
  const _ExpensesSliverAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade800, Colors.deepPurple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payments_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financials',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, letterSpacing: 1),
                            ),
                            const Text(
                              'Salary & Expenses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print_rounded, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Print preview coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final DateTime selectedMonth;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<DateTime> onCustomMonthSelected;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.selectedMonth,
    required this.onPeriodChanged,
    required this.onCustomMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Period',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPeriod,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      items: const [
                        DropdownMenuItem(value: 'current_month', child: Text('Current Month')),
                        DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                        DropdownMenuItem(value: 'custom', child: Text('Custom Month')),
                      ],
                      onChanged: (value) => onPeriodChanged(value!),
                    ),
                  ),
                ),
              ),
              if (selectedPeriod == 'custom') ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      onCustomMonthSelected(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 20, color: Colors.indigo.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedMonth.month}/${selectedMonth.year}',
                          style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseSummary extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _ExpenseSummary({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        final expenses = snapshot.data!.docs;

        double paidSalaries = 0;
        double otherExpenses = 0;
        
        for (var expense in expenses) {
          final data = expense.data() as Map;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final category = data['category'] ?? '';

          if (category == 'Salary' || category == 'Advance') {
            paidSalaries += amount;
          } else {
            otherExpenses += amount;
          }
        }

        final totalExpenses = paidSalaries + otherExpenses;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Expenses',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalExpenses.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryStat(
                        icon: Icons.groups_rounded,
                        label: 'Payroll (Salaries + Adv)',
                        value: '₹${paidSalaries.toStringAsFixed(0)}',
                        color: Colors.greenAccent.shade400,
                      ),
                      const VerticalDivider(color: Colors.white24, thickness: 1),
                      _buildSummaryStat(
                        icon: Icons.receipt_long_rounded,
                        label: 'Other',
                        value: '₹${otherExpenses.toStringAsFixed(0)}',
                        color: Colors.orangeAccent.shade200,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _SalaryBreakdown extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _SalaryBreakdown({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    // We combine the users stream and the expenses stream using RxDart
    final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    final expensesStream = FirebaseFirestore.instance.collection('expenses')
        .where('category', whereIn: ['Salary', 'Advance'])
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .snapshots();

    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(
        usersStream,
        expensesStream,
        (QuerySnapshot a, QuerySnapshot b) => [a, b],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final usersDocs = snapshot.data![0].docs;
        final salaryExpenses = snapshot.data![1].docs;

        // Aggregate salaries/advances per employee
        final paidSalaries = <String, double>{};
        for (var expense in salaryExpenses) {
          final data = expense.data() as Map;
          final employeeId = data['employeeId'] as String?;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          if (employeeId != null) {
            paidSalaries[employeeId] = (paidSalaries[employeeId] ?? 0) + amount;
          }
        }

        // Map data back to user profiles
        final salaryDisplayList = paidSalaries.entries.map((entry) {
          final empId = entry.key;
          final amount = entry.value;
          Map<String, dynamic> userData = {'name': 'Unknown', 'role': 'N/A'};
          try {
            final userDoc = usersDocs.firstWhere((u) => u.id == empId);
            userData = userDoc.data() as Map<String, dynamic>;
          } catch (_) {}
          
          return {
            'name': userData['name'] ?? 'Unknown',
            'role': userData['role'] ?? 'N/A',
            'amount': amount,
          };
        }).toList();

        salaryDisplayList.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_3_rounded, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Salaries Paid',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${salaryDisplayList.length} Processed',
                    style: TextStyle(color: Colors.indigo.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (salaryDisplayList.isEmpty)
              _EmptyState(message: 'No salaries paid this period', icon: Icons.person_off_rounded)
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: salaryDisplayList.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final data = salaryDisplayList[index];
                    final name = data['name'] as String;
                    final role = data['role'] as String;
                    final amount = data['amount'] as double;
                    final roleColor = _RolesAndCategories.getRoleColor(role);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: roleColor.withValues(alpha: 0.1),
                        child: Icon(_RolesAndCategories.getRoleIcon(role), color: roleColor, size: 20),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ),
                      trailing: Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OtherExpensesList extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _OtherExpensesList({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final rawExpenses = snapshot.data!.docs;
        // Filter out Salary and Advance payments
        final expenses = rawExpenses.where((e) {
          final data = e.data() as Map;
          return data['category'] != 'Salary' && data['category'] != 'Advance';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Other Expenses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${expenses.length} Records',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expenses.isEmpty)
              _EmptyState(message: 'No expenses recorded', icon: Icons.receipt_rounded)
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final data = expense.data() as Map;
                    final title = data['title'] ?? 'Unnamed Expense';
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    final category = data['category'] ?? 'General';
                    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final catColor = _RolesAndCategories.getCategoryColor(category);

                    return Dismissible(
                      key: Key(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(index == expenses.length - 1 ? 20 : 0),
                        ),
                        child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade700),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Expense'),
                            content: const Text('Are you sure you want to delete this specific expense record?'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        FirebaseFirestore.instance.collection('expenses').doc(expense.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_RolesAndCategories.getCategoryIcon(category), color: catColor, size: 22),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              Text(
                                '${date.day}/${date.month}/${date.year}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        trailing: Text(
                          '- ₹${amount.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ExpenseDialogs {
  static void showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'General';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Expense', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Expense Title',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                InkWell(
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date', style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
                        Row(
                          children: [
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.indigo),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
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

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense added successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  static void showGiveAdvanceDialog(BuildContext context) {
    String? selectedEmployeeId;
    String? selectedEmployeeName;
    String? selectedEmployeeUpi;
    String? selectedEmployeePhone;
    final amountController = TextEditingController();
    bool payViaGPay = false;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Give Advance Salary', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final users = snapshot.data!.docs.where((d) => (d.data() as Map)['role'] != 'OWNER').toList();
                    return DropdownButtonFormField<String>(
                      initialValue: selectedEmployeeId,
                      decoration: InputDecoration(
                        labelText: 'Select Employee',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: users.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedEmployeeId = value;
                          final selectedDoc = users.firstWhere((doc) => doc.id == value);
                          final data = selectedDoc.data() as Map<String, dynamic>;
                          selectedEmployeeName = data['name'];
                          selectedEmployeeUpi = data['upiId']?.toString().isNotEmpty == true ? data['upiId'] : null;
                          selectedEmployeePhone = data['phone'];
                        });
                      },
                    );
                  }
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Advance Amount',
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                InkWell(
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date', style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
                        Row(
                          children: [
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.indigo),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Pay via Google Pay / UPI', style: TextStyle(fontSize: 14)),
                  value: payViaGPay,
                  activeThumbColor: Colors.teal.shade600,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => payViaGPay = val),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmployeeId == null || amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an employee and enter an amount')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;

                if (payViaGPay) {
                   String upiId = selectedEmployeeUpi ?? selectedEmployeePhone ?? '';
                   if (upiId.isNotEmpty) {
                     if (!upiId.contains('@')) upiId = '$upiId@okicici';
                     final note = Uri.encodeComponent('Advance Salary to $selectedEmployeeName');
                     final url = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(selectedEmployeeName ?? '')}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$note';
                     final uri = Uri.parse(url);
                     
                     try {
                       final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                       if (!launched) {
                         throw Exception('Could not launch UPI app.');
                       }
                     } catch (e) {
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Could not find a UPI app (like GPay) on your phone!')),
                         );
                       }
                     }
                   } else {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Employee does not have a valid Phone Number or UPI ID for GPay.')),
                       );
                     }
                     return;
                   }
                }

                await FirebaseFirestore.instance.collection('expenses').add({
                  'title': 'Advance Salary - $selectedEmployeeName',
                  'amount': amount,
                  'category': 'Advance', // Ensure it uses 'Advance' category for later calculation
                  'employeeId': selectedEmployeeId,
                  'date': Timestamp.fromDate(selectedDate),
                  'description': 'Advance payments will be deducted from next salary payout.',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Advance recorded successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: payViaGPay ? Colors.teal.shade600 : Colors.indigo.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(payViaGPay ? 'Pay & Record Advance' : 'Record Advance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolesAndCategories {
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red.shade600;
      case 'sales': return Colors.blue.shade600;
      case 'billing': return Colors.green.shade600;
      case 'delivery': return Colors.orange.shade600;
      default: return Colors.grey.shade600;
    }
  }

  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'sales': return Icons.shopping_bag_rounded;
      case 'billing': return Icons.receipt_rounded;
      case 'delivery': return Icons.local_shipping_rounded;
      default: return Icons.person_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'rent': return Colors.purple.shade600;
      case 'utilities': return Colors.blue.shade600;
      case 'transport': return Colors.orange.shade600;
      case 'maintenance': return Colors.red.shade600;
      case 'office supplies': return Colors.teal.shade600;
      case 'marketing': return Colors.pink.shade600;
      default: return Colors.blueGrey.shade600;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent': return Icons.holiday_village_rounded;
      case 'utilities': return Icons.electric_bolt_rounded;
      case 'transport': return Icons.directions_bus_rounded;
      case 'maintenance': return Icons.handyman_rounded;
      case 'office supplies': return Icons.inventory_2_rounded;
      case 'marketing': return Icons.campaign_rounded;
      default: return Icons.receipt_rounded;
    }
  }
}
