import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/droppin/select_locaiton_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

class TakePictureScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const TakePictureScreen({super.key, required this.imagePath});

  @override
  ConsumerState<TakePictureScreen> createState() => TakePictureScreenState();
}

class TakePictureScreenState extends ConsumerState<TakePictureScreen> {
  bool showLikes = true;
  final logger = Logger();
  final int _currentIndex = 3;
  final LatLng photoLocation = const LatLng (0, 0);
  final TextEditingController _captionController = TextEditingController();

  Future<bool> _onWillPop() async {
    return false;
  }

  Future<void> _handleLocationSelection() async {
    // logger.i(showLikes);
    if (_captionController.text.isEmpty) {
      // Show error dialog if caption is empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Warning!'),
          content: const Text('Please enter a caption before proceeding.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to the next screen with the entered caption
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocationScreen(
          selectedLocation: photoLocation,
          caption: _captionController.text,
          imagePath: widget.imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Center(
          child: Column(
            children: [
              // Logo and close button aligned at the top
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/icons/logo.png', height: vhh(context, 12)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 30),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the screen
                      },
                    ),
                  ],
                ),
              ),

              // Image with overlays in a constrained height
              SizedBox(
                height: vhh(context, 60),
                width: vww(context, 96),
                child: Stack(
                  children: [
                    // Display the image as the background with constrained height
                    Center(
                      child: widget.imagePath.isNotEmpty
                          ? SizedBox(
                              width: vww(context, 100), // Set width
                              height: vhh(context, 100), // Set height
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(child: Text('No image selected.', style: TextStyle(fontFamily: 'Kadaw'),)),
                    ),

                    // Overlay elements on top of the image
                    Column(
                      children: [
                        // Caption text field with padding and blue border
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            color: Colors.transparent, // Semi-transparent background
                            child: TextField(
                              controller: _captionController,
                              decoration: InputDecoration(
                                hintText: 'Caption...',
                                hintStyle: const TextStyle(fontFamily: 'Kadaw'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.9),
                              ),
                              style: const TextStyle(fontFamily: 'Kadaw'),
                            ),
                          ),
                        ),
                      
                        const Spacer(),
                        // Radio buttons for "hide likes" and "show likes"
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  color: Colors.white.withOpacity(0.9),
                                  width: vww(context, 40),
                                  height: vhh(context, 4),
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    children: [
                                      Radio<bool>(
                                        value: false,
                                        groupValue: showLikes,
                                        onChanged: (value) {
                                          setState(() {
                                            showLikes = value!;
                                          });
                                        },
                                        activeColor: Colors.blue,
                                      ),
                                      const Text('hide likes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontFamily: 'Kadaw'),),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  color: Colors.white.withOpacity(0.9),
                                  width: vww(context, 40),
                                  height: vhh(context, 4),
                                  child: Row(
                                    children: [
                                      Radio<bool>(
                                        value: true,
                                        groupValue: showLikes,
                                        onChanged: (value) {
                                          setState(() {
                                            showLikes = value!;
                                          });
                                        },
                                        activeColor: Colors.blue,
                                      ),
                                      const Text('show likes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontFamily: 'Kadaw'),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10,),
              // Select Location button
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _handleLocationSelection,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: kColorButtonPrimary, // Button color
                      minimumSize: const Size(150, 30), // Set button width and height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Rounded corners
                      ),
                      elevation: 4, // Shadow depth
                      shadowColor: Colors.black.withOpacity(0.25), // Shadow color
                    ),
                    child: const Text(
                      'Select Location',
                      style: TextStyle(color: Colors.white, fontFamily: 'Kadaw', fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
      ),
    );
  }
}
