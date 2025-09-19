import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/home/home_screen.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TripMapWidget extends StatefulWidget {
  final Map<String, dynamic> trip;
  final int index;
  final bool isSelectMode;
  final List<int> selectedMapIndices; 
  final Function(int) onSelectTrip;
  final VoidCallback onDeleteButtonPressed;

  const TripMapWidget({
    super.key,
    required this.trip,
    required this.index,
    required this.isSelectMode,
    required this.selectedMapIndices,
    required this.onSelectTrip, 
    required this.onDeleteButtonPressed,
  });

  @override
  State<TripMapWidget> createState() => _TripMapWidgetState();
}

class _TripMapWidgetState extends State<TripMapWidget> {
  late MapController mapController;
  List<LatLng> routePoints = [];
  List<LatLng> locations = [];
  LatLng? startPoint;
  LatLng? endPoint;
  LatLng? lastDropPoint;
  bool isLoading = true;
  final logger = Logger();
  bool _isSelected = false; 
  List<dynamic> droppins = [];
  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initializeRoutePoints();
    _getLocations().then((_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
    // logger.i(widget.isSelectMode);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void _initializeRoutePoints() {
    if (widget.trip['trip_coordinates'] != null) {
      setState(() {
        routePoints =
            List<Map<String, dynamic>>.from(widget.trip['trip_coordinates'])
                .map((coord) {
                  if (coord['latitude'] is double &&
                      coord['longitude'] is double) {
                    return LatLng(coord['latitude'], coord['longitude']);
                  } else {
                    logger.e('Invalid coordinate data: $coord');
                    return null;
                  }
                })
                .where((latLng) => latLng != null)
                .cast<LatLng>()
                .toList();
      });
    }
  }

  Future<LatLng?> _getCoordinates(String address) async {
    try {
      final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coordinates = data['features'][0]['center'];
          return LatLng(coordinates[1], coordinates[0]); 
        }
      }
      return null;
    } catch (e) {
      logger.e('Error getting coordinates: $e');
      return null;
    }
  }

  Future<void> _getLocations() async {
    // logger.i(widget.trip);
    List<LatLng> tempLocations = [];
    
    try {
      final startCoordinates =
          await _getCoordinates(widget.trip['start_address']);
      if (startCoordinates != null) {
        startPoint = startCoordinates;
      }
    } catch (e) {
      logger.e('Failed to fetch start address coordinates: $e');
    }

    if (widget.trip['stop_locations'] != null) {
      try {
        final stopLocations =
            List<Map<String, dynamic>>.from(widget.trip['stop_locations']);
        for (var location in stopLocations) {
          final latitude = double.parse(location['latitude'].toString());
          final longitude = double.parse(location['longitude'].toString());
          tempLocations.add(LatLng(latitude, longitude));
        }
        droppins = widget.trip['droppins'];
      } catch (e) {
        logger.e('Failed to process stop locations: $e');
      }
    }

    try {
      final destinationCoordinates =
          await _getCoordinates(widget.trip['destination_address']);
      if (destinationCoordinates != null) {
        endPoint = destinationCoordinates;
      }
    } catch (e) {
      logger.e('Failed to fetch destination address coordinates: $e');
    }

    setState(() {
      locations = tempLocations;
      if (tempLocations.isNotEmpty) {
        lastDropPoint = tempLocations.last;
      }
    });
    _adjustZoom();
  }

  void _adjustZoom() {
    if (lastDropPoint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bounds = LatLngBounds(
          LatLng(lastDropPoint!.latitude - 0.03, lastDropPoint!.longitude - 0.03),
          LatLng(lastDropPoint!.latitude + 0.03, lastDropPoint!.longitude + 0.03), 
        );

        final center = bounds.center;

        mapController.move(center, 12.0); 
      });
    }
  }

  String get mapStyleUrl {
    const accessToken =
        'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw';
    final styleId = () {
      final style = widget.trip['map_style'];
      // logger.i(style);
      switch (style) {
        case "1":
          return 'satellite-v9';
        case "2":
          return 'light-v10';
        case "3":
          return 'dark-v10';
        case '0':
        case null:
        default:
          return 'streets-v11';
      }
    }();

    return "https://api.mapbox.com/styles/v1/mapbox/$styleId/tiles/{z}/{x}/{y}?access_token=$accessToken";
  }

  void _onSelectTrip() {
    setState(() {
      _isSelected = !_isSelected; 
      if (_isSelected) {
        widget.onSelectTrip(widget.trip['id']); 
      } else {
        widget.onSelectTrip(widget.trip['id']); 
      }
    });
  }

  void _onMapTap() {
    GlobalVariables.homeTripID = widget.trip['id'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: isLoading
          ? const Center(child: SpinningLoader())
          : Stack(
              children: [
                Opacity(
                  opacity: widget.isSelectMode ? 0.5 : 1.0,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: lastDropPoint ?? startPoint ?? const LatLng(37.7749, -122.4194),
                      initialZoom: 12,
                      onTap: (_, LatLng position) {
                        if (widget.isSelectMode == false) {
                            _onMapTap();
                          }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: mapStyleUrl,
                        additionalOptions: const {
                          'access_token':
                              'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw',
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          ...locations.map((location) {
                            return Marker(
                              width: 20.0,
                              height: 20.0,
                              point: location,
                              child: Container(
                                width: 12, 
                                height: 12, 
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: kColorBlack,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      spreadRadius: 0.5,
                                      blurRadius: 6,
                                      offset: const Offset(-3, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    // '${locations.indexOf(location) + 1}',
                                    '${droppins[locations.indexOf(location)]['stop_index']}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      // Polyline layer for the route
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                widget.isSelectMode ?
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: GestureDetector(
                      onTap: _onSelectTrip,
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: _isSelected ? Colors.black : Colors.white,
                          border: Border.all(color: Colors.black),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ) : const SizedBox.square(),
              ],
            ),
    );
  }
}
