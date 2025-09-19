import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:RollaTravel/src/utils/trip_marker_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/droppin/another_location_screen.dart';
import 'package:RollaTravel/src/screen/droppin/choosen_location_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/common.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/location.permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SelectLocationScreen extends ConsumerStatefulWidget {
  final LatLng? selectedLocation;
  final String caption;
  final String imagePath;
  const SelectLocationScreen(
      {super.key,
      required this.selectedLocation,
      required this.caption,
      required this.imagePath});

  @override
  ConsumerState<SelectLocationScreen> createState() =>
      SelectLocationScreenState();
}

class SelectLocationScreenState extends ConsumerState<SelectLocationScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 3;
  final logger = Logger();
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  final Completer<void> _mapReadyCompleter = Completer<void>();
  bool isuploadingImage = false;
  bool isuploadingData = false;
  String? tripMiles;
  String? startAddress;
  List<String> formattedStopAddresses = [];
  String stopAddressesString = "";
  List<Map<String, dynamic>> droppins = [];
  bool _isLoading = true;
  final uuid = const Uuid();
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
    if (PermissionService().hasLocationPermission) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      } catch (e) {
        logger.e("Failed to get location: $e");
        setState(() {
          _isLoading = false;
        });
      }
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

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 30), // Adjust padding to match the screenshot
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Caption and Close Icon Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Caption",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Image.asset(
                "assets/images/background/Lake1.png",
                fit: BoxFit.cover,
                width: vww(context, 90),
                height: vhh(context, 70),
              ),
              const Divider(
                  height: 1,
                  color: Colors.grey), 
              SizedBox(height: vhh(context, 5))
            ],
          ),
        );
      },
    );
  }

  Future<void> _dropPinButtonSelected() async {
    final apiserice = ApiService();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isuploadingImage = true;
    });
    File imageFile = File(widget.imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64String = base64Encode(imageBytes);
    final apiService = ApiService();
    String imageUrl = await apiService.getImageUrl(base64String);

    if (imageUrl.isNotEmpty) {
      setState(() {
        isuploadingImage = false;
        isuploadingData = true;
      });
    } else {
      if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed upload image....'),
          ),
        );
      return;
    }

    LatLng? testlocation;
    testlocation = widget.selectedLocation;

    final LatLng selectedLocation =
        (testlocation!.latitude == 0.0 && testlocation.longitude == 0.0)
            ? _currentLocation!
            : testlocation;
    DateTime now = DateTime.now();
    Duration delay;
    switch (GlobalVariables.delaySetting) {
      case 1:
        delay = const Duration(minutes: 30);
        break;
      case 2:
        delay = const Duration(hours: 2);
        break;
      case 3:
        delay = const Duration(hours: 12);
        break;
      default:
        delay = Duration.zero;
    }
    DateTime uploadTime = now.add(delay);
    String formattedUploadTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(uploadTime);
    
    final markerData = TripMarkerData(
        location: selectedLocation,
        imagePath: imageUrl,
        caption: widget.caption,
        delayTime: formattedUploadTime);

    ref.read(tripMarkersProvider.notifier).state = [
      ...ref.read(tripMarkersProvider),
      markerData,
    ];

    LatLng? startLocation = ref.read(staticStartingPointProvider);
    LatLng? endLocation = ref.read(movingLocationProvider);
    List<TripMarkerData> stopMarkers = ref.read(tripMarkersProvider);
    tripMiles = "${GlobalVariables.totalDistance.toStringAsFixed(3)} miles";
    if (startLocation != null) {
      startAddress = await Common.getAddressFromLocation(startLocation);
    }

    if (stopMarkers != []) {
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
        }),
      );

      formattedStopAddresses =
          stopMarkerAddresses.map((address) => '"$address"').toList();
      stopAddressesString = '[${formattedStopAddresses.join(', ')}]';
    }

    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final tripCoordinates = ref
        .read(pathCoordinatesProvider)
        .map((latLng) => {
              'latitude': latLng.latitude,
              'longitude': latLng.longitude,
            })
        .toList();

    final stopLocations = stopMarkers
        .map((marker) => {
              'latitude': marker.location.latitude,
              'longitude': marker.location.longitude,
            })
        .toList();

    String formattedDestination = '["${GlobalVariables.editDestination}"]';
    int? tripId = prefs.getInt("tripId");
    logger.i("tripId : $tripId");

    final Map<String, dynamic> response;

    if (tripId != null) {
      int? dropPinId = prefs.getInt("droppinId");
      int? dropcount = prefs.getInt("dropcount");
      int currentDropId = dropPinId ?? 0; 

      DateTime now = DateTime.now();
      Duration delay;
      switch (GlobalVariables.delaySetting) {
        case 1:
          delay = const Duration(minutes: 30);
          break;
        case 2:
          delay = const Duration(hours: 2);
          break;
        case 3:
          delay = const Duration(hours: 12);
          break;
        default:
          delay = Duration.zero;
      }
      DateTime uploadTime = now.add(delay);
      String formattedUploadTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(uploadTime);


      droppins = stopMarkers.asMap().entries.map((entry) {
        final int index = entry.key + 1; 
        final TripMarkerData marker = entry.value;

        if (dropPinId != null && entry.key < dropcount!) {
          final mapData = {
            "id": currentDropId, 
            "stop_index": index,
            "image_path": marker.imagePath,
            "image_caption": marker.caption,
            "delay_time" : marker.delayTime
          };
          currentDropId++; 
          return mapData;
        } else {
          return {
            "stop_index": index,
            "image_path": marker.imagePath,
            "image_caption": marker.caption,
            "delay_time" : formattedUploadTime
          };
        }
      }).toList();
      logger.i(droppins);


      List<String> songs = [
        if (GlobalVariables.song1 != null && GlobalVariables.song1!.isNotEmpty) GlobalVariables.song1!,
        if (GlobalVariables.song2 != null && GlobalVariables.song2!.isNotEmpty) GlobalVariables.song2!,
        if (GlobalVariables.song3 != null && GlobalVariables.song3!.isNotEmpty) GlobalVariables.song3!,
        if (GlobalVariables.song4 != null && GlobalVariables.song4!.isNotEmpty) GlobalVariables.song4!
      ];

      String arrangedSongs = songs.join(',');
  

      if(GlobalVariables.delaySetting == 0) {
        response = await apiserice.updateTrip(
          tripId: tripId,
          userId: GlobalVariables.userId!,
          startAddress: startAddress!,
          stopAddresses: stopAddressesString,
          destinationAddress: "Destination address for DropPin",
          destinationTextAddress: formattedDestination,
          tripStartDate: GlobalVariables.tripStartDate!,
          tripCaption: GlobalVariables.tripCaption.toString(),
          tripEndDate: formattedDate,
          tripMiles: tripMiles!,
          tripSound: arrangedSongs,
          tripTag: GlobalVariables.selectedUserIds.toString(),
          stopLocations: stopLocations,
          tripCoordinates: tripCoordinates,
          droppins: droppins,
          startLocation: startLocation.toString(),
          mapStyle: GlobalVariables.mapStyleSelected.toString(),
          destinationLocation: endLocation.toString());

        if (response['success'] == true) {
          setState(() {
            isuploadingData = false;
          });
          await prefs.setInt("tripId", response['trip']['id']);
          await prefs.setInt("dropcount", response['trip']['droppins'].length);
          if (mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChoosenLocationScreen(
                          caption: widget.caption,
                          imagePath: widget.imagePath,
                          location: _currentLocation,
                          soundList: response['trip']['trip_sound'],
                        )));
          }
        } else {
          setState(() {
            isuploadingData = false;
          });
          String errorMessage =
              response['error'] ?? 'Failed to create the trip. Please try again.';
          
          if(!mounted) return;
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
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }else {
        String message;
        setState(() {
          isuploadingData = false;
        });

        switch (GlobalVariables.delaySetting) {
          case 1:
            message = "Your trip will be uploaded after 30 minutes.";
            break;
          case 2:
            message = "Your trip will be uploaded after 2 hours.";
            break;
          case 3:
            message = "Your trip will be uploaded after 12 hours.";
            break;
          default:
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
                      setState(() {
                        isuploadingData = true;
                      });
                      final Map<String, dynamic> response;
                      response = await apiserice.updateTrip(
                        tripId: tripId,
                        userId: GlobalVariables.userId!,
                        startAddress: startAddress!,
                        stopAddresses: stopAddressesString,
                        destinationAddress: "Destination address for DropPin",
                        destinationTextAddress: formattedDestination,
                        tripStartDate: GlobalVariables.tripStartDate!,
                        tripCaption: GlobalVariables.tripCaption.toString(),
                        tripEndDate: formattedDate,
                        tripMiles: tripMiles!,
                        tripSound: arrangedSongs,
                        tripTag: GlobalVariables.selectedUserIds.toString(),
                        stopLocations: stopLocations,
                        tripCoordinates: tripCoordinates,
                        droppins: droppins,
                        startLocation: startLocation.toString(),
                        mapStyle: GlobalVariables.mapStyleSelected.toString(),
                        destinationLocation: endLocation.toString());

                      if (response['success'] == true) {
                        setState(() {
                          isuploadingData = false;
                        });
                        await prefs.setInt("tripId", response['trip']['id']);
                        await prefs.setInt("dropcount", response['trip']['droppins'].length);
                        if (mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChoosenLocationScreen(
                                        caption: widget.caption,
                                        imagePath: widget.imagePath,
                                        location: _currentLocation,
                                        soundList: response['trip']['trip_sound'],
                                      )));
                        }
                      } else {
                        setState(() {
                          isuploadingData = false;
                        });
                        String errorMessage =
                            response['error'] ?? 'Failed to create the trip. Please try again.';
                        
                        if(!mounted) return;
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
      
    } else {
      DateTime now = DateTime.now();
      Duration delay;
      switch (GlobalVariables.delaySetting) {
        case 1:
          delay = const Duration(minutes: 30);
          break;
        case 2:
          delay = const Duration(hours: 2);
          break;
        case 3:
          delay = const Duration(hours: 12);
          break;
        default:
          delay = Duration.zero;
      }
      DateTime uploadTime = now.add(delay);
      String formattedUploadTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(uploadTime);

      droppins = stopMarkers.asMap().entries.map((entry) {
        final int index = entry.key + 1;
        final TripMarkerData marker = entry.value;
        return {
          "stop_index": index,
          "image_path": marker.imagePath,
          "image_caption": widget.caption,
          "delay_time" : formattedUploadTime
        };
      }).toList();
      // logger.i(droppins);
      // logger.i(stopLocations);

      List<String> songs = [
        if (GlobalVariables.song1?.isNotEmpty ?? false) GlobalVariables.song1!,
        if (GlobalVariables.song2?.isNotEmpty ?? false) GlobalVariables.song2!,
        if (GlobalVariables.song3?.isNotEmpty ?? false) GlobalVariables.song3!,
        if (GlobalVariables.song4?.isNotEmpty ?? false) GlobalVariables.song4!
      ];
      String arrangedSongs = songs.isNotEmpty ? songs.join(',') : "tripSound";
      logger.i(arrangedSongs);

      if(GlobalVariables.delaySetting == 0) {

        DateTime now = DateTime.now();
        String delayDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

        response = await apiserice.createTrip(
          userId: GlobalVariables.userId!,
          startAddress: startAddress!,
          stopAddresses: stopAddressesString,
          destinationAddress: "Destination address for DropPin",
          destinationTextAddress: formattedDestination,
          tripStartDate: GlobalVariables.tripStartDate!,
          tripEndDate: "",
          tripMiles: tripMiles!,
          tripCaption: GlobalVariables.tripCaption?? "",
          tripTag: GlobalVariables.selectedUserIds.toString(),
          tripSound: arrangedSongs,
          stopLocations: stopLocations,
          tripCoordinates: tripCoordinates,
          droppins: droppins,
          startLocation: startLocation.toString(),
          destinationLocation: endLocation.toString(),
          mapstyle: GlobalVariables.mapStyleSelected.toString(),
          delayTime: delayDate);

        if (response['success'] == true) {
          // logger.i(response['trip']);
          setState(() {
            isuploadingData = false;
          });
          await prefs.setInt("tripId", response['trip']['id']);
          await prefs.setInt("droppinId", response['trip']['droppins'][0]['id']);
          await prefs.setInt("dropcount", response['trip']['droppins'].length);
          if (mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChoosenLocationScreen(
                          caption: widget.caption,
                          imagePath: widget.imagePath,
                          location: _currentLocation,
                          soundList: response['trip']['trip_sound'],
                        )));
          } else {
            setState(() {
              isuploadingData = false;
            });
            String errorMessage = response['error'] ??
                'Failed to create the trip. Please try again.';

            if(!mounted) return;
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
                        Navigator.of(context).pop(); 
                      },
                    ),
                  ],
                );
              },
            );
          }
        }
      } else{
        Duration delay;
        String message;

        setState(() {
          isuploadingData = false;
        });
        switch (GlobalVariables.delaySetting) {
          case 1:
            delay = const Duration(minutes: 30);
            message = "Your trip will be uploaded after 30 minutes.";
            break;
          case 2:
            delay = const Duration(hours: 2);
            message = "Your trip will be uploaded after 2 hours.";
            break;
          case 3:
            delay = const Duration(hours: 12);
            message = "Your trip will be uploaded after 12 hours.";
            break;
          default:
            delay = Duration.zero;
            message = "Your trip will be uploaded immediately.";
        }

        DateTime uploadTime = now.add(delay);
        String formattedUploadTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(uploadTime);


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
                      setState(() {
                        isuploadingData = true;
                      });
                      final Map<String, dynamic> response;
                      response = await apiserice.createTrip(
                        userId: GlobalVariables.userId!,
                        startAddress: startAddress!,
                        stopAddresses: stopAddressesString,
                        destinationAddress: "Destination address for DropPin",
                        destinationTextAddress: formattedDestination,
                        tripStartDate: GlobalVariables.tripStartDate!,
                        tripEndDate: "",
                        tripMiles: tripMiles!,
                        tripCaption: GlobalVariables.tripCaption?? "",
                        tripTag: GlobalVariables.selectedUserIds.toString(),
                        tripSound: arrangedSongs,
                        stopLocations: stopLocations,
                        tripCoordinates: tripCoordinates,
                        droppins: droppins,
                        startLocation: startLocation.toString(),
                        destinationLocation: endLocation.toString(),
                        mapstyle: GlobalVariables.mapStyleSelected.toString(),
                        delayTime: formattedUploadTime);

                      if (response['success'] == true) {
                        logger.i(response['trip']);
                        setState(() {
                          isuploadingData = false;
                        });
                        await prefs.setInt("tripId", response['trip']['id']);
                        await prefs.setInt("droppinId", response['trip']['droppins'][0]['id']);
                        await prefs.setInt("dropcount", response['trip']['droppins'].length);
                        if (mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChoosenLocationScreen(
                                        caption: widget.caption,
                                        imagePath: widget.imagePath,
                                        location: _currentLocation,
                                        soundList: response['trip']['trip_sound'],
                                      )));
                        } else {
                          setState(() {
                            isuploadingData = false;
                          });
                          String errorMessage = response['error'] ??
                              'Failed to create the trip. Please try again.';

                          if(!mounted) return;
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
                                      Navigator.of(context).pop(); 
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
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
  }

  void _onOtherLocationButtonSelected() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AnotherLocationScreen(
                  caption: widget.caption,
                  imagePath: widget.imagePath,
                  location: _currentLocation,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              return;
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: vhh(context, 5)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/images/icons/logo.png',
                            width: 90, height: 80,),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 12,),
                      ],
                    ),

                    //title
                    const Center(
                      child: Text(
                        'Select Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    SizedBox(height: vhh(context, 2)),

                    // set map
                    !_isLoading
                        ? Center(
                            child: SizedBox(
                              height: vhh(context, 42),
                              width: vww(context, 96),
                              child: Center(
                                  child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _currentLocation!,
                                      initialZoom: 12.0,
                                      onMapReady: () {
                                        _mapReadyCompleter.complete();
                                        if (widget.selectedLocation != const LatLng(0, 0)) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            _mapController.move(widget.selectedLocation!, 12.0);
                                          });
                                        }
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
                                      MarkerLayer(markers: [
                                        if (widget.selectedLocation ==
                                            const LatLng(0, 0))
                                          Marker(
                                            width: 60.0,
                                            height: 60.0,
                                            point: _currentLocation ??
                                                const LatLng(43.1557, -77.6157),
                                            child: GestureDetector(
                                              onTap: () => _showImageDialog(),
                                              child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 30),
                                            ),
                                          )
                                        else if (widget.selectedLocation !=
                                            const LatLng(0, 0))
                                          Marker(
                                            width: 60.0,
                                            height: 60.0,
                                            point: widget.selectedLocation ??
                                                const LatLng(43.1557, -77.6157),
                                            child: GestureDetector(
                                              onTap: () => _showImageDialog(),
                                              child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 30),
                                            ),
                                          )
                                      ]),
                                    ],
                                  ),
                                  Positioned(
                                    right: 10,
                                    top: 70,
                                    child: Column(
                                      children: [
                                        FloatingActionButton(
                                          heroTag: 'zoom_in_button_droppin',
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
                                          heroTag: 'zoom_out_button_droppin', 
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
                                  // Positioned(
                                  //   top: 5,
                                  //   left: 0,
                                  //   right: 0,
                                  //   child: Padding(
                                  //     padding:
                                  //         EdgeInsets.zero, // Adjust for width
                                  //     child: Container(
                                  //       padding: const EdgeInsets.all(5.0), 
                                  //       child: Text(
                                  //         'Tap the pin to see your photo',
                                  //         style: TextStyle(
                                  //             color: Colors.black.withValues(alpha: 0.8),
                                  //             fontSize: 14,
                                  //             fontStyle: FontStyle.italic,
                                  //             fontFamily: 'inter'),
                                  //         textAlign: TextAlign.center,
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              )),
                            ),
                          )
                        : const Center(child: SpinningLoader()),
                    SizedBox(
                      height: vhh(context, 5),
                    ),

                    // drop button
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: -2,
                                offset: const Offset(0, 3), // Shadow position
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _dropPinButtonSelected,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: kColorHereButton,
                              minimumSize: const Size(350, 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Drop pin at location displayed above',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: vhh(context, 1),
                    ),
                    const Center(
                      child: Text(
                        "OR",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'inter'),
                      ),
                    ),
                    SizedBox(
                      height: vhh(context, 1),
                    ),
                    GestureDetector(
                      onTap: () {
                        _onOtherLocationButtonSelected();
                      },
                      child: const Text(
                        "Choose another location",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.black,
                            fontFamily: 'inter'),
                      ),
                    ),
                  ],
                ),
              ),
              if (isuploadingImage)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center, // Ensures text is centered horizontally
                        children: [
                          SpinningLoader(),
                          SizedBox(height: 16),
                          Text(
                            'Uploading Data to server... \nThis may take up to 30 seconds. \nPlease do not exit this screen.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center, // Centers the text horizontally
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (isuploadingData)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center, // Ensures text is centered horizontally
                        children: [
                          SpinningLoader(),
                          SizedBox(height: 16),
                          Text(
                            'Uploading Data to server... \nThis may take up to 30 seconds. \nPlease do not exit this screen.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center, // Centers the text horizontally
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          )),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
