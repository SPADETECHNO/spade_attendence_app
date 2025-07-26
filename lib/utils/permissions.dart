import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;

class PermissionHelper {
  static final loc.Location _location = loc.Location();

  /// Requests location permission using the `location` package.
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    loc.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return false;
      }
    }

    if (permissionGranted == loc.PermissionStatus.deniedForever) {
      return false;
    }

    return true;
  }

  /// Requests camera permission using the `permission_handler` package.
  static Future<bool> requestCameraPermission() async {
    var status = await perm.Permission.camera.status;
    if (!status.isGranted) {
      status = await perm.Permission.camera.request();
    }
    return status.isGranted;
  }

  /// Check if both location and camera permissions are granted.
  static Future<bool> checkAllPermissions() async {
    bool locationPermission = await requestLocationPermission();
    bool cameraPermission = await requestCameraPermission();

    return locationPermission && cameraPermission;
  }
}
