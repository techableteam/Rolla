import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// Define a marker data model
class MarkerData {
  final LatLng location;
  final String imagePath;
  final String caption;

  MarkerData({required this.location, required this.imagePath, required this.caption});
}

// State provider for managing markers
final markersProvider = StateProvider<List<MarkerData>>((ref) => []);