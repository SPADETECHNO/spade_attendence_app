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
      // Load sessions for current selected year
      sessionProvider.loadAdminSessions(authProvider.user!.uid);
      
      // Load today's attendance
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));
      
      attendanceProvider.loadAttendanceByDateRange(
        startOfDay,
        endOfDay,
        adminId: authProvider.user!.uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          // Year selector dropdown
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              return PopupMenuButton<String>(
                icon: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sessionProvider.selectedYear,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                onSelected: (year) {
                  sessionProvider.changeSelectedYear(year);
                },
                itemBuilder: (context) {
                  List<String> years = sessionProvider.availableYears;
                  if (years.isEmpty) {
                    years = [DateTime.now().year.toString()];
                  }
                  
                  return years.map((year) => PopupMenuItem<String>(
                    value: year,
                    child: Row(
                      children: [
                        Icon(
                          year == sessionProvider.selectedYear 
                              ? Icons.radio_button_checked 
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: year == sessionProvider.selectedYear 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(year),
                        if (year == DateTime.now().year.toString()) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )).toList();
                },
              );
            },
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'profile') {
                _showProfileDialog();
              } else if (value == 'logout') {
                _logout();
              } else if (value == 'load_all_years') {
                _loadAllYearsSessions();
              } else if (value == 'refresh') {
                _loadDashboardData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'load_all_years',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Load All Years'),
                  ],
                ),
              ),
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
              _buildYearSelector(),
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

  Widget _buildYearSelector() {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        if (sessionProvider.availableYears.isEmpty) {
          return SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing Sessions for ${sessionProvider.selectedYear}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sessionProvider.availableYears.length > 1) ...[
                  SizedBox(height: 8),
                  Text(
                    'Available years: ${sessionProvider.availableYears.join(", ")}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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
                                // **FIXED: Ensure sessionId is properly passed**
                                if (sessionProvider.currentSession?.id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ScannerScreen(
                                        sessionId: sessionProvider.currentSession!.id,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Session ID not available. Please select a session first.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please create or select a session first.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
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
                    Spacer(),
                    // Year badge for current session
                    if (sessionProvider.hasActiveSession)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sessionProvider.currentSession!.sessionDate.year.toString(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
                      // **NEW: Session actions**
                      SizedBox(height: 12),
                      Row(
                        children: [
                          if (sessionProvider.isSessionActive())
                            ElevatedButton.icon(
                              onPressed: () {
                                sessionProvider.endCurrentSession();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Session ended successfully'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                              icon: Icon(Icons.stop, size: 16),
                              label: Text('End Session'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        'No active session. Create a new session to start scanning.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionSetupScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.add),
                        label: Text('Create Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                if (sessionProvider.error != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Error: ${sessionProvider.error}',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
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
                Column(
                  children: [
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
                    if (stats['pending'] != null && stats['pending']! > 0) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem('Verified', stats['verified'] ?? 0, Colors.teal),
                          ),
                          Expanded(
                            child: _buildStatItem('Pending', stats['pending'] ?? 0, Colors.amber),
                          ),
                          Expanded(child: SizedBox()),
                          Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ],
                ),
                if (attendanceProvider.error != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Error: ${attendanceProvider.error}',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
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
          textAlign: TextAlign.center,
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
                    Spacer(),
                    Text(
                      sessionProvider.selectedYear,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (recentSessions.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No sessions created for ${sessionProvider.selectedYear} yet.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionSetupScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Create First Session'),
                        ),
                      ],
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
                      bool isCurrentSession = sessionProvider.currentSession?.id == session.id;
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isCurrentSession 
                              ? Colors.green.withOpacity(0.1)
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            isCurrentSession ? Icons.play_circle_fill : Icons.event,
                            color: isCurrentSession 
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(session.sessionName ?? 'Session')),
                            if (isCurrentSession)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${session.companyName ?? 'Company'} • ${session.sessionDate != null ? session.sessionDate.toString().split(' ')[0] : 'Date'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (session.sessionDate != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: session.sessionDate!.year == DateTime.now().year
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  session.sessionDate!.year.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: session.sessionDate!.year == DateTime.now().year
                                        ? Colors.green
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          if (session.id != null && !isCurrentSession) {
                            String sessionYear = session.sessionDate?.year?.toString() ?? 
                                                sessionProvider.selectedYear;
                            sessionProvider.setCurrentSession(session.id, year: sessionYear);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Session activated: ${session.sessionName} (${sessionYear})'),
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

  void _loadAllYearsSessions() {
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();
    
    if (authProvider.user != null) {
      sessionProvider.loadAllAdminSessions(authProvider.user!.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading sessions from all years...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
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

  @override
  void dispose() {
    // **FIXED: Safe disposal**
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      attendanceProvider.stopListeningToAttendance();
    } catch (e) {
      // Provider might not be available during disposal
      debugPrint('Could not stop listening to attendance: $e');
    }
    super.dispose();
  }
}
