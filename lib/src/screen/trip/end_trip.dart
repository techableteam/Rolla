import 'package:RollaTravel/src/screen/trip/start_trip.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/stop_marker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:logger/logger.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EndTripScreen extends ConsumerStatefulWidget {
  final LatLng? startLocation;
  final LatLng? endLocation;
  final List<MarkerData> stopMarkers;
  final String tripStartDate;
  final String tripEndDate;
  final String tripDistance;
  const EndTripScreen({
    super.key,
    required this.startLocation,
    required this.endLocation,
    required this.stopMarkers,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.tripDistance,
  });

  @override
  ConsumerState<EndTripScreen> createState() => _EndTripScreenState();
}

class _EndTripScreenState extends ConsumerState<EndTripScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 2;
  final Logger logger = Logger();
  final MapController _mapController = MapController();
  double totalDistanceInMeters = 0;

  String? startAddress;
  String? endAddress;
  String stopAddressesString = "";
  List<String> formattedStopAddresses = [];
  List<Map<String, dynamic>> droppins = [];

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    // _fetchRoute();
    _fetchDropPins();
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
  }

  Future<void> _fetchDropPins() async {
    // Convert the list of MarkerData to the desired format
    droppins = widget.stopMarkers.asMap().entries.map((entry) {
      final int index = entry.key + 1; // stop_index starts from 1
      final MarkerData marker = entry.value;

      return {
        "stop_index": index,
        "image_path": marker.imagePath,
        "image_caption": marker.caption,
      };
    }).toList();

    // Log the formatted droppins
    logger.i("Droppins: $droppins");
  }

  Future<void> _fetchAddresses() async {
    if (widget.startLocation != null) {
      startAddress = await getAddressFromLocation(widget.startLocation!);
      logger.i("startAddress : $startAddress");
    }

    if (widget.endLocation != null) {
      endAddress = await getAddressFromLocation(widget.endLocation!);
      logger.i("endAddress : $endAddress");
    }

    if (widget.stopMarkers != []) {
      List<String?> stopMarkerAddresses = await Future.wait(
        widget.stopMarkers.map((marker) async {
          try {
            final address = await getAddressFromLocation(marker.location);
            return address ?? "";
          } catch (e) {
            logger.e(
                "Error fetching address for marker at ${marker.location}: $e");
            return "";
          }
        }),
      );

      // Format the list as JSON-like array
      formattedStopAddresses =
          stopMarkerAddresses.map((address) => '"$address"').toList();
      stopAddressesString = '[${formattedStopAddresses.join(', ')}]';
    }
  }

  Future<String?> getAddressFromLocation(LatLng location) async {
    const String accessToken =
        "pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw";
    final String url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${location.longitude},${location.latitude}.json?access_token=$accessToken";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          // Return the first result's place name
          return data['features'][0]['place_name'];
        } else {
          return "Address not found";
        }
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  // Future<void> _fetchRoute() async {
  //   // Retrieve starting point and moving location
  //   final staticStartingPoint = widget.startLocation;
  //   final movingLocation = widget.endLocation;

  //   // Retrieve waypoints from markersProvider
  //   final markers = widget.stopMarkers;
  //   final waypoints = markers.map((marker) => marker.location).toList();

  //   if (staticStartingPoint == null || movingLocation == null) {
  //     logger.i("Starting point or moving location is missing");
  //     return;
  //   }

  //   // Construct waypoints for the Mapbox Directions API
  //   final waypointString = waypoints
  //       .map((waypoint) => "${waypoint.longitude},${waypoint.latitude}")
  //       .join(";");
  //   final url =
  //       'https://api.mapbox.com/directions/v5/mapbox/driving/${staticStartingPoint.longitude},${staticStartingPoint.latitude};$waypointString;${movingLocation.longitude},${movingLocation.latitude}?geometries=polyline6&access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw';

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       final jsonResponse = jsonDecode(response.body);
  //       final List<dynamic> routes = jsonResponse['routes'];

  //       if (routes.isNotEmpty) {
  //         final String polyline = routes[0]['geometry'];
  //         final List<LatLng> decodedPolyline = _decodePolyline6(polyline);
  //         final double distanceInMeters = routes[0]['distance'];
  //         final double totalDistanceInMiles = distanceInMeters / 1609.34;

  //         setState(() {
  //           _pathCoordinates = decodedPolyline;
  //           totalDistanceInMeters = totalDistanceInMiles;
  //         });
  //       } else {
  //         logger.i("No routes found");
  //       }
  //     } else {
  //       logger.i("Error fetching route: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     logger.i("Error fetching route: $e");
  //   }
  // }

  // List<LatLng> _decodePolyline6(String encoded) {
  //   List<LatLng> polyline = [];
  //   int index = 0, len = encoded.length;
  //   int lat = 0, lng = 0;

  //   while (index < len) {
  //     int b, shift = 0, result = 0;
  //     do {
  //       b = encoded.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1f) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  //     lat += deltaLat;

  //     shift = 0;
  //     result = 0;
  //     do {
  //       b = encoded.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1f) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  //     lng += deltaLng;

  //     polyline.add(LatLng(lat / 1E6, lng / 1E6));
  //   }
  //   return polyline;
  // }

  Future<bool> _onWillPop() async {
    return false;
  }

  Future<void> sendTripData() async {
    final apiserice = ApiService();

    // Convert pathCoordinates to List<Map<String, double>>
    final tripCoordinates = ref
        .read(pathCoordinatesProvider)
        .map((latLng) => {
              'latitude': latLng.latitude,
              'longitude': latLng.longitude,
            })
        .toList();

    final stopLocations = widget.stopMarkers
        .map((marker) => {
              'latitude': marker.location.latitude,
              'longitude': marker.location.longitude,
            })
        .toList();

    logger.i("stopLocations: $stopLocations");

    final response = await apiserice.createTrip(
        userId: GlobalVariables.userId!,
        startAddress: startAddress!,
        stopAddresses: stopAddressesString,
        destinationAddress: endAddress!,
        tripStartDate: widget.tripStartDate,
        tripEndDate: widget.tripEndDate,
        tripMiles: widget.tripDistance,
        tripSound: "tripSound",
        stopLocations: stopLocations,
        tripCoordinates: tripCoordinates, // Use the converted list
        droppins: droppins);

    if (!mounted) return;

    if (response) {
      // Navigate to the next page
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) =>
              const StartTripScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      ref.read(pathCoordinatesProvider.notifier).state = [];
    } else {
      // Show an alert dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Failed to create the trip. Please try again."),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  ref.read(pathCoordinatesProvider.notifier).state = [];
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathCoordinates = ref.watch(pathCoordinatesProvider);

    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: vhh(context, 5),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      spreadRadius: -5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // Handle tap on the logo if needed
                            },
                            child: Image.asset(
                              'assets/images/icons/logo.png', // Replace with your logo asset path
                              height: vh(context, 13),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 10,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.black, size: 28),
                            onPressed: () {
                              ref.read(pathCoordinatesProvider.notifier).state =
                                  [];
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const StartTripScreen()));
                            },
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.0), // Adjust the value as needed
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            destination,
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                          Text(
                            edit_destination,
                            style: TextStyle(
                                color: kColorButtonPrimary,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: kColorButtonPrimary,
                                fontFamily: 'Kadaw'),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0), // Adjust the value as needed
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            miles_traveled,
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                          Text(
                            totalDistanceInMeters.toStringAsFixed(3),
                            style: const TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.0), // Adjust the value as needed
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            soundtrack,
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 14,
                                fontFamily: 'Kadaw'),
                          ),
                          Text(
                            edit_playlist,
                            style: TextStyle(
                                color: kColorButtonPrimary,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: kColorButtonPrimary,
                                fontFamily: 'Kadaw'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Map Image
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: vww(context, 4)),
                      child: SizedBox(
                        height: vhh(context, 30),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: widget.startLocation!,
                                initialZoom: 16.0,
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
                                if (pathCoordinates.isNotEmpty)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: pathCoordinates,
                                        strokeWidth: 4.0,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    if (widget.startLocation != null)
                                      Marker(
                                        width: 80.0,
                                        height: 80.0,
                                        point: widget.startLocation!,
                                        child: const Icon(Icons.location_on,
                                            color: Colors.red, size: 40),
                                      ),
                                    if (widget.endLocation != null)
                                      Marker(
                                        width: 80.0,
                                        height: 80.0,
                                        point: widget.endLocation!,
                                        child: const Icon(Icons.location_on,
                                            color: Colors.green, size: 40),
                                      ),
                                    if (widget.stopMarkers.isNotEmpty)
                                      ...widget.stopMarkers.map((markerData) {
                                        return Marker(
                                          width: 80.0,
                                          height: 80.0,
                                          point: markerData.location,
                                          child: GestureDetector(
                                            onTap: () {
                                              // Display the image in a dialog
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8.0,
                                                                vertical: 4.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              markerData
                                                                  .caption,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors.grey,
                                                                fontFamily:
                                                                    'Kadaw',
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.close,
                                                                  color: Colors
                                                                      .black),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
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
                                                            child,
                                                            loadingProgress) {
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
                                                                        (loadingProgress.expectedTotalBytes ??
                                                                            1)
                                                                    : null, // Show progress if available
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          // Fallback widget in case of an error
                                                          return const Icon(
                                                              Icons
                                                                  .broken_image,
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
                              ],
                            ),

                            // Zoom in/out buttons
                            Positioned(
                              right: 10,
                              top: 30,
                              child: Column(
                                children: [
                                  FloatingActionButton(
                                    heroTag: 'zoom_in_button_endtrip_1',
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
                                    heroTag: 'zoom_in_button_endtrip_2',
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Footer Text
                    const Text(
                      'Travel. Share.',
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'KadawBold',
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'the Rolla travel app',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'Kadaw'),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Share this summary:',
                    style: TextStyle(fontSize: 16, fontFamily: 'Kadaw'),
                  ),
                  GestureDetector(
                    onTap: () {
                      sendTripData();
                    },
                    child: Image.asset(
                      "assets/images/icons/share.png",
                      height: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
