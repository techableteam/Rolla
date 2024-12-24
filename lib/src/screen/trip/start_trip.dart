import 'package:RollaTravel/src/constants/app_button.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/trip/destination_screen.dart';
import 'package:RollaTravel/src/screen/trip/end_trip.dart';
import 'package:RollaTravel/src/screen/trip/sound_screen.dart';
import 'package:RollaTravel/src/screen/trip/trip_settting_screen.dart';
import 'package:RollaTravel/src/screen/trip/trip_tag_screen.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/utils/stop_marker_provider.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:math';

class StartTripScreen extends ConsumerStatefulWidget {
  const StartTripScreen({super.key});

  @override
  ConsumerState<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends ConsumerState<StartTripScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 2;
  StreamSubscription<Position>? _positionStreamSubscription;
  final MapController _mapController = MapController();
  bool hasSetStartPoint = false;
  final logger = Logger();
  LatLng? currentLocation;
  final TextEditingController _captionController = TextEditingController();
  String editDestination = 'Edit destination';
  String initialSound = "Edit Playlist";
  double totalDistanceInMiles = 0;

  @override
  void initState() {
    super.initState();
    _restoreState();
    _getCurrentLocation();
    _startTrackingMovement();
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
    _positionStreamSubscription?.cancel();
  }

