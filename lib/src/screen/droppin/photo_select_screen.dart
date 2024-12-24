import 'package:RollaTravel/src/screen/droppin/take_picture_screen.dart';
import 'package:RollaTravel/src/utils/index.dart';
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

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initializeCamera();
    } else {
      // Handle the case where the user denies the permission
      if(mounted){
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission', style: TextStyle(fontFamily: 'Kadaw'),),
            content: const Text('Camera permission is required to take photos.', style: TextStyle(fontFamily: 'Kadaw'),),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;

        _cameraController = CameraController(
          firstCamera,
          ResolutionPreset.medium,
        );

        _initializeControllerFuture = _cameraController!.initialize();
        setState(() {}); // Trigger a rebuild to ensure the FutureBuilder gets the updated future
      } else {
        logger.i('No cameras available');
      }
    } catch (e) {
      logger.i('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _getImageFromCamera() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      // Handle the captured image
      logger.i('Image captured at: ${image.path}');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TakePictureScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      logger.i(e);
    }
  }

  Future<void> _getImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Handle the selected image
        logger.i('Image selected from gallery: ${pickedFile.path}');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakePictureScreen(imagePath: pickedFile.path),
            ),
          );
        }
      }
    } catch (e) {
      logger.i(e);
    }
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('assets/images/icons/logo.png', height: 100),
              ),
              const Text(
                'Select photo to drop \non your map',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontFamily: 'Kadaw'
                ),
                textAlign: TextAlign.center,
              ),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: vhh(context, 50),
                  child: Stack(
                    alignment: Alignment.center, // Center contents in the stack
                    children: [
                      Container(
                        color: Colors.grey[300], // Set the background to a light gray color
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            return CameraPreview(_cameraController!);
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                      Positioned(
                        bottom: 20, // Position the button 20 pixels from the bottom of the Stack
                        child: ElevatedButton(
                          onPressed: _getImageFromCamera,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20), // Adjust button size
                            backgroundColor: Colors.white, // Set button color if desired
                          ),
                          child: const Icon(Icons.camera_alt, size: 30, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getImageFromGallery,
                child: const Text('Photo Library', style: TextStyle(fontFamily: 'Kadaw'),),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}