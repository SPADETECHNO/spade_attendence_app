import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/location/location_widget.dart';

class ScanResultScreen extends StatefulWidget {
  final String scannedData;

  const ScanResultScreen({
    Key? key,
    required this.scannedData,
  }) : super(key: key);

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  Map<String, dynamic>? _processedData;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _processScannedData();
  }

  void _processScannedData() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    _processedData = attendanceProvider.processScannedData(widget.scannedData);
  }

  Future<void> _submitAttendance() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

    if (authProvider.user == null || !sessionProvider.hasActiveSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid session or user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    bool success = await attendanceProvider.submitAttendanceRecord(
      scannedData: widget.scannedData,
      sessionId: sessionProvider.currentSession!.id,
      adminId: authProvider.user!.uid,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attendanceProvider.error ?? 'Failed to record attendance'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Result'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success/Error indicator
            Card(
              color: _processedData?['isValid'] == true 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _processedData?['isValid'] == true 
                          ? Icons.check_circle 
                          : Icons.error,
                      color: _processedData?['isValid'] == true 
                          ? Colors.green 
                          : Colors.red,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _processedData?['isValid'] == true 
                                ? 'Valid QR Code' 
                                : 'Invalid QR Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _processedData?['isValid'] == true 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            _processedData?['isValid'] == true 
                                ? 'Ready to submit attendance'
                                : 'Please scan a valid code',
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

            SizedBox(height: 16),

            // Scanned Data
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.qr_code, color: Theme.of(context).primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Scanned Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        widget.scannedData,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Processed Information
            if (_processedData != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Theme.of(context).primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Student Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (_processedData!['studentId'] != null)
                        _buildInfoRow('Student ID', _processedData!['studentId']),
                      if (_processedData!['studentName'] != null)
                        _buildInfoRow('Student Name', _processedData!['studentName']),
                      _buildInfoRow('Scanned At', DateTime.now().toString().substring(0, 19)),
                      if (_processedData!['error'] != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Error: ${_processedData!['error']}',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Session Information
            Consumer<SessionProvider>(
              builder: (context, sessionProvider, child) {
                if (!sessionProvider.hasActiveSession) {
                  return SizedBox.shrink();
                }

                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event, color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Session Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow('Company', sessionProvider.currentSession!.companyName),
                        _buildInfoRow('Session', sessionProvider.currentSession!.sessionName),
                        _buildInfoRow('Date', sessionProvider.currentSession!.sessionDate.toString().split(' ')[0]),
                        _buildInfoRow('Time', '${sessionProvider.currentSession!.startTime} - ${sessionProvider.currentSession!.endTime}'),
                        Row(
                          children: [
                            Text(
                              'Status: ',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: sessionProvider.isSessionActive() 
                                    ? Colors.green 
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                sessionProvider.isSessionActive() 
                                    ? 'Active' 
                                    : 'Outside Hours',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 16),

            // Location Information
            LocationWidget(
              showRefreshButton: false,
            ),

            SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Scan Again',
                    backgroundColor: Colors.grey,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Submit Attendance',
                    isLoading: _isSubmitting,
                    onPressed: _processedData?['isValid'] == true 
                        ? _submitAttendance 
                        : null,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Warning message if session is not active
            Consumer<SessionProvider>(
              builder: (context, sessionProvider, child) {
                if (!sessionProvider.isSessionActive()) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Attendance is being recorded outside the scheduled session hours.',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
}
