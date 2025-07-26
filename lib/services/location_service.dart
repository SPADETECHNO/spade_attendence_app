import 'package:location/location.dart';
import 'dart:math';
import '../utils/constants.dart';

class LocationService {
  final Location _location = Location();

  Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return null;
      }
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return null;
      }
      LocationData locationData = await _location.getLocation();
      return locationData;
    } catch (e) {
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    return await _location.serviceEnabled();
  }

  Future<PermissionStatus> getLocationPermission() async {
    return await _location.hasPermission();
  }

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    // Haversine formula for meters
    const R = 6371000; // meters
    double dLat = _toRadians(endLat - startLat);
    double dLon = _toRadians(endLng - startLng);
    double a = 
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(startLat)) * 
      cos(_toRadians(endLat)) *
      sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  bool verifyLocationProximity(
    LocationData currentLocation,
    double targetLatitude,
    double targetLongitude,
    double allowedRadius,
  ) {
    if (currentLocation.latitude == null || currentLocation.longitude == null) return false;
    double distance = calculateDistance(
      currentLocation.latitude!,
      currentLocation.longitude!,
      targetLatitude,
      targetLongitude,
    );
    return distance <= allowedRadius;
  }

  String formatLocationString(LocationData loc) {
    if (loc.latitude == null || loc.longitude == null) return '-';
    return '${loc.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)}';
  }

  Map<String, double> positionToMap(LocationData loc) {
    return {
      'latitude': loc.latitude ?? 0,
      'longitude': loc.longitude ?? 0,
    };
  }

  // Helper method to convert degrees to radians
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
