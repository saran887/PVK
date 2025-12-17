import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';
import '../../../../shared/enums/app_enums.dart';

class AddPersonScreen extends ConsumerStatefulWidget {
  final String? userId;
  final bool isEdit;
  
  const AddPersonScreen({super.key, this.userId, this.isEdit = false});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  UserRole _selectedRole = UserRole.sales;
  bool _isLoading = false;
  String? _selectedLocationId;
  String? _selectedLocationName;
  List<Map<String, dynamic>> _locations = [];

  @override
  void initState() {
    super.initState();
    if (!widget.isEdit) {
      _generateCode();
    }
    _loadLocations();
    if (widget.isEdit && widget.userId != null) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _generateCode() {
    final random = Random();
    final code = (1000 + random.nextInt(9000)).toString();
    _codeController.text = code;
  }

  Future<void> _loadLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .orderBy('name')
          .get();
      
      setState(() {
        _locations = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _codeController.text = data['code']?.toString() ?? '';
          _selectedRole = UserRole.fromString(data['role'] ?? 'SALES');
          _selectedLocationId = data['locationId'] as String?;
          _selectedLocationName = data['locationName'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isEdit) {
        // Update existing user
        final updateData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'code': _codeController.text,
          'role': _selectedRole.name.toUpperCase(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Only add location for sales and delivery roles
        if (_selectedRole == UserRole.sales || _selectedRole == UserRole.delivery) {
          updateData['locationId'] = _selectedLocationId ?? '';
          updateData['locationName'] = _selectedLocationName ?? '';
        } else {
          updateData['locationId'] = '';
          updateData['locationName'] = '';
        }
        
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new user
        final random = Random();
        final randomEmail = 'user${DateTime.now().millisecondsSinceEpoch}@pkv.local';
        final randomPassword = 'pwd${random.nextInt(999999).toString().padLeft(6, '0')}';

        final primaryApp = Firebase.app();
        final secondaryApp = await Firebase.initializeApp(
          name: 'temp-admin-${DateTime.now().microsecondsSinceEpoch}',
          options: primaryApp.options,
        );

        UserCredential userCredential;
        try {
          final tempAuth = FirebaseAuth.instanceFor(app: secondaryApp);
          userCredential = await tempAuth.createUserWithEmailAndPassword(
            email: randomEmail,
            password: randomPassword,
          );
          await tempAuth.signOut();
        } finally {
          await secondaryApp.delete();
        }

        final userData = {
          'name': _nameController.text.trim(),
          'email': randomEmail,
          'phone': _phoneController.text.trim(),
          'code': _codeController.text,
          'role': _selectedRole.name.toUpperCase(),
          'password': randomPassword,
          'isActive': true,
          'assignedRoutes': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Only add location for sales and delivery roles
        if (_selectedRole == UserRole.sales || _selectedRole == UserRole.delivery) {
          userData['locationId'] = _selectedLocationId ?? '';
          userData['locationName'] = _selectedLocationName ?? '';
        } else {
          userData['locationId'] = '';
          userData['locationName'] = '';
        }
        
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User added! Login code: ${_codeController.text}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Person' : 'Add New Person'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Login Code',
                      prefixIcon: Icon(Icons.code),
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Generate New Code',
                  iconSize: 32,
                  onPressed: _generateCode,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
              items: UserRole.values
                  .where((role) => role != UserRole.admin && role != UserRole.owner)
                  .map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            // Show location dropdown only for sales and delivery roles
            if (_selectedRole == UserRole.sales || _selectedRole == UserRole.delivery) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocationId,
                decoration: const InputDecoration(
                  labelText: 'Assign Location',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Select a location',
                ),
                items: _locations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location['id'] as String,
                    child: Text(location['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocationId = value;
                    _selectedLocationName = _locations.firstWhere(
                      (loc) => loc['id'] == value,
                      orElse: () => {'name': ''},
                    )['name'] as String?;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a location';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createUser,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEdit ? 'Save Changes' : 'Add Person'),
            ),
          ],
        ),
      ),
    );
  }
}
