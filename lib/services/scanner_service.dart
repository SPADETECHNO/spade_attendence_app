import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  MobileScannerController? _controller;

  // Initialize scanner controller
  MobileScannerController initializeController() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    return _controller!;
  }

  // Dispose controller
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  // Toggle torch/flashlight
  Future<void> toggleTorch() async {
    if (_controller != null) {
      await _controller!.toggleTorch();
    }
  }

  // Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_controller != null) {
      await _controller!.switchCamera();
    }
  }

  // Start scanning
  Future<void> startScanning() async {
    if (_controller != null) {
      await _controller!.start();
    }
  }

  // Stop scanning
  Future<void> stopScanning() async {
    if (_controller != null) {
      await _controller!.stop();
    }
  }

  // Validate scanned data
  bool validateScannedData(String data) {
    // Add your validation logic here
    if (data.isEmpty) return false;
    
    // Example validations:
    // - Check if it's a valid student ID format
    // - Verify data structure
    // - Check for required fields
    
    return true;
  }

  // Parse QR code data (if it contains structured data)
  Map<String, dynamic>? parseQRData(String rawData) {
    try {
      // If QR contains JSON data
      if (rawData.startsWith('{') && rawData.endsWith('}')) {
        // You can add JSON parsing here if needed
        return {'rawData': rawData, 'type': 'json'};
      }
      
      // If QR contains simple text
      return {
        'rawData': rawData,
        'type': 'text',
        'studentId': extractStudentId(rawData),
      };
    } catch (e) {
      return null;
    }
  }

  // Extract student ID from scanned data
  String? extractStudentId(String data) {
    // Implement your logic to extract student ID
    // This could be regex matching, string parsing, etc.
    
    // Example: if QR code is "STUDENT_ID:12345"
    if (data.contains('STUDENT_ID:')) {
      return data.split('STUDENT_ID:')[1];
    }
    
    // If it's just the ID
    return data;
  }

  // Format scanned data for display
  String formatForDisplay(String rawData) {
    Map<String, dynamic>? parsedData = parseQRData(rawData);
    
    if (parsedData != null) {
      String studentId = parsedData['studentId'] ?? 'Unknown';
      return 'Student ID: $studentId\nRaw Data: $rawData';
    }
    
    return 'Scanned Data: $rawData';
  }
}
