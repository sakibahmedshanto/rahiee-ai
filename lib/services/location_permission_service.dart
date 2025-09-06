import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:geolocator/geolocator.dart';

class LocationPermissionService extends GetxService {
  static LocationPermissionService get to => Get.find();

  final RxBool isLocationEnabled = false.obs;
  final RxBool hasLocationPermission = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString permissionStatus = 'unknown'.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialPermissionStatus();
  }

  /// Check initial permission status without requesting
  Future<void> _checkInitialPermissionStatus() async {
    try {
      final permission = await permission_handler.Permission.location.status;
      _updatePermissionStatus(permission);
      
      if (permission.isGranted) {
        await _checkLocationService();
      }
    } catch (e) {
      permissionStatus.value = 'error';
    }
  }

  /// Request location permission with comprehensive handling
  Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult(
          success: false,
          message: 'Location service is disabled. Please enable GPS.',
          action: LocationPermissionAction.enableGPS,
        );
      }

      // Check current permission status
      permission_handler.PermissionStatus permission = await permission_handler.Permission.location.status;
      
      // Request permission if needed
      if (permission.isDenied) {
        permission = await permission_handler.Permission.location.request();
      }

      _updatePermissionStatus(permission);

      // Handle different permission states
      if (permission.isGranted) {
        await _getCurrentLocation();
        return LocationPermissionResult(
          success: true,
          message: 'Location permission granted successfully',
          action: LocationPermissionAction.none,
        );
      } else if (permission.isDenied) {
        return LocationPermissionResult(
          success: false,
          message: 'Location permission denied. Please grant permission to continue.',
          action: LocationPermissionAction.requestAgain,
        );
      } else if (permission.isPermanentlyDenied) {
        return LocationPermissionResult(
          success: false,
          message: 'Location permission permanently denied. Please enable it in app settings.',
          action: LocationPermissionAction.openSettings,
        );
      } else if (permission.isRestricted) {
        return LocationPermissionResult(
          success: false,
          message: 'Location access is restricted on this device.',
          action: LocationPermissionAction.none,
        );
      }

      return LocationPermissionResult(
        success: false,
        message: 'Unknown permission state',
        action: LocationPermissionAction.none,
      );
    } catch (e) {
      return LocationPermissionResult(
        success: false,
        message: 'Error requesting location permission: $e',
        action: LocationPermissionAction.none,
      );
    }
  }

  /// Check if location service is enabled
  Future<void> _checkLocationService() async {
    try {
      isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      isLocationEnabled.value = false;
    }
  }

  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      if (!hasLocationPermission.value) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      currentPosition.value = position;
      return position;
    } catch (e) {
      currentPosition.value = null;
      return null;
    }
  }

  /// Update permission status
  void _updatePermissionStatus(permission_handler.PermissionStatus permission) {
    hasLocationPermission.value = permission.isGranted;
    
    if (permission.isGranted) {
      permissionStatus.value = 'granted';
    } else if (permission.isDenied) {
      permissionStatus.value = 'denied';
    } else if (permission.isPermanentlyDenied) {
      permissionStatus.value = 'permanently_denied';
    } else if (permission.isRestricted) {
      permissionStatus.value = 'restricted';
    } else {
      permissionStatus.value = 'unknown';
    }
  }

  /// Get fresh location (force update)
  Future<Position?> getCurrentLocation() async {
    if (!hasLocationPermission.value) {
      final result = await requestLocationPermission();
      if (!result.success) {
        return null;
      }
    }
    return await _getCurrentLocation();
  }

  /// Open app settings for location permissions
  Future<void> openAppSettings() async {
    await permission_handler.openAppSettings();
  }

  /// Check permission status
  Future<bool> hasPermission() async {
    final permission = await permission_handler.Permission.location.status;
    return permission.isGranted;
  }

  /// Get readable permission status
  String get readablePermissionStatus {
    switch (permissionStatus.value) {
      case 'granted':
        return 'Location permission granted';
      case 'denied':
        return 'Location permission denied';
      case 'permanently_denied':
        return 'Location permission permanently denied';
      case 'restricted':
        return 'Location access restricted';
      case 'error':
        return 'Error checking location permission';
      default:
        return 'Location permission status unknown';
    }
  }
}

/// Result of location permission request
class LocationPermissionResult {
  final bool success;
  final String message;
  final LocationPermissionAction action;

  LocationPermissionResult({
    required this.success,
    required this.message,
    required this.action,
  });
}

/// Actions that can be taken based on permission result
enum LocationPermissionAction {
  none,
  requestAgain,
  openSettings,
  enableGPS,
}
