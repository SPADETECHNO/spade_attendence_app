import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/location/location_widget.dart';
import '../../utils/validators.dart';
import '../../utils/date_helpers.dart';

class SessionSetupScreen extends StatefulWidget {
  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _sessionNameController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);

  @override
  void dispose() {
    _companyNameController.dispose();
    _sessionNameController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool success = await sessionProvider.createSession(
        companyName: _companyNameController.text.trim(),
        sessionName: _sessionNameController.text.trim(),
        sessionDate: _selectedDate,
        startTime: DateHelpers.formatTime(
          DateTime(2023, 1, 1, _startTime.hour, _startTime.minute),
        ),
        endTime: DateHelpers.formatTime(
          DateTime(2023, 1, 1, _endTime.hour, _endTime.minute),
        ),
        adminId: authProvider.user!.uid,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sessionProvider.error ?? 'Failed to create session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Session'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New Session',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Configure attendance session details',
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
              
              // Company Name
              CustomTextField(
                label: 'Company Name',
                controller: _companyNameController,
                prefixIcon: Icons.business,
                validator: Validators.validateCompanyName,
              ),
              
              SizedBox(height: 16),
              
              // Session Name
              CustomTextField(
                label: 'Session Name',
                controller: _sessionNameController,
                prefixIcon: Icons.event,
                validator: Validators.validateSessionName,
                hint: 'e.g., Morning Attendance, Workshop Check-in',
              ),
              
              SizedBox(height: 24),
              
              // Date Selection
              Text(
                'Session Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Text(
                        DateHelpers.formatDate(_selectedDate),
                        style: TextStyle(fontSize: 16),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectStartTime(context),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.grey[600]),
                                SizedBox(width: 12),
                                Text(
                                  _startTime.format(context),
                                  style: TextStyle(fontSize: 16),
                                ),
                                Spacer(),
                                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectEndTime(context),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.grey[600]),
                                SizedBox(width: 12),
                                Text(
                                  _endTime.format(context),
                                  style: TextStyle(fontSize: 16),
                                ),
                                Spacer(),
                                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Location Widget
              LocationWidget(
                showRefreshButton: true,
              ),
              
              SizedBox(height: 32),
              
              // Create Session Button
              Consumer<SessionProvider>(
                builder: (context, sessionProvider, child) {
                  return CustomButton(
                    text: 'Create Session',
                    isLoading: sessionProvider.isLoading,
                    onPressed: _createSession,
                  );
                },
              ),
              
              SizedBox(height: 16),
              
              // Info text
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your current location will be recorded and used for attendance verification.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
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
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // Ensure end time is after start time
        if (_endTime.hour < _startTime.hour ||
            (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      // Validate end time is after start time
      if (picked.hour > _startTime.hour ||
          (picked.hour == _startTime.hour && picked.minute > _startTime.minute)) {
        setState(() {
          _endTime = picked;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