  Future<void> _getCurrentLocation() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      currentLocation = LatLng(position.latitude, position.longitude);
      // ✅ Update only the moving location (for display purposes)
      ref.read(movingLocationProvider.notifier).state ??= currentLocation;
      _mapController.move(currentLocation!, 15.0);
    } else if (permissionStatus.isDenied ||
        permissionStatus.isPermanentlyDenied) {
      logger.i("Location permission denied. Redirecting to settings.");
      _showPermissionDeniedDialog();
    } else {
      logger.i("Location permission status: $permissionStatus");
    }
  }

  Future<void> _startTrackingMovement() async {
    if (_positionStreamSubscription != null) {
      return; // Prevent multiple listeners
    }
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final LatLng newLocation = LatLng(position.latitude, position.longitude);

      if (!GlobalVariables.isTripStarted) {
        ref.read(movingLocationProvider.notifier).state = newLocation;
        ref.read(staticStartingPointProvider.notifier).state = newLocation;
      } else {
        final previousLocation = ref.read(movingLocationProvider);
        ref.read(movingLocationProvider.notifier).state = newLocation;

        if (previousLocation != null) {
          await _fetchDrivingRoute(previousLocation, newLocation);
        }
      }

      _mapController.move(newLocation, 15.0);
    });
  }

  Future<void> _fetchDrivingRoute(LatLng start, LatLng end) async {
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=polyline6&overview=full&alternatives=false&steps=true&access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> routes = jsonResponse['routes'];
        if (routes.isNotEmpty) {
          final String polyline = routes[0]['geometry'];
          final List<LatLng> decodedPolyline = _decodePolyline6(polyline);

          final double distanceInMeters =
              (routes[0]['distance'] as num).toDouble();
          final double newMiles = distanceInMeters / 1609.34;

          final currentTotal = ref.read(totalDistanceProvider);
          ref.read(totalDistanceProvider.notifier).state =
              currentTotal + newMiles;
          GlobalVariables.totalDistance = currentTotal + newMiles;

          // Get current path
          final currentPath = ref.read(pathCoordinatesProvider);

          if (currentPath.isEmpty) {
            // First segment of the route
            ref.read(pathCoordinatesProvider.notifier).state = decodedPolyline;
          } else {
            // Find the last point in the current path
            final lastPoint = currentPath.last;

            // Find where to connect the new segment
            int connectionIndex = 0;
            double minDistance = double.infinity;

            // Find the closest point in the new polyline to connect
            for (int i = 0; i < decodedPolyline.length; i++) {
              final distance =
                  _calculateRealDistance(lastPoint, decodedPolyline[i]);
              if (distance < minDistance) {
                minDistance = distance;
                connectionIndex = i;
              }
            }

            // Create new path by:
            // 1. Taking all points from current path
            // 2. Adding only new points from the new segment
            final List<LatLng> newPath = [...currentPath];

            // Only add points that are actually new (after the connection point)
            for (int i = connectionIndex; i < decodedPolyline.length; i++) {
              final newPoint = decodedPolyline[i];
              // Check if this point is significantly different from the last added point
              if (newPath.isEmpty ||
                  _calculateRealDistance(newPath.last, newPoint) > 10) {
                // 10 meters threshold
                newPath.add(newPoint);
              }
            }

            // Update the path
            ref.read(pathCoordinatesProvider.notifier).state = newPath;
          }
        }
      }
    } catch (e) {
      logger.e('Error fetching route: $e');
    }
  }

  // Helper method to calculate real-world distance
  double _calculateRealDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  void toggleTrip() {
    if (GlobalVariables.isTripStarted) {
      // ✅ End the trip
      _endTrip();
    } else {
      // ✅ Start the trip
      _startTrip();
    }
  }

  void _startTrip() {
    GlobalVariables.isTripStarted = true;
    ref.read(isTripStartedProvider.notifier).state = true;

    // ✅ Record trip start time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    GlobalVariables.tripStartDate = formattedDate;

    // ✅ Set static starting point (this is the current location at the moment the trip starts)
    final currentLocation = ref.read(movingLocationProvider);
    if (currentLocation != null) {
      // ✅ Set this location as the starting point for the trip
      ref.read(staticStartingPointProvider.notifier).state = currentLocation;
    }

    // ✅ Clear previous path to start a new trip
    ref.read(pathCoordinatesProvider.notifier).state = [];

    // ✅ Start tracking user movement
    _startTrackingMovement();
  }

  void _endTrip() {
    LatLng? startLocation = ref.read(staticStartingPointProvider);
    LatLng? endLocation = ref.read(movingLocationProvider);
    List<MarkerData> stopMarkers = ref.read(markersProvider);

    // ✅ Record trip end time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    GlobalVariables.tripEndDate = formattedDate;

    String tripMiles =
        "${GlobalVariables.totalDistance.toStringAsFixed(3)} miles";

    if (GlobalVariables.tripStartDate != null &&
        GlobalVariables.tripEndDate != null) {
      // ✅ End the trip and navigate to the EndTripScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EndTripScreen(
            startLocation: startLocation,
            endLocation: endLocation,
            stopMarkers: stopMarkers,
            tripStartDate: GlobalVariables.tripStartDate!,
            tripEndDate: GlobalVariables.tripEndDate!,
            tripDistance: tripMiles,
          ),
        ),
      );

      // ✅ Reset the trip state
      ref.read(isTripStartedProvider.notifier).state = false;
      GlobalVariables.isTripStarted = false;

      // ✅ Reset all trip-related data
      ref.read(staticStartingPointProvider.notifier).state =
          ref.read(movingLocationProvider);
      ref.read(movingLocationProvider.notifier).state = null;
      ref.read(markersProvider.notifier).state = [];
      ref.read(totalDistanceProvider.notifier).state = 0.0;
      GlobalVariables.totalDistance = 0.0;
    } else {
      logger.i("tripStartDate is null.");
    }
  }

  List<LatLng> _decodePolyline6(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      polyline.add(LatLng(lat / 1E6, lng / 1E6));
    }
    return polyline;
  }

  void _restoreState() {
    final movingLocation = ref.read(movingLocationProvider);
    final pathCoordinates = ref.read(pathCoordinatesProvider);

    if (movingLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(movingLocation, 14.0);
      });
    }

    // Redraw the path
    if (pathCoordinates.isNotEmpty) {
      // Delay the modification to avoid the error
      Future(() {
        ref.read(pathCoordinatesProvider.notifier).state = [...pathCoordinates];
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: const Text(
            "To access your location, please enable permissions in System Preferences > Security & Privacy > Privacy > Location Services.",
          ),
          actions: [
            TextButton(
              child: const Text("Open Settings"),
              onPressed: () async {
                await openAppSettings();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onSettingClicked() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const TripSetttingScreen()));
  }

  void _onTagClicked() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const TripTagSearchScreen()));
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final pathCoordinates = ref.watch(pathCoordinatesProvider);
    final movingLocation = ref.watch(movingLocationProvider);
    final staticStartingPoint = ref.watch(staticStartingPointProvider);

    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: vhh(context, 5)),
                Padding(
                  padding: EdgeInsets.only(
                      left: vww(context, 4), right: vww(context, 4)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/icons/logo.png',
                        width: vww(context, 20),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _onTagClicked();
                            },
                            child: Image.asset(
                              'assets/images/icons/add_car1.png',
                              width: vww(context, 15),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _onSettingClicked();
                            },
                            child: Image.asset(
                              'assets/images/icons/setting.png',
                              width: vww(context, 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
                  child: const Divider(color: kColorGrey, thickness: 1),
                ),

                SizedBox(height: vhh(context, 1)),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            destination,
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation1,
                                          animation2) =>
                                      DestinationScreen(
                                          initialDestination: editDestination),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  editDestination = result;
                                });
                              }
                            },
                            child: Text(
                              editDestination.length > 30
                                  ? '${editDestination.substring(0, 30)}...'
                                  : editDestination,
                              style: const TextStyle(
                                color: kColorButtonPrimary,
                                fontSize: 14,
                                fontFamily: 'Kadaw',
                                decoration: TextDecoration.underline,
                                decorationColor: kColorButtonPrimary,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Add ellipsis if text is too long
                              maxLines: 1, // Limit to one line
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            miles_traveled,
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                          Text(
                            "0",
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            soundtrack,
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation1,
                                          animation2) =>
                                      SoundScreen(initialSound: initialSound),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  initialSound = result;
                                });
                              }
                            },
                            child: const Text(
                              edit_playlist,
                              style: TextStyle(
                                  color: kColorButtonPrimary,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: kColorButtonPrimary,
                                  fontFamily: 'Kadaw'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: vhh(context, 1),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors
                          .grey[200], // Background color similar to the image
                      border: Border.all(color: Colors.black), // Black border
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0), // Inner padding
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Caption:',
                          style: TextStyle(
                              color: kColorBlack,
                              fontSize: 14,
                              fontFamily: 'Kadaw'),
                        ),
                        const SizedBox(
                            width:
                                8), // Spacing between the label and input field
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            decoration: const InputDecoration(
                              isDense:
                                  true, // Reduces padding inside the TextField
                              border: InputBorder
                                  .none, // Removes default TextField border
                              hintText:
                                  '', // Empty hint text for a cleaner look
                            ),
                            style: const TextStyle(
                                fontSize: 14,
                                color: kColorBlack,
                                fontFamily: 'Kadaw'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  height: vhh(context, 1),
                ),

                // MapBox integration with a customized size
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
                  child: SizedBox(
                    height: vhh(context, 55),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: movingLocation ??
                                staticStartingPoint ??
                                const LatLng(43.1557, -77.6157),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw",
                              additionalOptions: const {
                                'access_token':
                                    'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw',
                              },
                            ),
                            MarkerLayer(
                              markers: [
                                if (movingLocation != null &&
                                    GlobalVariables.isTripStarted)
                                  Marker(
                                    width: 40.0,
                                    height: 40.0,
                                    point: movingLocation,
                                    child: Image.asset(
                                      'assets/images/icons/car_icon.png',
                                      width: 40,
                                      height: 35,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                if (staticStartingPoint != null)
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: staticStartingPoint,
                                    child: const Icon(Icons.location_on,
                                        color: Colors.red, size: 40),
                                  ),
                                // Markers from markersProvider
                                ...ref.watch(markersProvider).map((markerData) {
                                  return Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: markerData.location,
                                    child: GestureDetector(
                                      onTap: () {
                                        // Display the image in a dialog
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 4.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        markerData.caption,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.grey,
                                                          fontFamily: 'Kadaw',
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.close,
                                                            color:
                                                                Colors.black),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Image.network(
                                                  markerData.imagePath,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      // Image has loaded successfully
                                                      return child;
                                                    } else {
                                                      // Display a loading indicator while the image is loading
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  (loadingProgress
                                                                          .expectedTotalBytes ??
                                                                      1)
                                                              : null, // Show progress if available
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    // Fallback widget in case of an error
                                                    return const Icon(
                                                        Icons.broken_image,
                                                        size: 100);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors
                                            .blue, // Blue for additional markers
                                        size: 40,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            PolylineLayer(polylines: [
                              Polyline(
                                  points: pathCoordinates,
                                  strokeWidth: 4.0,
                                  color: Colors.blue)
                            ]),
                          ],
                        ),

                        GlobalVariables.isTripStarted
                            ? Positioned(
                                top: 1,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: EdgeInsets.zero, // Adjust for width
                                  child: Container(
                                    padding: const EdgeInsets.all(3.0),
                                    color: Colors.white.withOpacity(0.5),
                                    child: const Column(
                                      children: [
                                        Text(
                                          'Trip in progress',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              fontFamily: 'KadawBold'),
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          'Drop a pin to post your map',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              fontFamily: 'Kadaw'),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),

                        // Zoom in/out buttons
                        Positioned(
                          right: 10,
                          top: 70,
                          child: Column(
                            children: [
                              FloatingActionButton(
                                heroTag:
                                    'zoom_in_button_starttrip_1', // Unique tag for the zoom in button
                                onPressed: () {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    _mapController.camera.zoom + 1,
                                  );
                                },
                                mini: true,
                                child: const Icon(Icons.zoom_in),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton(
                                heroTag:
                                    'zoom_out_button_starttrip_2', // Unique tag for the zoom out button
                                onPressed: () {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    _mapController.camera.zoom - 1,
                                  );
                                },
                                mini: true,
                                child: const Icon(Icons.zoom_out),
                              ),
                            ],
                          ),
                        ),

                        // Button overlay
                        Positioned(
                          bottom: 70,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: vww(context, 15),
                                  right: vww(context, 15),
                                  top: vhh(context, 3)),
                              child: ButtonWidget(
                                btnType: GlobalVariables.isTripStarted
                                    ? ButtonWidgetType.endTripTitle
                                    : ButtonWidgetType.startTripTitle,
                                borderColor: GlobalVariables.isTripStarted
                                    ? Colors.red
                                    : kColorButtonPrimary,
                                textColor: kColorWhite,
                                fullColor: GlobalVariables.isTripStarted
                                    ? Colors.red
                                    : kColorButtonPrimary,
                                onPressed: toggleTrip,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 5,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.zero, // Adjust for width
                            child: Container(
                              padding: const EdgeInsets.all(
                                  3.0), // Inner padding for spacing around text
                              color: Colors.white.withOpacity(
                                  0.5), // Background color with slight transparency
                              child: const Text(
                                'Note: Start trip, then drop a pin to make\nyour post visible to your followers',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Kadaw',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
