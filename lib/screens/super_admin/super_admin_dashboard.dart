import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_button.dart';
import '../auth/login_screen.dart';
import 'manage_admins_screen.dart';
import 'add_admin_screen.dart';
import '../common/profile_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, int> _stats = {
    'totalAdmins': 0,
    'activeAdmins': 0,
    'totalSessions': 0,
    'todayAttendance': 0,
  };
  
  // **NEW: Year-based tracking**
  String _selectedYear = DateTime.now().year.toString();
  List<String> _availableYears = [];
  Map<String, int> _yearlyStats = {};
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _loadAvailableYears();
  }

  void _loadDashboardStats() {
    setState(() {
      _isLoadingStats = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      // Load admin stats
      _firestoreService.getAdmins(authProvider.user!.uid).listen((admins) {
        if (mounted) {
          setState(() {
            _stats['totalAdmins'] = admins.length;
            _stats['activeAdmins'] = admins.where((admin) => admin.isActive).length;
          });
        }
      });

      // **NEW: Load year-specific session stats**
      _loadYearlySessionStats(authProvider.user!.uid);
    }
  }

  // **NEW: Load available years**
  Future<void> _loadAvailableYears() async {
    try {
      List<String> years = await _firestoreService.getAvailableSessionYears();
      setState(() {
        _availableYears = years;
        if (_availableYears.isNotEmpty && !_availableYears.contains(_selectedYear)) {
          _availableYears.insert(0, _selectedYear);
          _availableYears.sort((a, b) => b.compareTo(a)); // Sort descending
        }
      });
    } catch (e) {
      print('Error loading available years: $e');
    }
  }

  // **NEW: Load yearly session statistics**
  Future<void> _loadYearlySessionStats(String superAdminId) async {
    try {
      // Load stats for current selected year
      await _loadStatsForYear(_selectedYear);
      
      // Load today's attendance (current year only)
      DateTime now = DateTime.now();
      if (_selectedYear == now.year.toString()) {
        // TODO: Implement today's attendance count from all admins
        // This would require aggregating attendance across all sessions for today
        setState(() {
          _stats['todayAttendance'] = 0; // Placeholder
        });
      }
    } catch (e) {
      print('Error loading yearly stats: $e');
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  // **NEW: Load statistics for specific year**
  Future<void> _loadStatsForYear(String year) async {
    try {
      // Get all admins first
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      // Count sessions for the selected year across all admins
      int totalSessionsForYear = 0;
      // This would require a more complex query to get sessions from all admins for a specific year
      // For now, we'll use a placeholder implementation
      
      setState(() {
        _stats['totalSessions'] = totalSessionsForYear;
        _yearlyStats[year] = totalSessionsForYear;
      });
    } catch (e) {
      print('Error loading stats for year $year: $e');
    }
  }

  // **NEW: Change selected year**
  Future<void> _changeSelectedYear(String year) async {
    if (_selectedYear != year) {
      setState(() {
        _selectedYear = year;
        _isLoadingStats = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await _loadYearlySessionStats(authProvider.user!.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Super Admin Dashboard'),
        actions: [
          // **NEW: Year selector**
          if (_availableYears.isNotEmpty)
            PopupMenuButton<String>(
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
                      _selectedYear,
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
              onSelected: _changeSelectedYear,
              itemBuilder: (context) {
                return _availableYears.map((year) => PopupMenuItem<String>(
                  value: year,
                  child: Row(
                    children: [
                      Icon(
                        year == _selectedYear 
                            ? Icons.radio_button_checked 
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: year == _selectedYear 
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
            ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              } else if (value == 'logout') {
                _logout();
              } else if (value == 'refresh_years') {
                _loadAvailableYears();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh_years',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Refresh Years'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
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
          _loadDashboardStats();
          await _loadAvailableYears();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              SizedBox(height: 16),
              // **NEW: Year indicator**
              _buildYearIndicator(),
              SizedBox(height: 16),
              _buildStatsCards(),
              SizedBox(height: 16),
              _buildQuickActions(),
              SizedBox(height: 16),
              _buildRecentActivity(),
              SizedBox(height: 16),
              _buildSystemInfo(),
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
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.admin_panel_settings,
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
                        'Welcome, Super Admin!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        authProvider.user?.email ?? 'Administrator',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your attendance system across all years',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
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

  // **NEW: Year indicator widget**
  Widget _buildYearIndicator() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing Year: $_selectedYear',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_availableYears.length > 1)
                  Text(
                    'Available: ${_availableYears.join(", ")}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            Spacer(),
            if (_selectedYear != DateTime.now().year.toString())
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Historical',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            if (_isLoadingStats)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Admins',
                _stats['totalAdmins']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
                subtitle: 'All time',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active Admins',
                _stats['activeAdmins']?.toString() ?? '0',
                Icons.person_outline,
                Colors.green,
                subtitle: 'Currently active',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sessions',
                _stats['totalSessions']?.toString() ?? '0',
                Icons.event,
                Colors.orange,
                subtitle: _selectedYear,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                _selectedYear == DateTime.now().year.toString() 
                    ? 'Today\'s Scans' 
                    : 'Year Scans',
                _stats['todayAttendance']?.toString() ?? '0',
                Icons.qr_code_scanner,
                Colors.purple,
                subtitle: _selectedYear == DateTime.now().year.toString() 
                    ? 'Today' 
                    : _selectedYear,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: CustomButton(
                        text: 'Add Admin',
                        icon: Icons.person_add,
                        backgroundColor: Colors.green,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAdminScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Flexible(
                      child: CustomButton(
                        text: 'Manage',
                        icon: Icons.manage_accounts,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageAdminsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                CustomButton(
                  text: 'View All Reports ($_selectedYear)',
                  icon: Icons.analytics,
                  backgroundColor: Colors.purple,
                  onPressed: () {
                    // TODO: Implement reports screen with year filter
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reports for $_selectedYear coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            if (_selectedYear != DateTime.now().year.toString())
              Text(
                '(${_selectedYear})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedYear == DateTime.now().year.toString()) ...[
                  _buildActivityItem(
                    'New admin added',
                    'admin@company.com was assigned admin access',
                    '2 hours ago',
                    Icons.person_add,
                    Colors.green,
                  ),
                  Divider(),
                  _buildActivityItem(
                    'Session created',
                    'Morning attendance session for ABC Company',
                    '4 hours ago',
                    Icons.event,
                    Colors.blue,
                  ),
                  Divider(),
                  _buildActivityItem(
                    'Attendance recorded',
                    '25 students scanned in current session',
                    '6 hours ago',
                    Icons.qr_code_scanner,
                    Colors.orange,
                  ),
                ] else ...[
                  // Historical year placeholder
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Historical data for $_selectedYear',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          'Activity details not available for past years',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, String time, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('App Version', '1.0.0'),
                _buildInfoRow('Database Status', 'Connected', Colors.green),
                _buildInfoRow('Available Years', _availableYears.length.toString()),
                _buildInfoRow('Current Year', _selectedYear, 
                  _selectedYear == DateTime.now().year.toString() ? Colors.green : Colors.orange),
                _buildInfoRow('Last Backup', 'Today, 3:00 AM'),
                _buildInfoRow('Total Storage Used', '2.5 MB'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
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
              color: valueColor,
            ),
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
              Provider.of<AuthProvider>(context, listen: false).signOut();
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
