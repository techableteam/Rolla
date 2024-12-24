import 'package:RollaTravel/src/constants/app_button.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/home/home_follower_screen.dart';
import 'package:RollaTravel/src/screen/profile/edit_profile.dart';
import 'package:RollaTravel/src/screen/settings/settings_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 4;
  bool isLiked = false;
  bool showLikesDropdown = false;
  String? followingCount;

  final logger = Logger();

  List<Map<String, dynamic>>? userTrips;
  bool isLoadingTrips = true;

  LatLng? startPoint;
  LatLng? endPoint;
  List<LatLng> locations = [];

  @override
  void initState() {
    super.initState();
    _loadUserTrips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (mounted) {
        setState(() {
          this.keyboardHeight = keyboardHeight;
        });
      }
    });
    if (GlobalVariables.followingIds != null &&
        GlobalVariables.followingIds!.isNotEmpty) {
      int count = GlobalVariables.followingIds!.split(',').length;
      followingCount = count.toString();
    }
  }

  Future<void> _loadUserTrips() async {
    try {
      final apiService = ApiService();
      final trips = await apiService.fetchUserTrips(GlobalVariables.userId!);
      setState(() {
        userTrips = trips;
        isLoadingTrips = false;
      });
      if (userTrips != null && userTrips!.isNotEmpty) {}
    } catch (error) {
      logger.e('Error fetching user trips: $error');
      setState(() {
        userTrips = [];
        isLoadingTrips = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  void _onFollowers() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const HomeFollowScreen()));
  }

  void _showImageDialog(
      String imagePath, String caption, int likes, List<dynamic> likedUsers) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption and Close Icon Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          caption,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontFamily: 'Kadaw',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              showLikesDropdown =
                                  false; // Hide the dropdown when the dialog is closed
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Image
                  Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.5,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
                  ),
                  const Divider(
                      height: 1,
                      color: Colors.grey), // Divider between image and footer
                  // Footer with Like Icon and Likes Count
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              isLiked = !isLiked;
                            });
                          },
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showLikesDropdown =
                                  !showLikesDropdown; // Toggle the visibility of the dropdown
                            });
                          },
                          child: Text(
                            '$likes likes',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Kadaw',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showLikesDropdown)
                    Column(
                      children: likedUsers.map((user) {
                        final photo = user['photo'] ?? '';
                        final firstName = user['first_name'] ?? 'Unknown';
                        final lastName = user['last_name'] ?? '';
                        final username = user['rolla_username'] ?? '@unknown';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              // User Profile Picture
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 2,
                                  ),
                                  image: photo.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(photo),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: photo.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 20) // Placeholder icon
                                    : null,
                              ),
                              const SizedBox(width: 5),
                              // User Information
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$firstName $lastName',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFamily: 'Kadaw',
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontFamily: 'Kadaw',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: kColorWhite,
            ),
            padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: vhh(context, 5)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/icons/logo.png',
                      width: vww(context, 20),
                    ),
                    SizedBox(width: vww(context, 20)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          GlobalVariables.userName!,
                          style: const TextStyle(
                              color: kColorBlack,
                              fontSize: 18,
                              fontFamily: 'KadawBold'),
                        ),
                        Image.asset(
                          'assets/images/icons/verify.png',
                          width: vww(context, 10),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: vhh(context, 1)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(),
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/icons/trips.png',
                          width: vww(context, 15),
                        ),
                        Text(
                          GlobalVariables.tripCount != null
                              ? GlobalVariables.tripCount!.toString()
                              : "0",
                          style: const TextStyle(
                              fontSize: 20,
                              color: kColorButtonPrimary,
                              fontFamily: 'KadawBold'),
                        ),
                      ],
                    ),
                    Container(
                      height: vhh(context, 15),
                      width: vhh(context, 15),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: kColorHereButton,
                            width: 2,
                          ),
                          image: GlobalVariables.userImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(GlobalVariables
                                      .userImageUrl!), // Use NetworkImage for URL
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/icons/followers.png',
                          width: vww(context, 15),
                        ),
                        GestureDetector(
                          onTap: () {
                            _onFollowers();
                          },
                          child: Text(
                            followingCount != null ? followingCount! : "0",
                            style: const TextStyle(
                                fontSize: 20,
                                color: kColorButtonPrimary,
                                fontFamily: 'KadawBold'),
                          ),
                        ),
                      ],
                    ),
                    Container(),
                  ],
                ),
                SizedBox(height: vhh(context, 1)),
                Text(
                  GlobalVariables.realName!,
                  style: const TextStyle(
                      color: kColorBlack,
                      fontSize: 20,
                      fontFamily: 'KadawBold'),
                ),
                SizedBox(height: vhh(context, 1)),

                Text(
                  GlobalVariables.bio != null ? GlobalVariables.bio! : " ",
                  style: const TextStyle(
                      color: kColorGrey, fontSize: 18, fontFamily: 'Kadaw'),
                ),
                SizedBox(height: vhh(context, 2)),
                Row(
                  children: [
                    SizedBox(
                      width: vww(context, 30),
                      child: ButtonWidget(
                        btnType: ButtonWidgetType.editProfileText,
                        borderColor: kColorStrongGrey,
                        textColor: kColorWhite,
                        fullColor: kColorStrongGrey,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ));
                        },
                      ),
                    ),
                    SizedBox(width: vww(context, 1)),
                    SizedBox(
                      width: vww(context, 30),
                      child: ButtonWidget(
                        btnType: ButtonWidgetType.followingText,
                        borderColor: kColorStrongGrey,
                        textColor: kColorWhite,
                        fullColor: kColorStrongGrey,
                        onPressed: () {
                          _onFollowers();
                        },
                      ),
                    ),
                    SizedBox(width: vww(context, 1)),
                    SizedBox(
                      width: vww(context, 30),
                      child: ButtonWidget(
                        btnType: ButtonWidgetType.settingText,
                        borderColor: kColorStrongGrey,
                        textColor: kColorWhite,
                        fullColor: kColorStrongGrey,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ));
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: vhh(context, 1)),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          odometer,
                          style: TextStyle(
                              color: kColorBlack,
                              fontSize: 14,
                              fontFamily: 'Kadaw'),
                        ),
                        Text(
                          GlobalVariables.odometer != null
                              ? '${GlobalVariables.odometer!} Km'
                              : ' ',
                          style: const TextStyle(
                              color: kColorButtonPrimary,
                              fontSize: 14,
                              fontFamily: 'Kadaw'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          happy_place,
                          style: TextStyle(
                              color: kColorBlack,
                              fontSize: 14,
                              fontFamily: 'Kadaw'),
                        ),
                        Text(
                          GlobalVariables.happyPlace != null
                              ? GlobalVariables.happyPlace!
                              : " ",
                          style: const TextStyle(
                              color: kColorButtonPrimary,
                              fontSize: 14,
                              fontFamily: 'Kadaw'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          my_garage,
                          style: TextStyle(
                              color: kColorBlack,
                              fontSize: 14,
                              fontFamily: 'Kadaw'),
                        ),
                        GlobalVariables.garageLogoUrl != null
                            ? Image.network(
                                GlobalVariables.garageLogoUrl!,
                                width: 25, // Adjust width as needed
                                height: 25, // Adjust height as needed
                              )
                            : const Text(""),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: vhh(context, 1)),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: GlobalVariables.dropPinsData?.length ?? 0,
                    itemBuilder: (context, index) {
                      final dropPin = GlobalVariables.dropPinsData![index]
                          as Map<String, dynamic>;

                      final String imagePath = dropPin['image_path'] ?? '';
                      final String caption =
                          dropPin['image_caption'] ?? 'No caption';
                      final List<dynamic> likedUsers =
                          dropPin['liked_users'] ?? [];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () {
                            // Handle the click event
                            _showImageDialog(imagePath, caption,
                                dropPin['liked_users'].length, likedUsers);
                          },
                          child: imagePath.isNotEmpty
                              ? Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.5),
                                        Colors.transparent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  child: Image.network(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        // Image has loaded successfully
                                        return child;
                                      } else {
                                        // Display a loading indicator while the image is loading
                                        return Center(
                                          child: CircularProgressIndicator(
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
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback widget in case of an error
                                      return const Icon(Icons.broken_image,
                                          size: 100);
                                    },
                                  ),
                                )
                              : const Icon(Icons.image_not_supported,
                                  size: 100),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: vhh(context, 1)),
                // Map and Route Section with Dividers
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      const Divider(
                        height: 1,
                        thickness: 2,
                        color: Colors.blue,
                      ),
                      SizedBox(height: vhh(context, 2)),
                      userTrips == null
                          ? const Center(child: CircularProgressIndicator())
                          : userTrips!.isEmpty
                              ? const Center(child: Text("No trips to display"))
                              : Column(
                                  children: List.generate(
                                    (userTrips!.length / 2).ceil(),
                                    (rowIndex) => Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.4,
                                              height: 150,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 2,
                                                ),
                                              ),
                                              child: TripMapWidget(
                                                trip: userTrips![rowIndex * 2],
                                                index: rowIndex * 2,
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                              height: 150,
                                              child: const VerticalDivider(
                                                width: 2,
                                                thickness: 2,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            if (rowIndex * 2 + 1 <
                                                userTrips!.length)
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.4,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: TripMapWidget(
                                                  trip: userTrips![
                                                      rowIndex * 2 + 1],
                                                  index: rowIndex * 2 + 1,
                                                ),
                                              ),
                                            if (rowIndex * 2 + 1 >=
                                                userTrips!.length)
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.4),
                                          ],
                                        ),
                                        if (rowIndex <
                                            (userTrips!.length / 2).ceil() - 1)
                                          Column(
                                            children: [
                                              SizedBox(height: vhh(context, 1)),
                                              const Divider(
                                                height: 1,
                                                thickness: 2,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: vhh(context, 1)),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                    ],
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

// Create a new StatefulWidget for trip maps
class TripMapWidget extends StatefulWidget {
  final Map<String, dynamic> trip;
  final int index;

  const TripMapWidget({
    super.key,
    required this.trip,
    required this.index,
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
  bool isLoading = true;
  final logger = Logger();

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
          return LatLng(
              coordinates[1], coordinates[0]); // [lng, lat] to LatLng(lat, lng)
        }
      }
      return null;
    } catch (e) {
      logger.e('Error getting coordinates: $e');
      return null;
    }
  }

  Future<void> _getLocations() async {
    List<LatLng> tempLocations = [];

    try {
      // Fetch Start Address
      final startCoordinates =
          await _getCoordinates(widget.trip['start_address']);
      if (startCoordinates != null) {
        startPoint = startCoordinates;
      }
    } catch (e) {
      logger.e('Failed to fetch start address coordinates: $e');
    }

    // Use Stop Locations directly
    if (widget.trip['stop_locations'] != null) {
      try {
        final stopLocations =
            List<Map<String, dynamic>>.from(widget.trip['stop_locations']);
        for (var location in stopLocations) {
          final latitude = double.parse(location['latitude'].toString());
          final longitude = double.parse(location['longitude'].toString());
          tempLocations.add(LatLng(latitude, longitude));
        }
      } catch (e) {
        logger.e('Failed to process stop locations: $e');
      }
    }

    // Fetch Destination Address
    try {
      final destinationCoordinates =
          await _getCoordinates(widget.trip['destination_address']);
      if (destinationCoordinates != null) {
        endPoint = destinationCoordinates;
      }
    } catch (e) {
      logger.e('Failed to fetch destination address coordinates: $e');
    }

    if (mounted) {
      setState(() {
        locations = tempLocations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 10),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter:
                        startPoint != null ? startPoint! : const LatLng(0, 0),
                    initialZoom: 14.0,
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
                        if (startPoint != null)
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: startPoint!,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                        if (endPoint != null)
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: endPoint!,
                            child: const Icon(Icons.location_on,
                                color: Colors.green, size: 40),
                          ),
                        ...locations.map((location) {
                          return Marker(
                            width: 80.0,
                            height: 80.0,
                            point: location,
                            child: const Icon(Icons.location_on,
                                color: Colors.blue, size: 40),
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
                // ... Zoom controls
              ],
            ),
    );
  }
}
