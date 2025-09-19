import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:RollaTravel/src/screen/home/home_sound_screen.dart';
// import 'package:RollaTravel/src/screen/trip/sound_screen.dart';
import 'package:RollaTravel/src/screen/trip/start_trip.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:RollaTravel/src/utils/trip_marker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:logger/logger.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class EndTripScreen extends ConsumerStatefulWidget {
  final LatLng? startLocation;
  final LatLng? endLocation;
  final List<TripMarkerData> stopMarkers;
  final String tripStartDate;
  final String tripEndDate;
  final String endDestination;
  final String tripSound;

  const EndTripScreen(
      {super.key,
      required this.startLocation,
      required this.endLocation,
      required this.stopMarkers,
      required this.tripStartDate,
      required this.tripEndDate,
      required this.endDestination,
      required this.tripSound});
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
  final GlobalKey mapKey = GlobalKey();
  final GlobalKey _shareWidgetKey = GlobalKey();
  bool _isSharing = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
  }

  // String _generateStaticMapUrl() {
  //   const accessToken = 'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw';
  //   final List<String> points = widget.stopMarkers
  //       .map((m) => '${m.location.longitude},${m.location.latitude}')
  //       .toList();

  //   final pathOverlay = points.isNotEmpty
  //       ? 'path-5+0000ff-1(${points.join(";")})/'
  //       : '';

  //   final center = widget.endLocation!;
  //   return 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/'
  //       '$pathOverlay${center.longitude},${center.latitude},10,0/600x400'
  //       '?access_token=$accessToken';
  // }

  Future<void> _onShareClicked() async {
    if (_isSharing) return;
    
    setState(() => _isSharing = true);
    
    try {
      // Ensure widget is mounted and ready
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 50)); // Small delay for rendering

      // Get the boundary
      final boundaryContext = _shareWidgetKey.currentContext;
      if (boundaryContext == null || !boundaryContext.mounted) {
        _showErrorDialog("Widget not ready for sharing.");
        return;
      }

      // Wait for the next frame to ensure rendering is complete
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));

      // ignore: use_build_context_synchronously
      final boundary = boundaryContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showErrorDialog("Unable to capture content.");
        return;
      }

      // Convert to image with error handling
      ui.Image originalImage;
      try {
        originalImage = await boundary.toImage(pixelRatio: 3.0);
      } catch (e) {
        logger.e("Image capture error: $e");
        _showErrorDialog("Failed to capture image.");
        return;
      }
      final width = originalImage.width.toDouble();
      final height = originalImage.height.toDouble();

      // Create canvas with rounded clipping
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(60), // same as your UI
      );

      canvas.clipRRect(rrect);
      canvas.drawImage(originalImage, Offset.zero, Paint());

      final clippedImage = await recorder
          .endRecording()
          .toImage(originalImage.width, originalImage.height);

      final pngBytes = await clippedImage.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) {
        _showErrorDialog("Failed to encode image.");
        return;
      }

      // Save to file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/rolla_share_$timestamp.png';
      final file = File(filePath);
      
      try {
        await file.writeAsBytes(pngBytes.buffer.asUint8List());
        if (!(await file.exists())) {
          _showErrorDialog("File not saved.");
          return;
        }
      } catch (e) {
        logger.e("File write error: $e");
        _showErrorDialog("Failed to save image.");
        return;
      }

      // Share the file with platform-specific handling
      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Posted on the Rolla travel app',
          // text: 'I just created a trip with Rolla Travel!',
        );
        logger.i("Share successful");
      } on PlatformException catch (e) {
        logger.e("Platform sharing error: ${e.message}");
        _showErrorDialog("Sharing failed: ${e.message ?? 'Unknown error'}");
      } catch (e) {
        logger.e("General sharing error: $e");
        _showErrorDialog("Sharing failed: ${e.toString().replaceAll('Exception: ', '')}");
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sharing Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _playListClicked () {
    if (widget.tripSound == "tripSound") {
      // Show an alert
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("No playlist"),
            content: const Text("There is no playlist available for this trip."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.pop(context);
                },
                child: const Text("OK",
                style: TextStyle(color: kColorStrongGrey),),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeSoundScreen(
            tripSound: widget.tripSound,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathCoordinates = ref.watch(pathCoordinatesProvider);
    return Scaffold(
      backgroundColor: kColorWhite,
      body: PopScope(
          canPop: !_isSharing, 
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_isSharing) {
              _showErrorDialog("Please wait while sharing completes");
            }
          },
          child: SizedBox.expand(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: vhh(context, 6),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.9),
                                spreadRadius: 1.5,
                                blurRadius: 15,
                                offset: const Offset(0, 0),
                              ),
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20), 
                            child: RepaintBoundary(
                              key: _shareWidgetKey,
                              child: Container(
                                width: vhh(context, 100),
                                height: vhh(context, 65),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20), // Rounded corners for image
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        Center(
                                          child: GestureDetector(
                                            onTap: () {},
                                            child: Image.asset(
                                              'assets/images/icons/logo.png',
                                              width: 90,
                                              height: 80,
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
                                              GlobalVariables.editDestination = null;
                                              ref.read(pathCoordinatesProvider.notifier).state = [];
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) =>const StartTripScreen()));
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 11.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            destination,
                                            style: TextStyle(
                                              color: kColorBlack,
                                              fontSize: 13,
                                              letterSpacing: -0.1,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'inter',
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              widget.endDestination,
                                              style: const TextStyle(
                                                color: kColorButtonPrimary,
                                                fontSize: 14,
                                                decoration: TextDecoration.underline,
                                                decorationColor: kColorButtonPrimary,
                                                fontFamily: 'inter',
                                              ),
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            soundtrack,
                                            style: TextStyle(
                                              color: kColorBlack,
                                              fontSize: 13,
                                              letterSpacing: -0.1,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'inter',
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  spreadRadius: 0.5,
                                                  blurRadius: 6,
                                                  offset: const Offset(-3, 5),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: kColorButtonPrimary,
                                                width: 1.2,
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2.5),
                                            child: GestureDetector(
                                              onTap: () {
                                                _playListClicked();
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Image.asset(
                                                    "assets/images/icons/music.png",
                                                    width: 12,
                                                    height: 12,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  const Text(
                                                    'playlist',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: -0.1,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: vww(context, 2)),
                                      child: Container(
                                        height: vhh(context, 30),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: kColorStrongGrey,
                                            width: 1,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            FlutterMap(
                                                mapController: _mapController,
                                                options: MapOptions(
                                                  initialCenter: widget.startLocation!,
                                                  initialZoom: 11.0,
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
                                                      if (widget.stopMarkers.isNotEmpty)
                                                        ...widget.stopMarkers.map((markerData) {
                                                          int index = widget.stopMarkers.indexOf(markerData) + 1;
                                                          return Marker(
                                                            width: 20.0,
                                                            height: 20.0,
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
                                                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical:4.0),
                                                                          child: Row(
                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                markerData.caption,
                                                                                style: const TextStyle(
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: Colors.grey,
                                                                                  fontFamily:'inter',
                                                                                ),
                                                                              ),
                                                                              IconButton(
                                                                                icon: const Icon(
                                                                                    Icons.close,
                                                                                    color:Colors.black),
                                                                                onPressed:() {
                                                                                  Navigator.of(context).pop();
                                                                                },
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Image.network(
                                                                          markerData.imagePath,
                                                                          fit: BoxFit.cover,
                                                                          loadingBuilder:(context, child, loadingProgress) {
                                                                            if (loadingProgress ==null) {
                                                                              return child;
                                                                            } else {
                                                                              return const Center(
                                                                                child:SpinningLoader(),
                                                                              );
                                                                            }
                                                                          },
                                                                          errorBuilder:
                                                                              (context,
                                                                                  error,
                                                                                  stackTrace) {
                                                                            return const Icon(
                                                                                Icons
                                                                                    .broken_image,
                                                                                size:
                                                                                    100);
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              child: Container(
                                                                width: 30,
                                                                height: 30,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape:
                                                                      BoxShape.circle,
                                                                  color: Colors.white,
                                                                  border: Border.all(
                                                                    color: Colors.black,
                                                                    width:
                                                                        2, // Black border
                                                                  ),
                                                                ),
                                                                alignment:
                                                                    Alignment.center,
                                                                child: Text(
                                                                  index
                                                                      .toString(), // Display index number
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize: 13,
                                                                    fontWeight:
                                                                        FontWeight.bold,
                                                                    color: Colors.black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Image.asset(
                                      'assets/images/icons/logo.png',
                                      width: 90,
                                      height: 80,
                                    ),
                                    const Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "the Rolla travel app.",
                                              style: TextStyle(
                                                fontSize: 16,
                                                letterSpacing: -0.1,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'inter',
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
                        ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kColorGreen,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 5, 
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          SizedBox(height: 15,),
                          Text("Success! This trip has been completed.",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.1,
                              fontFamily: 'inter',
                              color: kColorWhite,
                            ),
                          ),
                          SizedBox(height: 15,),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 15.0),
                          child: Text(
                            "Share this summary on another platform:",
                            style: TextStyle(
                              fontSize: 14,
                              color: kColorStrongGrey,
                              fontFamily: 'inter',
                              letterSpacing: -0.1
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        GestureDetector(
                          onTap: () {
                            _onShareClicked();
                          },
                          child: Image.asset(
                            "assets/images/icons/upload_icon.png",
                            height: 20,
                          ),
                        ),
                        const SizedBox(height: 30,),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
