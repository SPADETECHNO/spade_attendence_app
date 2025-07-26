import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _displayNameController.text = authProvider.userModel?.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      bool success = await authProvider.updateProfile(_displayNameController.text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Profile updated successfully'
              : authProvider.error ?? 'Failed to update profile'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            authProvider.isSuperAdmin 
                                ? Icons.admin_panel_settings 
                                : Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.userModel?.displayName ?? 
                                authProvider.user?.email?.split('@')[0] ?? 
                                'User',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                authProvider.user?.email ?? 'No email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: authProvider.isSuperAdmin 
                                      ? Colors.purple 
                                      : Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  authProvider.isSuperAdmin ? 'Super Admin' : 'Admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                
                // Update Profile Section
                Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Display Name',
                            controller: _displayNameController,
                            prefixIcon: Icons.person,
                            validator: (value) => Validators.validateRequired(value, 'Display name'),
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            label: 'Email Address',
                            enabled: false,
                            controller: TextEditingController(text: authProvider.user?.email ?? ''),
                            prefixIcon: Icons.email,
                          ),
                          SizedBox(height: 20),
                          CustomButton(
                            text: 'Update Profile',
                            isLoading: authProvider.isLoading,
                            onPressed: _updateProfile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Account Statistics (for Super Admin)
                if (authProvider.isSuperAdmin) ...[
                  Text(
                    'Account Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatRow('Account Type', 'Super Administrator'),
                          _buildStatRow('Account Created', 
                              authProvider.userModel?.createdAt.toString().split(' ')[0] ?? 'Unknown'),
                          _buildStatRow('Last Login', 'Today'),
                          _buildStatRow('Total Admins Managed', '5'), // This would come from actual data
                        ],
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 24),
                
                // App Information
                Text(
                  'App Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatRow('App Version', '1.0.0'),
                        _buildStatRow('Platform', 'Flutter'),
                        _buildStatRow('Database', 'Firebase Firestore'),
                        _buildStatRow('Authentication', 'Firebase Auth'),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Danger Zone
                Card(
                  color: Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Danger Zone',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Once you delete your account, there is no going back. Please be certain.',
                          style: TextStyle(
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        CustomButton(
                          text: 'Delete Account',
                          backgroundColor: Colors.red,
                          onPressed: _showDeleteAccountDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and will remove all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account deletion feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
