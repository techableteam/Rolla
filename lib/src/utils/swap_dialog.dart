import 'dart:ui';  // For ImageFilter
import 'package:flutter/material.dart';

class SwipeableImageViewer extends StatefulWidget {
  final List<dynamic> droppins;
  final int currnetIndex;

  const SwipeableImageViewer({
    super.key, 
    required this.droppins,
    required this.currnetIndex});

  @override
  SwipeableImageViewerState createState() => SwipeableImageViewerState();
}

class SwipeableImageViewerState extends State<SwipeableImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentIndex = widget.currnetIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background blur effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0), // Just to keep the container occupied
            ),
          ),
        ),
        // Your dialog
        Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.droppins[_currentIndex]['image_caption'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontFamily: 'inter',
                        letterSpacing: -0.1,
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
              // PageView for swiping through images
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.9,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.droppins.length,
                  itemBuilder: (context, index) {
                    final droppin = widget.droppins[index];
                    return Image.network(
                      droppin['image_path'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      },
                    );
                  },
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              // You can display other information like likes, view count, etc.
            ],
          ),
        ),
      ],
    );
  }
}
