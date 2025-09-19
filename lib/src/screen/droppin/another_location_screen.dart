// import 'package:RollaTravel/src/screen/droppin/select_locaiton_screen.dart';
// import 'package:RollaTravel/src/screen/droppin/choosen_location_screen.dart';
import 'package:RollaTravel/src/screen/droppin/select_locaiton_screen.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AnotherLocationScreen extends ConsumerStatefulWidget {
  final LatLng? location;
  final String caption;
  final String imagePath;
  const AnotherLocationScreen(
      {super.key,
      required this.caption,
      required this.imagePath,
      required this.location});
  @override
  ConsumerState<AnotherLocationScreen> createState() =>
      AnotherLocationScreenState();
}

class AnotherLocationScreenState extends ConsumerState<AnotherLocationScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 3;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  final logger = Logger();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  static const String mapboxAccessToken =
      "pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw";

  final List<String> _mapStyles = [
    "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken",
    "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken",
    "https://api.mapbox.com/styles/v1/mapbox/light-v10/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken",
    "https://api.mapbox.com/styles/v1/mapbox/dark-v10/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (mounted) {
        setState(() {
          this.keyboardHeight = keyboardHeight;
        });
      }
    });
    _checkLocationServices();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        logger.i("_currentLocation: $_currentLocation");
        _isLoading = false; // Stop loading
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            try {
              _mapController.move(_currentLocation!, 12.0);
            } catch (e) {
              logger.e("Error moving map: $e");
            }
          }
        });
      });
      return;
    } 
     if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.i("Location permission denied.");
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.i("Location permission permanently denied.");
      _showPermissionDeniedDialog();
      return;
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
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkLocationServices() async {
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!isLocationEnabled) {
      logger.e("Location services are disabled!");
      _showLocationDisabledDialog();
      return;
    }

    // ✅ If permission is denied, request it
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.e("Location permission denied!");
        _showPermissionDeniedDialog();
        return;
      }
    }

    // ✅ If permission is permanently denied, open settings
    if (permission == LocationPermission.deniedForever) {
      logger.e("Location permission permanently denied!");
      _showPermissionDeniedDialog();
      return;
    }

    // ✅ If everything is enabled, log success
    logger.i("Location services and permissions are enabled.");
  }

  void _showLocationDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Services Disabled"),
          content: const Text(
            "Please enable location services to track your movement.",
          ),
          actions: [
            TextButton(
              child: const Text("Open Settings"),
              onPressed: () async {
                await Geolocator.openLocationSettings(); // ✅ Opens GPS settings
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
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

  Future<List<String>> fetchAddressSuggestions(String query) async {
    final response = await http.get(
      Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List features = (data['features'] ?? []) as List;
      return features
          .map((feature) => feature['place_name'] as String)
          .toList();
    } else {
      debugPrint('API Error: ${response.statusCode} - ${response.body}');
      return [];
    }
  }

  

  Future<void> _moveMarkerToAddress(String address) async {
    final response = await http.get(
      Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$address.json?access_token=$mapboxAccessToken'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      if (features.isNotEmpty) {
        final location = features.first['geometry']['coordinates'];
        final latLng = LatLng(location[1], location[0]);

        setState(() {
          _selectedLocation = latLng;
          logger.i("Selected location: $_selectedLocation");
        });

        // Move the map, then force rebuild after a short delay
        _mapController.move(latLng, 13.0);

        // Force redraw after slight delay to avoid blank tiles
        await Future.delayed(const Duration(milliseconds: 300));
        _mapController.move(latLng, 13.0); // Re-move to same point
      }
    } else {
      throw Exception('Failed to load location');
    }
  }


  Future<void> _updateAddressFromLocation(LatLng location) async {
    final response = await http.get(
      Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${location.longitude},${location.latitude}.json?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      if (features.isNotEmpty) {
        final address = features.first['place_name'];
        setState(() {
          _searchController.text = address;
        });
      }
    } else {
      throw Exception('Failed to load address');
    }
  }

  void _onChooseLocation() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectLocationScreen(
                  caption: widget.caption,
                  imagePath: widget.imagePath,
                  selectedLocation: _selectedLocation,
                )));
    // logger.i("Selected location: $_selectedLocation");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        canPop: false, // Prevents popping by default
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return; // Prevent pop action
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    SizedBox(height: vhh(context, 5)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/images/icons/logo.png',
                            width: 90,
                            height: 80,),
                        IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the screen
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                      children: [
                        const Icon(Icons.search, size: 24, color: Colors.black),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 35,
                          width: vww(context, 84),
                          child: TypeAheadFormField(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Search Locations",
                                hintStyle: const TextStyle(
                                    fontSize: 15,
                                    fontFamily:'inter'),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0.0,
                                    horizontal: 16.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: const BorderSide(
                                      color: Colors.black, width: 1.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: const BorderSide(
                                      color: Colors.black, width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: const BorderSide(
                                      color: Colors.black, width: 1.0),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontFamily:'inter'), 
                            ),
                            suggestionsCallback: (pattern) async {
                              return await fetchAddressSuggestions(pattern);
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (suggestion) {
                              _searchController.text = suggestion;
                              _moveMarkerToAddress(suggestion);
                            },
                          ),
                        ),
                      ],
                    ),),
                    
                    SizedBox(
                      height: vhh(context, 1),
                    ),

                    _isLoading
                        ? const Center(
                            child: SpinningLoader(), 
                          )
                        : SizedBox(
                            height: vhh(context, 62),
                            width: vww(context, 98),
                            child: Center(
                                child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _currentLocation ??
                                        const LatLng(37.7749, -122.4194),
                                    initialZoom: 12.0,
                                    onTap: (tapPosition, point) {
                                      setState(() {
                                        _selectedLocation = point;
                                      });
                                      _updateAddressFromLocation(point);
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: _mapStyles[
                                        GlobalVariables.mapStyleSelected],
                                      additionalOptions: const {
                                        'access_token':
                                            'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw',
                                      },
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        if (_selectedLocation != null)
                                          Marker(
                                            width: 60.0,
                                            height: 60.0,
                                            point: _selectedLocation!,
                                            child: GestureDetector(
                                              // onTap: () => _selectMarker(_selectedLocation!),
                                              child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 30),
                                            ),
                                          )
                                        else if (_currentLocation != null)
                                          Marker(
                                            width: 60.0,
                                            height: 60.0,
                                            point: _currentLocation!,
                                            child: GestureDetector(
                                              // onTap: () => _selectMarker(_currentLocation!),
                                              child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 30),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 10,
                                  top: 70,
                                  child: Column(
                                    children: [
                                      FloatingActionButton(
                                        heroTag:'zoom_in_button_otherlocation',
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
                                        heroTag:'zoom_out_button_otherlocation', 
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
                                Positioned(
                                  top: 5,
                                  left: 0,
                                  right: 0,
                                  child: Padding(
                                    padding:EdgeInsets.zero,
                                    child: Container(
                                      padding: const EdgeInsets.all(5.0),
                                      color:Colors.white.withValues(alpha: 0.5),
                                      child: Text(
                                        'Search or tap on the map where you want to \ndrop a pin',
                                        style: TextStyle(
                                            color: Colors.black.withValues(alpha: 0.9),
                                            fontSize: 14,
                                            letterSpacing: -0.43,
                                            fontFamily: 'inter'),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 15,
                                  left: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      _onChooseLocation();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal:20), 
                                      padding: const EdgeInsets.all(8.0), 
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha:0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Choose this location',
                                        style: TextStyle(
                                          color: Colors.black.withValues(alpha:0.95), 
                                          fontSize: 14,
                                          fontFamily: 'interBold',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
