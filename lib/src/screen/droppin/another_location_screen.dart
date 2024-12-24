// import 'package:RollaTravel/src/screen/droppin/select_locaiton_screen.dart';
import 'package:RollaTravel/src/screen/droppin/choosen_location_screen.dart';
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
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  Future<void> _getCurrentLocation() async {
    logger.i("Checking location permission...");

    final permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      // Permission granted, fetch current location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        logger.i("_currentLocation: $_currentLocation");
      });
      _mapController.move(_currentLocation!, 13.0);
    } else if (permissionStatus.isDenied ||
        permissionStatus.isPermanentlyDenied) {
      // Permission denied - prompt user to open settings
      logger.i("Location permission denied. Redirecting to settings.");
      _showPermissionDeniedDialog();
    } else {
      logger.i("Location permission status: $permissionStatus");
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
                await openAppSettings(); // This will open app settings
                if (mounted) {
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

  // void _selectMarker(LatLng location){
  //   Navigator.push(context, MaterialPageRoute(builder: (context) => SelectLocationScreen(selectedLocation: location,)));
  // }

  Future<List<String>> fetchAddressSuggestions(String query) async {
    final response = await http.get(
      Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      return features
          .map((feature) => feature['place_name'] as String)
          .toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<void> _moveMarkerToAddress(String address) async {
    final response = await http.get(
      Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$address.json?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw'),
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
        _mapController.move(latLng, 13.0);
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
            builder: (context) => ChoosenLocationScreen(
                  caption: widget.caption,
                  imagePath: widget.imagePath,
                  location: _selectedLocation,
                )));
    logger.i("Selected location: $_selectedLocation");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    // Logo and close button aligned at the top
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/images/icons/logo.png',
                              height: vhh(context, 12)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 30),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the screen
                            },
                          ),
                        ],
                      ),
                    ),

                    //Search input text field
                    Row(
                      children: [
                        const Icon(Icons.search, size: 24, color: Colors.black),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 35,
                          width: vww(context, 86),
                          child: TypeAheadFormField(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Search Locations",
                                hintStyle: const TextStyle(
                                    fontSize: 16,
                                    fontFamily:
                                        'Kadaw'), // Set font size for hint text
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0.0,
                                    horizontal: 16.0), // Set inner padding
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
                                  fontSize: 14,
                                  fontFamily:
                                      'Kadaw'), // Set font size for input text
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
                    ),
                    SizedBox(
                      height: vhh(context, 1),
                    ),
                    //Flutter map widget
                    SizedBox(
                      height: vhh(context, 65),
                      width: vww(context, 96),
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
                                urlTemplate:
                                    "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw",
                                additionalOptions: const {
                                  'access_token':
                                      'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw',
                                },
                              ),
                              MarkerLayer(
                                markers: [
                                  if (_selectedLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: _selectedLocation!,
                                      child: GestureDetector(
                                        // onTap: () => _selectMarker(_selectedLocation!),
                                        child: const Icon(Icons.location_on,
                                            color: Colors.red, size: 40),
                                      ),
                                    )
                                  else if (_currentLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: _currentLocation!,
                                      child: GestureDetector(
                                        // onTap: () => _selectMarker(_currentLocation!),
                                        child: const Icon(Icons.location_on,
                                            color: Colors.red, size: 40),
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
                                  heroTag:
                                      'zoom_in_button_otherlocation', // Unique tag for the zoom in button
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
                                      'zoom_out_button_otherlocation', // Unique tag for the zoom out button
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
                              padding: EdgeInsets.zero, // Adjust for width
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                color: Colors.white.withOpacity(0.5),
                                child: Text(
                                  'Search or double tap on the map \nwhere you want ot drop pin',
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.9),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'Kadaw'),
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
                                margin: const EdgeInsets.symmetric(
                                    horizontal:
                                        20), // Spacing from screen edges
                                padding: const EdgeInsets.all(
                                    8.0), // Adjust padding for content
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                      0.9), // Semi-transparent background
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded corners
                                ),
                                child: Text(
                                  'Choose this location',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.95),
                                    fontSize: 14,
                                    fontFamily: 'KadawBold',
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
