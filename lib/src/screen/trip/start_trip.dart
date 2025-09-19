import 'dart:convert';
import 'package:RollaTravel/src/constants/app_button.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/droppin/drop_pin.dart';
import 'package:RollaTravel/src/screen/droppin/limit_trip_screen.dart';
import 'package:RollaTravel/src/screen/droppin/photo_select_screen.dart';
import 'package:RollaTravel/src/screen/trip/end_trip.dart';
import 'package:RollaTravel/src/screen/trip/sound_screen.dart';
import 'package:RollaTravel/src/screen/trip/trip_settting_screen.dart';
import 'package:RollaTravel/src/screen/trip/trip_tag_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/common.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/utils/location.permission.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:RollaTravel/src/utils/stop_marker_provider.dart';
import 'package:RollaTravel/src/utils/trip_marker_provider.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  String initialSound = "Edit Playlist";
  double totalDistanceInMiles = 0;
  List<LatLng> pathCoordinates = [];
  bool isStateRestored = false;
  bool _isLoading = false;
  String? startAddress;
  String? endAddress;
  String stopAddressesString = "";
  List<String> formattedStopAddresses = [];
  final FocusNode _captionFocusNode = FocusNode();
  final uuid = const Uuid();
  int _currentLength = 0;
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
    _captionController.addListener(_updateTextLength);
    _getFetchTripData();
    _checkLocationServices();
    if (GlobalVariables.tripCaption != null) {
      _captionController.text = GlobalVariables.tripCaption!;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
    _positionStreamSubscription?.cancel();
    _captionController.removeListener(_updateTextLength);
    _captionFocusNode.dispose();
    _captionController.dispose();
  }

  void _updateTextLength() {
    setState(() {
      _currentLength = _captionController.text.length;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _getFetchTripData() async {
    final prefs = await SharedPreferences.getInstance();
    int? tripId = prefs.getInt("tripId");
    // logger.i("saved tripid : $tripId");
    if (tripId != null) {
      final apiserice = ApiService();
      try {
        _showLoadingDialog();
        final tripData = await apiserice.fetchTripData(tripId);
        // logger.i(tripData);
        if ((tripData['trips'] as List).isEmpty) {
          logger.i("no trip in server");
          _hideLoadingDialog();
          ref.read(tripMarkersProvider.notifier).state = [];
          GlobalVariables.isTripStarted = false;
          GlobalVariables.droppinCount = 0;
          ref.read(isTripStartedProvider.notifier).state = false;
          await prefs.remove("tripId");
          await prefs.remove("dropcount");
          await prefs.remove("destination_text");
          await prefs.remove("start_date");
          await prefs.remove("caption_text");
          _getCurrentLocation();
        } else {
          ref.read(tripMarkersProvider.notifier).state = [];
          GlobalVariables.isTripStarted = true;
          ref.read(isTripStartedProvider.notifier).state = true;
          String? destinationText = prefs.getString('destination_text');
          if (destinationText != null) {
            ref.read(isTripStartedProvider.notifier).state = true;
            GlobalVariables.editDestination = destinationText;
            GlobalVariables.tripStartDate = prefs.getString('start_date');
            GlobalVariables.tripCaption = prefs.getString('caption_text');
          }

          var destinationTextAddress =
              tripData['trips'][0]['destination_text_address'];
          if (tripData['trips'][0]['trip_caption'] != null &&
              tripData['trips'][0]['trip_caption'] != "null") {
            _captionController.text = tripData['trips'][0]['trip_caption'];
          }
          if (destinationTextAddress is String) {
            destinationTextAddress = jsonDecode(destinationTextAddress);
          }
          if (tripData['trip_tags'] != null &&
              tripData['trip_tags'] != "null") {
            try {
              List<int> tags =
                  List<int>.from(jsonDecode(tripData['trip_tags']));
              GlobalVariables.selectedUserIds.addAll(tags);
              logger.i(GlobalVariables.selectedUserIds);
            } catch (e) {
              logger.i('Error parsing trip_tags: $e');
            }
          }
          List<String> songs = tripData['trips'][0]['trip_sound'].split(',');

          GlobalVariables.song1 = songs.isNotEmpty ? songs[0].trim() : null;
          GlobalVariables.song2 = songs.length > 1 ? songs[1].trim() : null;
          GlobalVariables.song3 = songs.length > 2 ? songs[2].trim() : null;
          GlobalVariables.song4 = songs.length > 3 ? songs[3].trim() : null;

          GlobalVariables.editDestination = destinationTextAddress[0];

          GlobalVariables.tripStartDate =
              tripData['trips'][0]['trip_start_date'];
          List stopLocations = tripData['trips'][0]['stop_locations'];
          List droppins = tripData['trips'][0]['droppins'];

          List<TripMarkerData> markers = [];

          stopLocations.asMap().forEach((i, stop) {
            if (stop is Map &&
                stop.containsKey('latitude') &&
                stop.containsKey('longitude')) {
              double latitude = stop['latitude'];
              double longitude = stop['longitude'];

              String imagePath = "";
              String caption = "Trip Stop";
              String delayTime = "";

              var droppin = droppins.firstWhere(
                (d) => d['stop_index'] == (i + 1),
                orElse: () => null,
              );

              if (droppin != null) {
                imagePath = droppin['image_path'] ?? "";
                caption = droppin['image_caption'] ?? "No caption";
                delayTime = droppin['deley_time'];
              }

              TripMarkerData marker = TripMarkerData(
                  location: LatLng(latitude, longitude),
                  imagePath: imagePath,
                  caption: caption,
                  delayTime: delayTime);
              markers.add(marker);
            }
          });
          ref.read(tripMarkersProvider.notifier).state = markers;
          GlobalVariables.droppinCount = markers.length;
          // logger.i(GlobalVariables.droppinCount);

          var startLocation = tripData['trips'][0]['start_location'];
          if (startLocation is String) {
            RegExp regExp = RegExp(
                r'LatLng\((latitude:([0-9.-]+), longitude:([0-9.-]+))\)');
            Match? match = regExp.firstMatch(startLocation);

            if (match != null) {
              double latitude = double.tryParse(match.group(2) ?? "0.0") ?? 0.0;
              double longitude =
                  double.tryParse(match.group(3) ?? "0.0") ?? 0.0;
              LatLng startLatLng = LatLng(latitude, longitude);
              ref.read(staticStartingPointProvider.notifier).state ??=
                  startLatLng;
              setState(() {
                isStateRestored = true;
              });
            } else {
              logger.e("Failed to parse start location string");
              setState(() {
                isStateRestored = true;
              });
            }
          }
          _hideLoadingDialog();
        }
      } catch (e) {
        logger.e("Error fetching trip data: $e");
      } finally {
        _hideLoadingDialog();
      }
    } else {
      ref.read(tripMarkersProvider.notifier).state = [];
      setState(() {
        isStateRestored = true;
      });
      if (PermissionService().hasLocationPermission) {
        _getCurrentLocation();
      }
      logger.w("No tripId found in local database");
    }
  }

  void _showLoadingDialog() {
    setState(() {
      _isLoading = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SpinningLoader(),
              SizedBox(width: 20),
              Text("Loading..."),
            ],
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (_isLoading) {
      Navigator.of(context).pop();
      setState(() {
        _isLoading = false;
      });
    }
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
                await Geolocator.openLocationSettings();
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

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        ref.read(staticStartingPointProvider.notifier).state ??=
            currentLocation;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && currentLocation != null) {
          try {
            // Only move the map if the controller is ready
            _mapController.move(currentLocation!, 12.0);
          } catch (e) {
            logger.e("Error moving map: $e");
          }
        }
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

  void toggleTrip() {
    if (GlobalVariables.isTripStarted) {
      // ✅ End the trip
      sendTripData();
    } else {
      // ✅ Start the trip
      // _startTrip();
      _noTrackingStartTrip();
    }
  }

  void droppinClicked () {
    logger.i(GlobalVariables.isTripStarted);
    if (!GlobalVariables.isTripStarted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DropPinScreen()));
    } else {
      if (GlobalVariables.droppinCount > 6) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LimitDropPinScreen()));
      } else {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PhotoSelectScreen()));
      }
    }
  }

  Future<void> _noTrackingStartTrip() async {
    if (GlobalVariables.editDestination == null) {
      _showDestinationAlert(context);
      return;
    }
    GlobalVariables.isTripStarted = true;
    ref.read(isTripStartedProvider.notifier).state = true;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    GlobalVariables.tripStartDate = formattedDate;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('destination_text', GlobalVariables.editDestination!);
    await prefs.setString('start_date', formattedDate);
    if (GlobalVariables.tripCaption != null) {
      await prefs.setString('caption_text', GlobalVariables.tripCaption!);
    }
  }

  void _showDestinationAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Destination Required"),
          content: const Text(
              "Please enter the destination before starting the trip."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendTripData() async {
    _showLoadingDialog();
    final apiserice = ApiService();
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    LatLng? startLocation = ref.read(staticStartingPointProvider);
    LatLng? endLocation = LatLng(position.latitude, position.longitude);
    List<TripMarkerData> stopMarkers = ref.read(tripMarkersProvider);
    // logger.i("stopmakers : $stopMarkers");
    await _fetchAddresses(startLocation, endLocation, stopMarkers);

    final tripCoordinates = ref
        .read(pathCoordinatesProvider)
        .map((latLng) => {
              'latitude': latLng.latitude,
              'longitude': latLng.longitude,
            })
        .toList();

    if (stopMarkers.isEmpty) {
      _hideLoadingDialog();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Warning"),
            content: const Text(
                "You need to add at least one stop marker (drop pin) before ending the trip."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    GlobalVariables.tripEndDate = formattedDate;

    String tripMiles =
        "${GlobalVariables.totalDistance.toStringAsFixed(3)} miles";

    final stopLocations = stopMarkers
        .map((marker) => {
              'latitude': marker.location.latitude,
              'longitude': marker.location.longitude,
            })
        .toList();

    String formattedDestination = '["${GlobalVariables.editDestination}"]';

    final prefs = await SharedPreferences.getInstance();
    int? tripId = prefs.getInt("tripId");

    List<String> songs = [
      if (GlobalVariables.song1 != null && GlobalVariables.song1!.isNotEmpty)
        GlobalVariables.song1!,
      if (GlobalVariables.song2 != null && GlobalVariables.song2!.isNotEmpty)
        GlobalVariables.song2!,
      if (GlobalVariables.song3 != null && GlobalVariables.song3!.isNotEmpty)
        GlobalVariables.song3!,
      if (GlobalVariables.song4 != null && GlobalVariables.song4!.isNotEmpty)
        GlobalVariables.song4!
    ];
    String arrangedSongs = songs.join(',');
    if (GlobalVariables.delaySetting == 0) {
      final response = await apiserice.updateTrip(
          tripId: tripId!,
          userId: GlobalVariables.userId!,
          startAddress: startAddress!,
          stopAddresses: stopAddressesString,
          destinationAddress: endAddress!,
          destinationTextAddress: formattedDestination,
          tripStartDate: GlobalVariables.tripStartDate!,
          tripEndDate: GlobalVariables.tripEndDate!,
          tripCaption: GlobalVariables.tripCaption ?? "",
          tripTag: GlobalVariables.selectedUserIds.toString(),
          tripMiles: tripMiles,
          tripSound: arrangedSongs,
          stopLocations: stopLocations,
          tripCoordinates: tripCoordinates,
          startLocation: startLocation.toString(),
          destinationLocation: endLocation.toString(),
          droppins: [],
          mapStyle: GlobalVariables.mapStyleSelected.toString());

      if (!mounted) return;

      if (response['success'] == true) {
        logger.i(response);
        await prefs.remove("tripId");
        await prefs.remove("dropcount");
        await prefs.remove("destination_text");
        await prefs.remove("start_date");
        await prefs.remove("caption_text");
        String jsonStr = response['trip']['destination_text_address'] ?? '[]';

        // Parse it to a List<String>
        List<dynamic> parsedList = [];
        try {
          parsedList = jsonDecode(jsonStr);
        } catch (e) {
          logger.e("Failed to parse destination_text_address: $e");
        }

        // Extract first element or empty string if list is empty
        String destination =
            parsedList.isNotEmpty ? parsedList[0].toString() : "";

        _hideLoadingDialog();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EndTripScreen(
              startLocation: startLocation,
              endLocation: endLocation,
              stopMarkers: stopMarkers,
              tripStartDate: GlobalVariables.tripStartDate!,
              tripEndDate: GlobalVariables.tripEndDate!,
              endDestination: destination,
              tripSound: response['trip']['trip_sound'],
            ),
          ),
        );
        ref.read(isTripStartedProvider.notifier).state = false;
        GlobalVariables.isTripStarted = false;
        ref.read(staticStartingPointProvider.notifier).state =
            ref.read(movingLocationProvider);
        ref.read(movingLocationProvider.notifier).state = null;
        ref.read(markersProvider.notifier).state = [];
        ref.read(totalDistanceProvider.notifier).state = 0.0;
        GlobalVariables.totalDistance = 0.0;
        GlobalVariables.tripCaption = null;
        GlobalVariables.song1 = null;
        GlobalVariables.song2 = null;
        GlobalVariables.song3 = null;
        GlobalVariables.song4 = null;
        GlobalVariables.editDestination = null;
        GlobalVariables.selectedUserIds = [];
        GlobalVariables.droppinCount = 0;
        ref.read(pathCoordinatesProvider.notifier).state = [];
      } else {
        _hideLoadingDialog();
        String errorMessage =
            response['error'] ?? 'Failed to create the trip. Please try again.';
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    ref.read(pathCoordinatesProvider.notifier).state = [];
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      // Duration delay;
      String message;

      switch (GlobalVariables.delaySetting) {
        case 1:
          // delay = const Duration(minutes: 30);
          message = "The trip ends in 30 minutes.";
          break;
        case 2:
          // delay = const Duration(hours: 2);
          message = "The trip ends in 2 hours.";
          break;
        case 3:
          // delay = const Duration(hours: 12);
          message = "The trip ends in 12 hours.";
          break;
        default:
          // delay = Duration.zero;
          message = "Your trip will be uploaded immediately.";
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text("Trip Upload Scheduled"),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    final response = await apiserice.updateTrip(
                        tripId: tripId!,
                        userId: GlobalVariables.userId!,
                        startAddress: startAddress!,
                        stopAddresses: stopAddressesString,
                        destinationAddress: endAddress!,
                        destinationTextAddress: formattedDestination,
                        tripStartDate: GlobalVariables.tripStartDate!,
                        tripEndDate: GlobalVariables.tripEndDate!,
                        tripCaption: GlobalVariables.tripCaption ?? "",
                        tripTag: GlobalVariables.selectedUserIds.toString(),
                        tripMiles: tripMiles,
                        tripSound: arrangedSongs,
                        stopLocations: stopLocations,
                        tripCoordinates: tripCoordinates,
                        startLocation: startLocation.toString(),
                        destinationLocation: endLocation.toString(),
                        droppins: [],
                        mapStyle: GlobalVariables.mapStyleSelected.toString());

                    if (!mounted) return;

                    if (response['success'] == true) {
                      logger.i(response);
                      await prefs.remove("tripId");
                      await prefs.remove("dropcount");
                      await prefs.remove("destination_text");
                      await prefs.remove("start_date");
                      await prefs.remove("caption_text");
                      String jsonStr =
                          response['trip']['destination_text_address'] ?? '[]';

                      // Parse it to a List<String>
                      List<dynamic> parsedList = [];
                      try {
                        parsedList = jsonDecode(jsonStr);
                      } catch (e) {
                        logger
                            .e("Failed to parse destination_text_address: $e");
                      }

                      // Extract first element or empty string if list is empty
                      String destination =
                          parsedList.isNotEmpty ? parsedList[0].toString() : "";

                      _hideLoadingDialog();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EndTripScreen(
                            startLocation: startLocation,
                            endLocation: endLocation,
                            stopMarkers: stopMarkers,
                            tripStartDate: GlobalVariables.tripStartDate!,
                            tripEndDate: GlobalVariables.tripEndDate!,
                            endDestination: destination,
                            tripSound: response['trip']['trip_sound'],
                          ),
                        ),
                      );
                      ref.read(isTripStartedProvider.notifier).state = false;
                      GlobalVariables.isTripStarted = false;
                      ref.read(staticStartingPointProvider.notifier).state =
                          ref.read(movingLocationProvider);
                      ref.read(movingLocationProvider.notifier).state = null;
                      ref.read(markersProvider.notifier).state = [];
                      ref.read(totalDistanceProvider.notifier).state = 0.0;
                      GlobalVariables.totalDistance = 0.0;
                      GlobalVariables.tripCaption = null;
                      GlobalVariables.song1 = null;
                      GlobalVariables.song2 = null;
                      GlobalVariables.song3 = null;
                      GlobalVariables.song4 = null;
                      GlobalVariables.editDestination = null;
                      GlobalVariables.selectedUserIds = [];
                      ref.read(pathCoordinatesProvider.notifier).state = [];
                    } else {
                      _hideLoadingDialog();
                      String errorMessage = response['error'] ??
                          'Failed to create the trip. Please try again.';
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Error"),
                            content: Text(errorMessage),
                            actions: [
                              TextButton(
                                child: const Text("OK"),
                                onPressed: () {
                                  ref
                                      .read(pathCoordinatesProvider.notifier)
                                      .state = [];
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _fetchAddresses(
    LatLng? startLocation,
    LatLng? endLocation,
    List<TripMarkerData> stopMarkers,
  ) async {
    // logger.i(stopMarkers);

    if (startLocation != null) {
      startAddress = await Common.getAddressFromLocation(startLocation);
    }

    if (endLocation != null) {
      endAddress = await Common.getAddressFromLocation(endLocation);
    }

    if (stopMarkers.isNotEmpty) {
      List<String?> stopMarkerAddresses = await Future.wait(
        stopMarkers.map((marker) async {
          try {
            final address =
                await Common.getAddressFromLocation(marker.location);
            return address ?? "";
          } catch (e) {
            logger.e(
                "Error fetching address for marker at ${marker.location}: $e");
            return "";
          }
        }).toList(),
      );

      formattedStopAddresses =
          stopMarkerAddresses.map((address) => '"$address"').toList();
      stopAddressesString = '[${formattedStopAddresses.join(', ')}]';
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: const Text(
            "To access your location, please enable permissions in Settings > Privacy & Security > Location Services.",
          ),
          actions: [
            TextButton(
              child: const Text("Open Settings"),
              onPressed: () async {
                await Geolocator.openAppSettings(); // Open settings for iOS
                if (mounted) {
                  // ignore: use_build_context_synchronously
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

  void _onDestintionClick() {
    TextEditingController textController =
        TextEditingController(text: GlobalVariables.editDestination ?? "");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Edit Destination",
            style: TextStyle(fontFamily: 'interBold'),
          ),
          content: TextField(
            controller: textController,
            maxLength: 30, // ✅ Limit to 30 characters
            maxLines: 1, // ✅ Single line only
            decoration: const InputDecoration(
              hintText: "Enter destination",
              hintStyle: TextStyle(fontFamily: 'inter'),
              counterText: '', // ✅ Hide counter text
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kColorHereButton),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'inter',
              fontSize: 14,
              overflow: TextOverflow.ellipsis, // ✅ Prevent wrapping
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                "Cancel",
                style: TextStyle(fontFamily: 'inter', color: kColorButtonPrimary),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  GlobalVariables.editDestination = textController.text;
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                "OK",
                style: TextStyle(fontFamily: 'inter', color: kColorCreateButton),
              ),
            ),
          ],
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    final pathCoordinates = ref.watch(pathCoordinatesProvider);
    final movingLocation = ref.watch(movingLocationProvider);
    final staticStartingPoint = ref.watch(staticStartingPointProvider);
    // final isTripStarted = ref.watch(isTripStartedProvider);

    return Scaffold(
      backgroundColor: kColorWhite,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return;
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: vhh(context, 5)),
                Padding(
                  padding: EdgeInsets.only(
                      left: vww(context, 0), right: vww(context, 4)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/icons/logo.png',
                        width: 90,
                        height: 80,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _onTagClicked();
                            },
                            child: Image.asset(
                              'assets/images/icons/tag_icon.png',
                              width: vww(context, 15),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _onSettingClicked();
                            },
                            child: Image.asset(
                              'assets/images/icons/setting.png',
                              width: vww(context, 15.5),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                fontFamily: 'inter'),
                          ),
                          GestureDetector(
                            onTap: () {
                              _onDestintionClick();
                            },
                            child: Text(
                              GlobalVariables.editDestination != null &&
                                      GlobalVariables
                                          .editDestination!.isNotEmpty
                                  ? (GlobalVariables.editDestination!.length >
                                          30
                                      ? '${GlobalVariables.editDestination!.substring(0, 30)}...'
                                      : GlobalVariables.editDestination!)
                                  : "Edit Destination",
                              style: const TextStyle(
                                color: kColorButtonPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                fontFamily: 'inter',
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
                      SizedBox(
                        height: vh(context, 2),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            soundtrack,
                            style: TextStyle(
                                color: kColorBlack,
                                fontSize: 13,
                                letterSpacing: -0.1,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'inter'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation1, animation2) =>
                                          const SoundScreen(),
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
                              editplaylist,
                              style: TextStyle(
                                  color: kColorButtonPrimary,
                                  fontSize: 13,
                                  letterSpacing: -0.1,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: kColorButtonPrimary,
                                  fontFamily: 'inter'),
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
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: vww(context, 3)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kColorStafGrey,
                        border: Border.all(color: Colors.black),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 1.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  'Caption:',
                                  style: TextStyle(
                                    color: kColorBlack,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    fontFamily: 'inter',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4,),
                              Text(
                                '$_currentLength/200',
                                style: const TextStyle(
                                  fontFamily: 'inter',
                                  fontSize: 10,
                                  letterSpacing: -0.1,
                                  fontWeight: FontWeight.w500,
                                  color: kColorStrongGrey,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _captionController,
                              focusNode: _captionFocusNode,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '',
                                counterText: ""
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: kColorBlack,
                                fontFamily: 'inter',
                              ),
                              minLines: 2,
                              maxLines: 2,
                              maxLength: 200,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () {
                                _captionFocusNode.unfocus();
                              },
                              onChanged: (value) {
                                GlobalVariables.tripCaption = value;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // MapBox integration with a customized size
                !isStateRestored ||
                        (movingLocation == null && staticStartingPoint == null)
                    ? const SizedBox.shrink()
                    : Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: vww(context, 4)),
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
                                  initialZoom: 12.0,
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
                                      ...ref
                                          .watch(tripMarkersProvider)
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key + 1;
                                        TripMarkerData markerData = entry.value;
                                        bool isDelayed = false;
                                        try {
                                          final delay = DateTime.parse(
                                              markerData.delayTime);
                                          isDelayed =
                                              delay.isAfter(DateTime.now());
                                        } catch (_) {
                                          isDelayed = false;
                                        }
                                        return Marker(
                                          width: 20.0,
                                          height: 20.0,
                                          point: markerData.location,
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  Duration? delayDuration;
                                                  String delayText = "";
                                                  try {
                                                    final delay =
                                                        DateTime.parse(
                                                            markerData
                                                                .delayTime);
                                                    final now = DateTime.now();
                                                    if (delay.isAfter(now)) {
                                                      delayDuration =
                                                          delay.difference(now);
                                                      final hours =
                                                          delayDuration.inHours;
                                                      final minutes =
                                                          delayDuration
                                                              .inMinutes
                                                              .remainder(60);
                                                      delayText =
                                                          "Will be posted in ";
                                                      if (hours > 0) {
                                                        delayText +=
                                                            "$hours hour${hours > 1 ? 's' : ''}";
                                                      }
                                                      if (hours > 0 && minutes > 0) {
                                                        delayText += " and ";
                                                      }
                                                      if (minutes > 0) {
                                                        delayText +=
                                                            "$minutes minute${minutes > 1 ? 's' : ''}";
                                                      }
                                                    }
                                                  } catch (_) {
                                                    delayText = "";
                                                  }

                                                  return AlertDialog(
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0), // Increased vertical padding
                                                          child: SizedBox(
                                                            height: 40, 
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    (markerData.caption.length) > 20
                                                                      ? '${markerData.caption.substring(0, 40)}...'
                                                                      : (markerData.caption),
                                                                    style: const TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: Colors.grey,
                                                                      fontFamily: 'inter',
                                                                      letterSpacing: -0.1,
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(Icons.close, color: Colors.black),
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Image.network(
                                                          markerData.imagePath,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) {
                                                              return child;
                                                            } else {
                                                              return const Center(
                                                                child:SpinningLoader(),
                                                              );
                                                            }
                                                          },
                                                          errorBuilder:
                                                              (context, error, stackTrace) {
                                                            return const Icon(
                                                                Icons.broken_image,
                                                                size: 100);
                                                          },
                                                        ),
                                                        if (delayText.isNotEmpty)
                                                          Padding(
                                                            padding:const EdgeInsets.only(top: 8.0),
                                                            child: Text(
                                                              delayText,
                                                              style:const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:FontWeight.w600,
                                                                color: Colors.redAccent,
                                                                fontFamily:
                                                                    'inter',
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: Opacity(
                                              opacity: isDelayed ? 0.5 : 1.0,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                  border: Border.all(
                                                      color: Colors.black,
                                                      width: 2),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  index.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),

                                      // Future delay label markers
                                      ...ref
                                          .watch(futureMarkersProvider)
                                          .map((futureMarker) {
                                        return Marker(
                                          point: futureMarker.location,
                                          width: 150,
                                          height: 20,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 2, vertical: 0),
                                            decoration: BoxDecoration(
                                              color: Colors.grey
                                                  .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(2, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                futureMarker.label,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                    fontFamily: 'inter'),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  // MarkerLayer(
                                  //   markers: [
                                  //     ...ref
                                  //         .watch(markersProvider)
                                  //         .asMap()
                                  //         .entries
                                  //         .map((entry) {
                                  //       int index = entry.key + 1;
                                  //       MarkerData markerData = entry.value;
                                  //       return Marker(
                                  //         width: 20.0,
                                  //         height: 20.0,
                                  //         point: markerData.location,
                                  //         child: GestureDetector(
                                  //           onTap: () {
                                  //             showDialog(
                                  //               context: context,
                                  //               builder: (context) => AlertDialog(
                                  //                 content: Column(
                                  //                   mainAxisSize: MainAxisSize.min,
                                  //                   children: [
                                  //                     Padding(
                                  //                       padding: const EdgeInsets.symmetric(
                                  //                         horizontal: 8.0,
                                  //                         vertical: 4.0
                                  //                       ),
                                  //                       child: Row(
                                  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //                         children: [
                                  //                           Text(
                                  //                             markerData.caption,
                                  //                             style: const TextStyle(
                                  //                               fontSize: 16,
                                  //                               fontWeight:FontWeight.bold,
                                  //                               color: Colors.grey,
                                  //                               fontFamily: 'inter',
                                  //                             ),
                                  //                           ),
                                  //                           IconButton(
                                  //                             icon: const Icon(
                                  //                               Icons.close,
                                  //                               color: Colors.black),
                                  //                             onPressed: () {
                                  //                               Navigator.of(context).pop();
                                  //                             },
                                  //                           ),
                                  //                         ],
                                  //                       ),
                                  //                     ),
                                  //                     Image.network(
                                  //                       markerData.imagePath,
                                  //                       fit: BoxFit.cover,
                                  //                       loadingBuilder: (context,
                                  //                           child,
                                  //                           loadingProgress) {
                                  //                         if (loadingProgress ==
                                  //                             null) {
                                  //                           return child;
                                  //                         } else {
                                  //                           return const Center(
                                  //                             child:SpinningLoader(),
                                  //                           );
                                  //                         }
                                  //                       },
                                  //                       errorBuilder: (context,error, stackTrace) {
                                  //                         return const Icon(
                                  //                           Icons.broken_image,
                                  //                           size: 100
                                  //                         );
                                  //                       },
                                  //                     ),
                                  //                   ],
                                  //                 ),
                                  //               ),
                                  //             );
                                  //           },
                                  //           child: Container(
                                  //             width: 10,
                                  //             height: 10,
                                  //             decoration: BoxDecoration(
                                  //               shape: BoxShape.circle,
                                  //               color: Colors.white,
                                  //               border: Border.all(
                                  //                 color: Colors.black,
                                  //                 width: 2
                                  //               ),
                                  //             ),
                                  //             alignment: Alignment.center,
                                  //             child: Text(
                                  //               index.toString(),
                                  //               style: const TextStyle(
                                  //                 fontSize: 13,
                                  //                 fontWeight: FontWeight.bold,
                                  //                 color: Colors.black,
                                  //               ),
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       );
                                  //     }),
                                  //   ],
                                  // ),
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
                                        padding:
                                            EdgeInsets.zero, // Adjust for width
                                        child: Container(
                                          padding: const EdgeInsets.all(3.0),
                                          // ignore: deprecated_member_use
                                          color: Colors.white.withOpacity(0.5),
                                          child: const Column(
                                            children: [
                                              Text(
                                                'Trip in progress',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontStyle: FontStyle.italic,
                                                    fontFamily: 'interBold'),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                'Drop a pin to post your map',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontStyle: FontStyle.italic,
                                                    fontFamily: 'inter'),
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

                              Positioned(
                                bottom: 70,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: vww(context, 7),
                                      right: vww(context, 7),
                                      top: vhh(context, 3),
                                    ),
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final isTripStarted = ref.watch(isTripStartedProvider);

                                        return Row(
                                          children: [
                                            Expanded(
                                              child: ButtonWidget(
                                                btnType: isTripStarted
                                                    ? ButtonWidgetType.endTripTitle   // "End Trip"
                                                    : ButtonWidgetType.startTripTitle, // "Start Trip"
                                                borderColor:
                                                    isTripStarted ? Colors.red : kColorButtonPrimary,
                                                textColor: kColorWhite,
                                                fullColor:
                                                    isTripStarted ? Colors.red : kColorButtonPrimary,
                                                onPressed: toggleTrip,
                                              ),
                                            ),

                                            const SizedBox(width: 30),

                                            // Drop Pin button
                                            Expanded(
                                              child: IgnorePointer(
                                                ignoring: !isTripStarted, // block taps when false
                                                child: ButtonWidget(
                                                  btnType: ButtonWidgetType.dropPinTitle,
                                                  borderColor: isTripStarted
                                                      ? const Color(0xFF4DC4FF)
                                                      : const Color(0xFFBDBDBD),
                                                  fullColor: isTripStarted
                                                      ? const Color(0xFF4DC4FF)
                                                      : const Color(0xFFBDBDBD),
                                                  textColor: Colors.white,
                                                  onPressed: isTripStarted
                                                      ? droppinClicked
                                                      : () {}, 
                                                ),
                                              ),
                                            ),

                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),


                              Positioned(
                                bottom: 13,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: EdgeInsets.zero, // Adjust for width
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                        3.0), // Inner padding for spacing around text
                                    color: Colors.white.withAlpha(
                                        128), // Background color with slight transparency
                                    child: const Text(
                                      'Note: Start trip, then drop a pin to make\nyour post visible to your followers',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'inter',
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

class MarkerDataWithDelayLabel {
  final LatLng location;
  final String label;
  MarkerDataWithDelayLabel({required this.location, required this.label});
}

final futureMarkersProvider =
    StateProvider<List<MarkerDataWithDelayLabel>>((ref) => []);
