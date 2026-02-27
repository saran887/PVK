import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pkv2/shared/widgets/animations.dart';

class OwnerSalaryScreen extends ConsumerStatefulWidget {
  const OwnerSalaryScreen({super.key});

  @override
  ConsumerState<OwnerSalaryScreen> createState() => _OwnerSalaryScreenState();
}

class _OwnerSalaryScreenState extends ConsumerState<OwnerSalaryScreen> {
  String _searchQuery = '';
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 100),
                    child: _buildSalarySummary(),
                  ),
                  const SizedBox(height: 24),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 200),
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(height: 24),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 300),
                    child: const Text(
                      'Team Members',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SlideFadeIn(
                    show: _showContent,
                    delay: const Duration(milliseconds: 400),
                    child: _buildEmployeeList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SlideFadeIn(
        show: _showContent,
        delay: const Duration(milliseconds: 500),
        child: FloatingActionButton.extended(
          onPressed: () => GoRouter.of(context).push('/admin/add-person'),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add Employee'),
          backgroundColor: Colors.teal.shade500,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade900],
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
                        child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Human Resources',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, letterSpacing: 1),
                            ),
                            const Text(
                              'Salary Management',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildSalarySummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade800, Colors.black87],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Monthly Payroll',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalSalaries.toStringAsFixed(0)}',
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryStat(
                      icon: Icons.groups_rounded,
                      label: 'Total Staff',
                      value: '${users.length}',
                      color: Colors.blueAccent.shade100,
                    ),
                    const SizedBox(height: 40, child: VerticalDivider(color: Colors.white24, thickness: 1)),
                    _buildSummaryStat(
                      icon: Icons.check_circle_rounded,
                      label: 'With Salary',
                      value: '$employeesWithSalary',
                      color: Colors.greenAccent.shade400,
                    ),
                    const SizedBox(height: 40, child: VerticalDivider(color: Colors.white24, thickness: 1)),
                    _buildSummaryStat(
                      icon: Icons.warning_amber_rounded,
                      label: 'Pending',
                      value: '$employeesWithoutSalary',
                      color: employeesWithoutSalary > 0 ? Colors.orangeAccent.shade200 : Colors.white54,
                    ),
                  ],
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
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search by employee name...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, 1)))
              .snapshots(),
          builder: (context, expenseSnapshot) {
            if (!expenseSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            final allExpenses = expenseSnapshot.data!.docs.map((e) => e.data() as Map<String, dynamic>).toList();

            var employees = userSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final role = data['role'] ?? '';
              final isActive = data['isActive'] ?? true;

              final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
              final isNotOwner = role != 'owner';

              return matchesSearch && isNotOwner && isActive;
            }).toList();

            employees.sort((a, b) {
              final salaryA = ((a.data() as Map)['salary'] as num?)?.toDouble() ?? 0;
              final salaryB = ((b.data() as Map)['salary'] as num?)?.toDouble() ?? 0;
              
              if (salaryA == 0 && salaryB > 0) return -1;
              if (salaryB == 0 && salaryA > 0) return 1;
              return salaryB.compareTo(salaryA);
            });

            if (employees.isEmpty) {
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
                    Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No employees found matching search', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                final data = employee.data() as Map<String, dynamic>;
                
                final employeeExpenses = allExpenses.where((e) => e['employeeId'] == employee.id).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EmployeeCard(
                    employeeId: employee.id,
                    data: data,
                    monthlyExpenses: employeeExpenses,
                    onSalaryUpdated: () => setState(() {}),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final String employeeId;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> monthlyExpenses;
  final VoidCallback onSalaryUpdated;

  const _EmployeeCard({
    required this.employeeId,
    required this.data,
    required this.monthlyExpenses,
    required this.onSalaryUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final role = data['role'] ?? 'N/A';
    final salary = (data['salary'] as num?)?.toDouble() ?? 0;
    final employeeCode = data['code'] ?? data['employeeId'] ?? '';
    final hasSalary = salary > 0;
    final roleColor = _getRoleColor(role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasSalary ? Colors.grey.shade100 : Colors.orange.shade200,
          width: hasSalary ? 1 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showSalaryDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor.withValues(alpha: 0.1),
                  child: Icon(_getRoleIcon(role), color: roleColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!hasSalary)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_rounded, size: 12, color: Colors.orange.shade800),
                                  const SizedBox(width: 4),
                                  Text('Unset', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            role.toUpperCase(),
                            style: TextStyle(fontSize: 11, color: roleColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          if (employeeCode.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Text('â€¢', style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text(employeeCode, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasSalary) ...[
                      const Text('Salary', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Row(
                        children: [
                          Text(
                            '₹${salary.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit_rounded, color: Colors.grey.shade400, size: 14),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          bool isPaid = false;
                          double totalAdvances = 0;
                          for (var exp in monthlyExpenses) {
                            if (exp['category'] == 'Salary') isPaid = true;
                            if (exp['category'] == 'Advance') totalAdvances += (exp['amount'] as num?)?.toDouble() ?? 0;
                          }
                          
                          double netSalary = salary - totalAdvances;
                          if (netSalary < 0) netSalary = 0;

                          if (isPaid) {
                            return Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              alignment: Alignment.center,
                              child: const Text('Paid This Month', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                            );
                          }

                          return SizedBox(
                            height: 28,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showPaymentDialog(context, name, salary, totalAdvances, netSalary);
                              },
                              icon: const Icon(Icons.payments_rounded, size: 14),
                              label: const Text('Pay', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          );
                        }
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => _showSalaryDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String employeeName, double baseSalary, double totalAdvances, double netSalary) {
    // Default to the saved UPI ID, or fallback to the employee's phone number
    final String initialUpiOrPhone = (data['upiId'] != null && data['upiId'].toString().isNotEmpty)
        ? data['upiId']
        : (data['phone'] ?? '');

    final upiController = TextEditingController(text: initialUpiOrPhone);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.payments_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (totalAdvances > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Base Salary:'), Text('₹${baseSalary.toStringAsFixed(0)}')]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Advances (This Month):', style: TextStyle(color: Colors.deepOrange)), Text('- ₹${totalAdvances.toStringAsFixed(0)}', style: const TextStyle(color: Colors.deepOrange))]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Net Payable:', style: TextStyle(fontWeight: FontWeight.bold)), Text('₹${netSalary.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text('Record payment of ₹${netSalary.toStringAsFixed(0)} to $employeeName?'),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: upiController,
                decoration: InputDecoration(
                  labelText: 'Phone Number or UPI ID',
                  hintText: 'e.g., 9876543210 or name@upi',
                  prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              const Text(
                'Payment will be recorded under the "Salary" category.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
          actions: [
            TextButton(
               onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                String upiId = upiController.text.trim();
                
                try {
                  // Save the entered info as the preferred UPI ID so it persists natively
                  if (upiId.isNotEmpty && upiId != (data['upiId'] ?? '')) {
                     await FirebaseFirestore.instance.collection('users').doc(employeeId).update({'upiId': upiId});
                  }

                  // Launch UPI App if an identifier is provided
                  if (upiId.isNotEmpty) {
                    // If the user just left the phone number (no @ symbol), we assume GPay default handler
                    if (!upiId.contains('@')) {
                      upiId = '$upiId@okicici'; // A common default for GPay number resolution
                    }

                    final note = Uri.encodeComponent('Salary payment to $employeeName');
                    // tez:// is the specific app link for Google Pay, though upi:// is universal
                    final url = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(employeeName)}&am=${netSalary.toStringAsFixed(2)}&cu=INR&tn=$note';
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
                  }

                  // Record the expense
                  await FirebaseFirestore.instance.collection('expenses').add({
                    'amount': netSalary,
                    'category': 'Salary',
                    'description': 'Salary payment - $employeeName (Base: $baseSalary, Deducted Advances: $totalAdvances)',
                    'date': Timestamp.now(),
                    'employeeId': employeeId, 
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Paid ₹${netSalary.toStringAsFixed(0)} to $employeeName'),
                        backgroundColor: Colors.teal.shade600,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Pay via UPI & Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSalaryDialog(BuildContext context) {
    final salaryController = TextEditingController(
      text: (data['salary'] ?? 0) > 0 ? (data['salary'] ?? 0).toString() : '',
    );
    final hasExistingSalary = (data['salary'] ?? 0) > 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${hasExistingSalary ? 'Update' : 'Set'} Salary Base', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getRoleColor(data['role'] ?? '').withValues(alpha: 0.1),
                  child: Icon(_getRoleIcon(data['role'] ?? ''), color: _getRoleColor(data['role'] ?? ''), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        (data['role'] ?? 'N/A').toUpperCase(),
                        style: TextStyle(fontSize: 11, color: _getRoleColor(data['role'] ?? ''), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: salaryController,
              decoration: InputDecoration(
                labelText: 'Base Monthly Rate',
                prefixText: '₹ ',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                helperText: 'Enter the defined monthly salary amount',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
        actions: [
          if (hasExistingSalary)
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(employeeId).update({'salary': 0});
                if (context.mounted) {
                  Navigator.pop(context);
                  onSalaryUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary base removed')));
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove Base'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
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

              await FirebaseFirestore.instance.collection('users').doc(employeeId).update({
                'salary': salary,
                'salaryUpdatedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                onSalaryUpdated();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Salary base ${hasExistingSalary ? 'updated' : 'set'} successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save Base'),
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
      default: return Colors.blueGrey.shade600;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'sales': return Icons.shopping_bag_rounded;
      case 'billing': return Icons.receipt_long_rounded;
      case 'delivery': return Icons.local_shipping_rounded;
      default: return Icons.person_rounded;
    }
  }
}
