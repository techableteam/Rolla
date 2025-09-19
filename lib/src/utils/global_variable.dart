import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final isTripStartedProvider = StateProvider<bool>((ref) => false);

final pathCoordinatesProvider = StateProvider<List<LatLng>>((ref) => []);

final staticStartingPointProvider = StateProvider<LatLng?>((ref) => null);

final movingLocationProvider = StateProvider<LatLng?>((ref) => null);

final totalDistanceProvider = StateProvider<double>((ref) => 0.0);
// Signal that increments every time the Home tab is reselected.
final homeTabReselectedProvider = StateProvider<int>((ref) => 0);

class GlobalVariables {
  static int? userId;
  static String? userName;
  static String? realName;
  static String? bio;
  static String? happyPlace;
  static String? odometer;
  static String? garage;
  static String? garageLogoUrl;
  static String? userImageUrl;
  static String? tripStartDate;
  static String? tripEndDate;
  static String? editDestination;
  static String? tripCaption;
  static String? song1;
  static String? song2;
  static String? song3;
  static String? song4;
  static int? tripCount;
  static int delaySetting = 0;
  static int? homeTripID;
  static double totalDistance = 0.0;
  static String? followingIds;
  static List<int> selectedUserIds= [];
  static List<dynamic>? dropPinsData;
  static bool isTripStarted = false;
  static bool openComment = false;
  static int mapStyleSelected = 0;
  static int droppinCount= 0;
  static int? likedDroppinId;
}
