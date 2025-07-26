import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/scanner/scanner_widget.dart';
import '../../widgets/common/custom_button.dart';
import 'scan_result_screen.dart';

class ScannerScreen extends StatefulWidget {
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? _scannedData;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkSessionAndLocation();
  }

  void _checkSessionAndLocation() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    if (!sessionProvider.hasActiveSession) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active session. Please create a session first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update location when scanner opens
    await sessionProvider.updateCurrentLocation();
  }

  void _onScanComplete(String data) {
    setState(() {
      _scannedData = data;
      _isProcessing = false;
    });

    // Navigate to result screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(scannedData: data),
      ),
    ).then((_) {
      // Reset scanning state when returning
      setState(() {
        _scannedData = null;
        _isProcessing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: Colors.black,
        actions: [
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              return IconButton(
                icon: Icon(Icons.info),
                onPressed: () => _showSessionInfo(sessionProvider),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Consumer2<SessionProvider, AttendanceProvider>(
        builder: (context, sessionProvider, attendanceProvider, child) {
          if (!sessionProvider.hasActiveSession) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Active Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please create a session first',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 24),
                  CustomButton(
                    text: 'Go Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Scanner Widget
              ScannerWidget(
                onScanComplete: _onScanComplete,
                overlayText: 'Position the QR code within the frame',
              ),

              // Session info overlay
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.black.withOpacity(0.7),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionProvider.currentSession?.sessionName ?? 'Current Session',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          sessionProvider.currentSession?.companyName ?? '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (sessionProvider.currentLocation != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Location verified',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 50,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.black.withOpacity(0.7),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ready to scan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (attendanceProvider.lastScannedData != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Last scan: ${attendanceProvider.lastScannedData}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Processing overlay
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Processing scan...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSessionInfo(SessionProvider sessionProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            if (sessionProvider.currentSession != null) ...[
              _buildInfoRow('Company', sessionProvider.currentSession!.companyName),
              _buildInfoRow('Session', sessionProvider.currentSession!.sessionName),
              _buildInfoRow('Date', sessionProvider.currentSession!.sessionDate.toString().split(' ')[0]),
              _buildInfoRow('Time', '${sessionProvider.currentSession!.startTime} - ${sessionProvider.currentSession!.endTime}'),
              _buildInfoRow('Status', sessionProvider.isSessionActive() ? 'Active' : 'Outside hours'),
              if (sessionProvider.currentLocation != null) ...[
                _buildInfoRow(
                  'Latitude',
                  sessionProvider.currentLocation?.latitude != null
                      ? sessionProvider.currentLocation!.latitude!.toStringAsFixed(6)
                      : 'Unknown',
                ),
                _buildInfoRow(
                  'Longitude',
                  sessionProvider.currentLocation?.longitude != null
                      ? sessionProvider.currentLocation!.longitude!.toStringAsFixed(6)
                      : 'Unknown',
                ),
              ],
            ],
            SizedBox(height: 16),
            CustomButton(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
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
            width: 80,
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
              style: TextStyle(
                fontFamily: label.toLowerCase().contains('lat') ||
                        label.toLowerCase().contains('lon')
                    ? 'monospace'
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
