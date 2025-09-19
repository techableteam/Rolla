import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// Define a marker data model
class TripMarkerData {
  final LatLng location;
  final String imagePath;
  final String caption;
  final String delayTime;

  TripMarkerData(
      {required this.location, required this.imagePath, required this.caption, required this.delayTime});
}

// State provider for managing markers
final tripMarkersProvider = StateProvider<List<TripMarkerData>>((ref) => []);
