import 'dart:async';

import 'package:RollaTravel/src/screen/droppin/take_picture_screen.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';

class PhotoSelectScreen extends StatefulWidget {
  const PhotoSelectScreen({super.key});

  @override
  PhotoSelectScreenState createState() => PhotoSelectScreenState();
}

class PhotoSelectScreenState extends State<PhotoSelectScreen> {
  final int _currentIndex = 3;
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final logger = Logger();
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;
  bool _isCameraInitialized = false;
  // FlashMode _currentFlashMode = FlashMode.off;
  FlashMode _userFlashMode = FlashMode.off; // default: OFF
  // DateTime _lastFlashChange = DateTime.now();
  // bool _flashLocked = false;
  // bool _isReadyToDisplay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraPermission();
    });
  }

  @override
  void dispose() {
    _cameraController?.setFlashMode(FlashMode.off);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      logger.i("✅ Camera permission already granted");
      _initializeCamera();
    } else if (status.isDenied || status.isRestricted || status.isLimited) {
      logger.e("🚨 Camera permission denied or restricted");
      final newStatus = await Permission.camera.request();
      if (newStatus.isGranted) {
        _initializeCamera();
      } else {
        _showCameraPermissionDialog();
      }
    } else if (status.isPermanentlyDenied) {
      logger.e("🚨 Camera permission permanently denied");
      _showCameraPermissionDialog();
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Camera Permission Needed",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "You have denied camera access. Please enable it in Settings to take a photo.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await openAppSettings(); // ✅ Open app settings
                // ignore: use_build_context_synchronously
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text(
                "Open Settings",
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ❌ Cancel
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        _initializeControllerFuture = _cameraController!.initialize();
        await _initializeControllerFuture;
        await _cameraController!.setFlashMode(FlashMode.off);
        // _currentFlashMode = FlashMode.off;
        // await _cameraController!.startImageStream(_processCameraImage);
        setState(() {
          _isCameraInitialized = true;
        });
        logger.i("📷 Camera initialized successfully");
      } else {
        logger.e("🚨 No cameras available");
      }
    } catch (e) {
      logger.e("❌ Error initializing camera: $e");
    }
  }

  // void _processCameraImage(CameraImage image) {
  //   if (_isReadyToDisplay) return; // already processed

  //   final bytes = image.planes[0].bytes;
  //   int sumBrightness = 0;

  //   for (var byte in bytes) {
  //     sumBrightness += byte;
  //   }

  //   final avgBrightness = sumBrightness / bytes.length;
  //   final now = DateTime.now();

  //   // Debounce
  //   if (now.difference(_lastFlashChange).inMilliseconds < 3000) return;

  //   const onThreshold = 45.0;
  //   const offThreshold = 60.0;

  //   if (_flashLocked) return;

  //   if (avgBrightness < onThreshold && _currentFlashMode != FlashMode.torch) {
  //     _cameraController?.setFlashMode(FlashMode.torch);
  //     setState(() {
  //       _currentFlashMode = FlashMode.torch;
  //       _flashLocked = true;
  //       _isReadyToDisplay = true; // ✅ Ready to show UI
  //     });
  //     _lastFlashChange = now;

  //     Timer(const Duration(seconds: 30), () {
  //       if (mounted) {
  //         setState(() => _flashLocked = false);
  //       }
  //     });
  //   } else if (avgBrightness > offThreshold && _currentFlashMode != FlashMode.off) {
  //     _cameraController?.setFlashMode(FlashMode.off);
  //     setState(() {
  //       _currentFlashMode = FlashMode.off;
  //       _isReadyToDisplay = true; // ✅ Ready to show UI
  //     });
  //     _lastFlashChange = now;
  //   } else {
  //     // if brightness is in between thresholds, still unlock view
  //     setState(() => _isReadyToDisplay = true); // ✅ Show anyway
  //   }
  // }

  Future<void> _capturePhoto() async {
    if (_isCapturing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      logger.e("🚨 Camera not ready");
      return;
    }
    setState(() => _isCapturing = true);
    try {
      await _initializeControllerFuture;
      if (_userFlashMode == FlashMode.always) {
        await _cameraController!.setFlashMode(FlashMode.torch);
        await Future.delayed(
            const Duration(milliseconds: 300)); // allow exposure
      }
      await _cameraController!.setFocusMode(FocusMode.locked);
      await _cameraController!.setExposureMode(ExposureMode.locked);
      final image = await _cameraController!.takePicture();
      logger.i('📸 Image captured at: ${image.path}');
      await _cameraController?.setFlashMode(FlashMode.off);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TakePictureScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      logger.e('🚨 Error capturing image: $e');
      _initializeCamera();
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    setState(() {
      _userFlashMode =
          (_userFlashMode == FlashMode.off) ? FlashMode.always : FlashMode.off;
    });
    logger.i("🔦 Flash mode toggled to: $_userFlashMode");
  }

  Future<void> _pickImageFromGallery() async {
    try { 
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        logger.i('📷 Image selected from gallery: ${pickedFile.path}');
        
        // ✅ Only turn off flash if the camera controller is initialized
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          await _cameraController!.setFlashMode(FlashMode.off);
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TakePictureScreen(imagePath: pickedFile.path),
            ),
          );
        }
      }
    } catch (e) {
      logger.e("❌ Error selecting image: $e");
    }
  }


  // Future<void> _pickImageFromGallery() async {
  //   try {
  //     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //     if (pickedFile != null) {
  //       logger.i('📷 Image selected from gallery: ${pickedFile.path}');
  //       // ✅ Immediately turn off flash before navigation
  //       await _cameraController!.setFlashMode(FlashMode.off);
  //       if (mounted) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) =>
  //                 TakePictureScreen(imagePath: pickedFile.path),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     logger.e("❌ Error selecting image: $e");
  //   }
  // }

  // Future<void> _toggleFlash() async {
  //   if (_cameraController == null) return;

  //   FlashMode newMode =
  //       (_userFlashMode == FlashMode.off) ? FlashMode.torch : FlashMode.off;

  //   _userFlashMode = newMode;
  //   await _cameraController!.setFlashMode(_userFlashMode);

  //   setState(() {
  //     _currentFlashMode = _userFlashMode;
  //   });

  //   logger.i("🔦 Flash set to: $_userFlashMode");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return;
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: vhh(context, 5)),
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/icons/logo.png',
                  width: 90,
                  height: 80,
                ),
              ),
              const Text(
                'Select photo to drop on your map',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'inter'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: vhh(context, 2)),
              Center(
                child: SizedBox(
                  width: vww(context, 96),
                  height: (() {
                    final desiredHeight =
                        MediaQuery.of(context).size.height * 0.6;
                    return desiredHeight.clamp(250.0, 450.0);
                  })(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        color: Colors.grey[300],
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      if (_isCameraInitialized)
                        CameraPreview(_cameraController!)
                      else
                        const Center(child: SpinningLoader()),

                      // Capture Button
                      Positioned(
                        bottom: 20,
                        child: ElevatedButton(
                          onPressed: _capturePhoto,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.white,
                          ),
                          child: _isCapturing
                              ? const SpinningLoader()
                              : const Icon(Icons.camera_alt,
                                  size: 30, color: Colors.black),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: IconButton(
                          icon: Icon(
                            _userFlashMode == FlashMode.always
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: vhh(context, 2)),
              SizedBox(
                height: 30,
                width: vhh(context, 20),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.5),
                        spreadRadius: -0.5,
                        blurRadius: 10,
                        offset: const Offset(0, 5), // shadow position
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _pickImageFromGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation:
                          0, // remove default shadow since we add custom one
                    ),
                    child: const Text(
                      'photo library',
                      style: TextStyle(
                        fontFamily: 'inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: -0.1,
                        color: Colors.black,
                      ),
                    ),
                  ),
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
