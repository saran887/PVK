import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import '../../../../core/config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/enums/app_enums.dart';
import '../../../../shared/widgets/animations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  // OTP related
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _isOtpSent = false;
  String? _reqId; // Added for MSG91 OTP
  UserModel? _pendingUser;

  // Animation state variables
  bool _showContent = false; // Controls entrance animation
  bool _shakeOtp = false; // Triggers shake on wrong OTP
  bool _showSuccess = false; // Shows success checkmark

  bool _isLoading = false;
  bool _showDemoCodes = false;

  @override
  void initState() {
    super.initState();
    // Initialize MSG91 OTP Widget
    OTPWidget.initializeWidget(AppConfig.msg91WidgetCode, AppConfig.msg91AuthToken);
    
    // Trigger entrance animation after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();
  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

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
          color: Colors.black, // Solid black
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
          if (_enteredCode.length == 4 && !_isOtpSent) {
            _handleLogin();
          }
        },
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    
    return SizedBox(
      width: 65,
      height: 65,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        obscureText: false,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Solid black for best visibility
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: hasValue ? Colors.green.shade50 : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasValue ? Colors.green.shade200 : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.green, width: 2.5),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty && index < 3) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          if (_enteredOtp.length == 4) {
            _verifyOtp();
          }
        },
      ),
    );
  }

  Future<void> _sendOtp(UserModel user) async {
    final phoneNumber = user.phone.trim();
    if (phoneNumber.isEmpty) {
      _showMessage('No registered phone number found for this account', isError: true);
      return;
    }

    // MSG91 requires country code without '+' (e.g. 91)
    String countryCode = '91';
    
    setState(() {
      _isLoading = true;
      _pendingUser = user;
    });
    
    try {
      // Send OTP using MSG91 SDK
      final response = await OTPWidget.sendOTP({
        'identifier': '$countryCode$phoneNumber'
      });
      
      if (response != null && response['type'] == 'success') {
        setState(() {
          _reqId = response['message']; // Store reqId
          _isOtpSent = true;
          _isLoading = false;
        });
        _showMessage('OTP sent to registered number ending in ${phoneNumber.substring(phoneNumber.length - 3)}', isError: false);
        _otpFocusNodes[0].requestFocus();
      } else {
        throw Exception(response?['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      debugPrint('âŒ Error sending OTP: $e');
      _showMessage('Failed to send OTP. Try again.', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length < 4) return;
    if (_reqId == null) {
      _showMessage('Session expired. Resend OTP.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Verify OTP using MSG91 SDK
      final response = await OTPWidget.verifyOTP({
        'reqId': _reqId!,
        'otp': _enteredOtp,
      });
      
      if (response != null && response['type'] == 'success') {
        // Show success animation before proceeding
        setState(() => _showSuccess = true);
        await Future.delayed(const Duration(milliseconds: 800));
        // If verification succeeds, proceed to handle final login
        await _signInAfterVerification();
      } else {
        // Trigger shake animation on wrong OTP
        setState(() => _shakeOtp = true);
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() => _shakeOtp = false);
        _showMessage(response?['message'] ?? 'Invalid OTP', isError: true);
        _clearOtp();
      }
    } catch (e) {
      debugPrint('âŒ OTP verification error: $e');
      // Trigger shake animation on error
      setState(() => _shakeOtp = true);
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _shakeOtp = false);
      _showMessage('Invalid OTP. Please try again.', isError: true);
      _clearOtp();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAfterVerification() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      // Now use the original access code to sign in with email/password 
      // This ensures we get all the user metadata/role etc.
      await authRepo.signInWithCode(_enteredCode);
      if (mounted) {
        _showMessage('Login Successful!', isError: false);
      }
    } catch (e) {
      debugPrint('âŒ Final sign-in error: $e');
      if (mounted) _showMessage('Authentication failed: $e', isError: true);
      _clearCode();
    }
  }

  void _clearOtp() {
    for (var c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
    setState(() {});
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
      debugPrint('ðŸ” Looking for code: $code');

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
      debugPrint('âœ… Found user: ${userData['name']} (${userData['role']})');

      final user = UserModel.fromFirestore(userData, id: userDoc.id);
      
      // Special check for Owner and Admin - Send OTP automatically
      if (user.code == '1000' || user.code == '1111' || user.role == UserRole.owner || user.role == UserRole.admin) {
        debugPrint('ðŸ” Role-based security triggered for: ${user.role}');
        await _sendOtp(user);
      } else {
        // Direct login for other roles
        await authRepo.signInWithCode(code);
        if (mounted) {
          _showMessage('Welcome, ${user.name}!', isError: false);
        }
      }
    } catch (e) {
      debugPrint('âŒ Error signing in: $e');
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
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _isOtpSent = false;
    _reqId = null;
    _pendingUser = null;
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
                // App Logo/Icon with fade + scale entrance animation
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedScale(
                    scale: _showContent ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 150,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title with slide + fade animation
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedSlide(
                    offset: _showContent ? Offset.zero : const Offset(0, 0.2),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    child: Text(
                      'PVK Agency',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle with delayed slide animation
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedSlide(
                    offset: _showContent ? Offset.zero : const Offset(0, 0.2),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    child: Text(
                      'Enter your 4-digit access code',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Code Input Boxes with fade animation
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 4; i++) ...[
                        _buildCodeBox(i),
                        if (i < 3) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),

                // OTP Section with slide-in animation
                if (_isOtpSent) ...[
                  const SizedBox(height: 32),
                  // Success checkmark animation (shows after verification)
                  if (_showSuccess)
                    AnimatedCheckmark(
                      size: 80,
                      color: Colors.green,
                      show: _showSuccess,
                    )
                  else ...[
                    // OTP Title slides in
                    AnimatedSlide(
                      offset: _isOtpSent ? Offset.zero : const Offset(0, 0.5),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _isOtpSent ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Text(
                          'Enter 4-digit OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_pendingUser != null)
                      AnimatedOpacity(
                        opacity: _isOtpSent ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          'Sent to: ******${_pendingUser!.phone.substring(_pendingUser!.phone.length - 3)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // OTP boxes with shake animation for wrong OTP
                    SimpleShake(
                      trigger: _shakeOtp,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 4; i++) ...[
                              _buildOtpBox(i),
                              if (i < 3) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 32),
                
                // Sign In Button with scale press animation
                if (!_isOtpSent && _pendingUser == null)
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLoading
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            child: const CircularProgressIndicator(),
                          )
                        : AnimatedPressButton(
                            onPressed: _enteredCode.length == 4 ? _handleLogin : null,
                            child: SizedBox(
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
                  ),
                ),

                // Verify OTP Button with scale press animation
                if (_isOtpSent && !_showSuccess)
                AnimatedOpacity(
                  opacity: _isOtpSent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedPressButton(
                    onPressed: _isLoading || _enteredOtp.length < 4 ? null : _verifyOtp,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || _enteredOtp.length < 4 ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify & Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: color.withValues(alpha: 0.9),
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
