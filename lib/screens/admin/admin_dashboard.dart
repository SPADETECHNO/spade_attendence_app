import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../auth/login_screen.dart';
import 'session_setup_screen.dart';
import 'scanner_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    if (authProvider.user != null) {
      sessionProvider.loadAdminSessions(authProvider.user!.uid);
      
      // Load today's attendance - Updated method call
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));
      
      // Fixed method call with correct parameter order
      attendanceProvider.loadAttendanceByDateRange(
        startOfDay,
        endOfDay,
        adminId: authProvider.user!.uid, // Pass adminId as named parameter
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'profile') {
                _showProfileDialog();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadDashboardData();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              SizedBox(height: 16),
              _buildQuickActions(),
              SizedBox(height: 16),
              _buildCurrentSession(),
              SizedBox(height: 16),
              _buildAttendanceStats(),
              SizedBox(height: 16),
              _buildRecentSessions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        authProvider.userModel?.displayName ?? 
                        authProvider.user?.email ?? 'Admin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (authProvider.isLoading)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'New Session',
                    icon: Icons.add,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SessionSetupScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Consumer<SessionProvider>(
                    builder: (context, sessionProvider, child) {
                      return CustomButton(
                        text: 'Start Scanning',
                        icon: Icons.qr_code_scanner,
                        backgroundColor: sessionProvider.hasActiveSession 
                            ? Colors.green 
                            : Colors.grey,
                        onPressed: sessionProvider.hasActiveSession
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScannerScreen(),
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSession() {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Current Session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (sessionProvider.isLoading)
                  Center(child: CircularProgressIndicator())
                else if (sessionProvider.hasActiveSession)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionProvider.getSessionDisplayInfo(),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: sessionProvider.isSessionActive() 
                                ? Colors.green 
                                : Colors.orange,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            sessionProvider.isSessionActive() 
                                ? 'Active' 
                                : 'Outside session hours',
                            style: TextStyle(
                              color: sessionProvider.isSessionActive() 
                                  ? Colors.green 
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Text(
                    'No active session. Create a new session to start scanning.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (sessionProvider.error != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Error: ${sessionProvider.error}',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStats() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        if (attendanceProvider.isLoading) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        Map<String, int> stats = attendanceProvider.getAttendanceStats();
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Attendance Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem('Today', stats['today'] ?? 0, Colors.blue),
                    ),
                    Expanded(
                      child: _buildStatItem('This Week', stats['thisWeek'] ?? 0, Colors.green),
                    ),
                    Expanded(
                      child: _buildStatItem('This Month', stats['thisMonth'] ?? 0, Colors.orange),
                    ),
                    Expanded(
                      child: _buildStatItem('Total', stats['total'] ?? 0, Colors.purple),
                    ),
                  ],
                ),
                if (attendanceProvider.error != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Error: ${attendanceProvider.error}',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildRecentSessions() {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        if (sessionProvider.isLoading) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        List<dynamic> recentSessions = sessionProvider.sessions.take(5).toList();
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (recentSessions.isEmpty)
                  Text(
                    'No sessions created yet.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: recentSessions.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      var session = recentSessions[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.event,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(session.sessionName ?? 'Session'),
                        subtitle: Text(
                          '${session.companyName ?? 'Company'} • ${session.sessionDate != null ? session.sessionDate.toString().split(' ')[0] : 'Date'}',
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          // Set as current session
                          if (session.id != null) {
                            sessionProvider.setCurrentSession(session.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Session activated: ${session.sessionName}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileDialog() {
    final authProvider = context.read<AuthProvider>();
    final displayNameController = TextEditingController(
      text: authProvider.userModel?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Email: ${authProvider.user?.email ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Role: ${authProvider.userModel?.role ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey[600]),
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
                onPressed: authProvider.isLoading ? null : () async {
                  if (displayNameController.text.isNotEmpty) {
                    bool success = await authProvider.updateProfile(
                      displayNameController.text,
                    );
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                          ? 'Profile updated successfully'
                          : authProvider.error ?? 'Failed to update profile'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: authProvider.isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Update'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
