import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _showDemoCodes = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  Widget _buildCodeBox(int index) {
    final hasValue = _controllers[index].text.isNotEmpty;
    
    return SizedBox(
      width: 65,
      height: 65,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasValue ? Colors.blue.shade50 : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasValue ? Colors.blue.shade200 : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2.5),
          ),
        ),
        onChanged: (value) {
          setState(() {}); // Rebuild to update colors
          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto-submit when all 4 digits are entered
          if (_enteredCode.length == 4) {
            _handleLogin();
          }
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    final code = _enteredCode;
    if (code.length != 4) {
      _showMessage('Please enter a 4-digit code', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      debugPrint('🔍 Looking for code: $code');

      // Try finding user with code as string first, then as number
      QuerySnapshot usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        final codeNum = int.tryParse(code);
        if (codeNum != null) {
          usersQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('code', isEqualTo: codeNum)
              .limit(1)
              .get();
        }
      }

      if (usersQuery.docs.isEmpty) {
        throw Exception('Invalid code. Please try again.');
      }

      final userDoc = usersQuery.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;
      debugPrint('✅ Found user: ${userData['name']} (${userData['role']})');

      await authRepo.signInWithCode(code);
      debugPrint('✅ Successfully signed in');

      if (mounted) {
        _showMessage('Welcome, ${userData['name']}!', isError: false);
      }
    } catch (e) {
      debugPrint('❌ Error signing in: $e');
      if (mounted) {
        _showMessage('Invalid code. Please try again.', isError: true);
        _clearCode();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  void _fillDemoCode(String code) {
    for (int i = 0; i < 4 && i < code.length; i++) {
      _controllers[i].text = code[i];
    }
    setState(() {});
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outlined,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Distribution Management',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your 4-digit access code',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Code Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 4; i++) ...[
                      _buildCodeBox(i),
                      if (i < 3) const SizedBox(width: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
                
                // Sign In Button or Loading
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isLoading
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          child: const CircularProgressIndicator(),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _enteredCode.length == 4 ? _handleLogin : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                ),
                
                // Clear Button
                if (_enteredCode.isNotEmpty && !_isLoading) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _clearCode,
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Demo Codes Section (Collapsible)
                _buildDemoCodesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCodesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showDemoCodes = !_showDemoCodes),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demo Login Codes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showDemoCodes ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildDemoCodeTile('1000', 'OWNER', Colors.purple),
                  _buildDemoCodeTile('1111', 'ADMIN', Colors.indigo),
                  _buildDemoCodeTile('9168', 'SALES', Colors.green),
                  _buildDemoCodeTile('1854', 'BILLING', Colors.orange),
                  _buildDemoCodeTile('7293', 'DELIVERY', Colors.blue),
                ],
              ),
            ),
            crossFadeState: _showDemoCodes
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCodeTile(String code, String role, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _fillDemoCode(code),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  role,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
