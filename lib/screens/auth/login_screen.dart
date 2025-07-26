import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/validators.dart';
import '../super_admin/super_admin_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        bool success = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        if (success && authProvider.userModel != null) {
          print("Role check - isSuperAdmin: ${authProvider.isSuperAdmin}, isAdmin: ${authProvider.isAdmin}");
          print("Current role from model: ${authProvider.userModel?.role}");
          
          if (authProvider.isSuperAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SuperAdminDashboard()),
            );
          } else if (authProvider.isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
            );
          } else {
            throw Exception('Invalid user role: ${authProvider.userModel?.role}');
          }
        } else {
          throw Exception(authProvider.error ?? 'Login failed');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and title
                Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Attendance Scanner',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),

                // Email field
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  validator: Validators.validateEmail,
                ),
                SizedBox(height: 16),

                // Password field
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock,
                  validator: Validators.validatePassword,
                ),
                SizedBox(height: 24),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Sign In',
                      isLoading: authProvider.isLoading,
                      onPressed: _login,
                    );
                  },
                ),

                SizedBox(height: 16),

                // Forgot password
                TextButton(
                  onPressed: () => _showForgotPasswordDialog(),
                  child: Text('Forgot Password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to receive password reset instructions.'),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return TextButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (emailController.text.isNotEmpty) {
                          bool success = await authProvider.sendPasswordReset(
                            emailController.text.trim(),
                          );

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Password reset email sent'
                                    : authProvider.error ??
                                          'Failed to send email',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      },
                child: authProvider.isLoading
                    ? CircularProgressIndicator(strokeWidth: 2)
                    : Text('Send'),
              );
            },
          ),
        ],
      ),
    );
  }
}

