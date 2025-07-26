import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';
import '../../models/user_model.dart';

class AddAdminScreen extends StatefulWidget {
  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  
  bool _isLoading = false;
  List<String> _selectedPermissions = ['scan_attendance', 'create_session'];
  
  final List<Map<String, dynamic>> _availablePermissions = [
    {'key': 'scan_attendance', 'label': 'Scan Attendance', 'description': 'Allow scanning QR codes for attendance'},
    {'key': 'create_session', 'label': 'Create Sessions', 'description': 'Allow creating new attendance sessions'},
    {'key': 'view_reports', 'label': 'View Reports', 'description': 'Access attendance reports and analytics'},
    {'key': 'export_data', 'label': 'Export Data', 'description': 'Export attendance data to files'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _addAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String adminEmail = _emailController.text.trim();
      firebase_auth.UserCredential? result;

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // ✅ FIX 1: Ensure Super Admin is authenticated
        if (authProvider.user == null) {
          throw Exception('Super admin not authenticated');
        }

        // ✅ Get the correct Super Admin UID
        String superAdminUid = authProvider.user!.uid;
        print('🔥 DEBUG: Super Admin UID: $superAdminUid');
        print('🔥 DEBUG: Super Admin Email: ${authProvider.user!.email}');
        print('🔥 DEBUG: Creating admin for email: $adminEmail');

        // Check if email already exists
        try {
          List<String> methods = await firebase_auth.FirebaseAuth.instance
              .fetchSignInMethodsForEmail(adminEmail);
          if (methods.isNotEmpty) {
            throw Exception('An account with email $adminEmail already exists');
          }
        } catch (e) {
          if (e.toString().contains('already exists')) {
            rethrow;
          }
          // Continue if it's just a network error
          print('🔥 DEBUG: Could not check existing email, continuing...');
        }

        // STEP 1: Create Firebase Authentication User
        print('🔥 STEP 1: Creating Firebase Auth user...');
        result = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: adminEmail,
          password: 'AdminTemp123!', // Strong temporary password
        );

        if (result.user == null) {
          throw Exception('Failed to create Firebase Auth user');
        }

        print('✅ SUCCESS: Firebase Auth user created!');
        print('   - New Admin UID: ${result.user!.uid}');
        print('   - New Admin Email: ${result.user!.email}');

        // STEP 2: Create Firestore Document with CORRECT assignedBy
        print('🔥 STEP 2: Creating Firestore document...');
        
        UserModel adminUser = UserModel(
          id: result.user!.uid,
          email: adminEmail,
          role: Constants.ADMIN,
          displayName: _displayNameController.text.trim().isEmpty 
              ? null 
              : _displayNameController.text.trim(),
          createdAt: DateTime.now(),
          isActive: true,
          assignedBy: superAdminUid, // ✅ FIX: Use correct Super Admin UID
        );

        await FirebaseFirestore.instance
            .collection(Constants.USERS_COLLECTION)
            .doc(result.user!.uid)
            .set(adminUser.toFirestore());

        print('✅ SUCCESS: Firestore document created!');
        print('   - Document ID: ${result.user!.uid}');
        print('   - AssignedBy: $superAdminUid'); // ✅ This should show correct UID

        // STEP 3: Send Password Reset Email with Enhanced Error Handling
        print('🔥 STEP 3: Sending password reset email...');
        
        try {
          await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
            email: adminEmail,
          );
          print('✅ SUCCESS: Password reset email sent to $adminEmail');
        } catch (emailError) {
          print('❌ EMAIL ERROR: $emailError');
          
          // Don't fail the entire process if email fails
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Email Warning'),
                  ],
                ),
                content: Text(
                  'Admin user was created successfully but the password reset email failed to send.\n\n'
                  'You can manually send the password reset email from Firebase Console:\n'
                  '• Go to Authentication → Users\n'
                  '• Find the user: $adminEmail\n'
                  '• Click the menu and select "Reset Password"'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
        }

        // Show success message
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Admin created successfully!\n'
                '👤 Admin: $adminEmail\n'
                '📧 Password reset email sent (check spam folder)\n'
                '🔗 AssignedBy: $superAdminUid'
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 6),
            ),
          );
        }

      } on firebase_auth.FirebaseAuthException catch (e) {
        print('❌ FirebaseAuthException: ${e.code}');
        print('❌ Message: ${e.message}');
        
        String userMessage;
        switch (e.code) {
          case 'email-already-in-use':
            userMessage = '❌ Email $adminEmail is already registered. Use a different email.';
            break;
          case 'invalid-email':
            userMessage = '❌ Invalid email format: $adminEmail';
            break;
          case 'weak-password':
            userMessage = '❌ Password is too weak (this shouldn\'t happen with our temp password)';
            break;
          case 'network-request-failed':
            userMessage = '❌ Network error. Check your internet connection and try again.';
            break;
          case 'too-many-requests':
            userMessage = '❌ Too many requests. Please wait a few minutes and try again.';
            break;
          default:
            userMessage = '❌ Authentication failed: ${e.message}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        print('❌ GENERAL ERROR: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to create admin: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Admin'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Debug info for Super Admin
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔍 Debug Info',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Super Admin UID: ${authProvider.user?.uid ?? 'Not loaded'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            'Super Admin Email: ${authProvider.user?.email ?? 'Not loaded'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 16),
              
              // Header
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Admin User',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Creates Firebase Auth user + Firestore document',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Email field
              CustomTextField(
                label: 'Admin Email Address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                validator: Validators.validateEmail,
                hint: 'Enter the admin\'s email address',
              ),
              
              SizedBox(height: 16),
              
              // Display name field
              CustomTextField(
                label: 'Display Name (Optional)',
                controller: _displayNameController,
                prefixIcon: Icons.person,
                hint: 'Enter display name for the admin',
              ),
              
              SizedBox(height: 24),
              
              // Permissions section
              Text(
                'Admin Permissions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Select what this admin user can do',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: _availablePermissions.map((permission) {
                      return CheckboxListTile(
                        title: Text(permission['label']),
                        subtitle: Text(
                          permission['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: _selectedPermissions.contains(permission['key']),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedPermissions.add(permission['key']);
                            } else {
                              _selectedPermissions.remove(permission['key']);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Create Admin Button
              CustomButton(
                text: _isLoading ? 'Creating Admin...' : 'Create Admin User',
                isLoading: _isLoading,
                onPressed: _selectedPermissions.isNotEmpty ? _addAdmin : null,
              ),
              
              SizedBox(height: 24),
              
              // Email troubleshooting info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'If Password Reset Email Doesn\'t Arrive',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Check ALL email folders (Inbox, Spam, Promotions, Updates)\n'
                      '2. Look for sender: noreply@[your-project].firebaseapp.com\n'
                      '3. Test with a Gmail address first\n'
                      '4. Wait up to 10 minutes for delivery\n'
                      '5. Manual backup: Firebase Console → Auth → Users → Reset Password',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}