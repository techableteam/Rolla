import 'package:latlong2/latlong.dart';

class Post {
  final String username;
  final String destination;
  final int milesTraveled;
  final String soundtrack;
  final String caption;
  final int comments;
  final String lastUpdated;
  final String imagePath;
  final List<LatLng> locations;
  final List<String> locationImages;
  final List<String> locationDecription;
  final List<Map<String, String>> commentsList;

  Post({
    required this.username,
    required this.destination,
    required this.milesTraveled,
    required this.soundtrack,
    required this.caption,
    required this.comments,
    required this.lastUpdated,
    required this.imagePath,
    required this.locations,
    required this.locationImages,
    required this.locationDecription,
    required this.commentsList,
  });
}