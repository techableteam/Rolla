import 'package:geolocator/geolocator.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  bool hasLocationPermission = false;

  Future<void> checkAndRequestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      hasLocationPermission = true;
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      hasLocationPermission = (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always);
    }

    if (permission == LocationPermission.deniedForever) {
      hasLocationPermission = false;
    }
  }
}
