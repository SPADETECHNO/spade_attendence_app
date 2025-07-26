import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/admin_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import 'add_admin_screen.dart';

class ManageAdminsScreen extends StatefulWidget {
  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Admins'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAdminScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.user == null) {
            return LoadingWidget(message: 'Loading...');
          }

          return StreamBuilder<List<AdminModel>>(
            stream: _firestoreService.getAdmins(authProvider.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingWidget(message: 'Loading admins...');
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Error loading admins',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              List<AdminModel> admins = snapshot.data ?? [];

              if (admins.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // Stats header
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatColumn(
                                'Total Admins',
                                admins.length.toString(),
                                Icons.people,
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildStatColumn(
                                'Active',
                                admins.where((admin) => admin.isActive).length.toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildStatColumn(
                                'Inactive',
                                admins.where((admin) => !admin.isActive).length.toString(),
                                Icons.cancel,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Admin list
                  Expanded(
                    child: ListView.builder(
                      itemCount: admins.length,
                      itemBuilder: (context, index) {
                        AdminModel admin = admins[index];
                        return _buildAdminCard(admin);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'No Admins Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start by adding your first admin user',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 32),
          CustomButton(
            text: 'Add First Admin',
            icon: Icons.person_add,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAdminScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCard(AdminModel admin) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: admin.isActive ? Colors.green : Colors.grey,
                  child: Text(
                    admin.email.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.displayName ?? admin.email.split('@')[0],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        admin.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: admin.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    admin.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Added: ${admin.assignedAt.toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Spacer(),
                Text(
                  'Permissions: ${admin.permissions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAdminDetails(admin),
                    child: Text('View Details'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleAdminStatus(admin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: admin.isActive ? Colors.red : Colors.green,
                    ),
                    child: Text(admin.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminDetails(AdminModel admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Email', admin.email),
            _buildDetailRow('Display Name', admin.displayName ?? 'Not set'),
            _buildDetailRow('Status', admin.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Assigned Date', admin.assignedAt.toString().split(' ')[0]),
            _buildDetailRow('Permissions', admin.permissions.join(', ')),
            if (admin.lastKnownLocation != null)
              _buildDetailRow('Last Location', 
                '${admin.lastKnownLocation!['latitude']?.toStringAsFixed(6)}, ${admin.lastKnownLocation!['longitude']?.toStringAsFixed(6)}'),
            SizedBox(height: 24),
            CustomButton(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAdminStatus(AdminModel admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${admin.isActive ? 'Deactivate' : 'Activate'} Admin'),
        content: Text(
          'Are you sure you want to ${admin.isActive ? 'deactivate' : 'activate'} ${admin.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _firestoreService.updateAdminStatus(admin.id, !admin.isActive);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Admin status updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update admin status'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(admin.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }
}
