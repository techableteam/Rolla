import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:logger/logger.dart';

class HomeSoundScreen extends ConsumerStatefulWidget {
  final String tripSound;
  const HomeSoundScreen({super.key, required this.tripSound});

  @override
  ConsumerState<HomeSoundScreen> createState() => HomeSoundScreenState();
}

class HomeSoundScreenState extends ConsumerState<HomeSoundScreen> with WidgetsBindingObserver {
  final int _currentIndex = 5;
  final logger = Logger();
  double keyboardHeight = 0;
  List<String> songList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    logger.i(widget.tripSound);
    if (widget.tripSound.isNotEmpty && widget.tripSound != 'null') {
      songList =
          widget.tripSound.split(',').map((song) => song.trim()).toList();
    }
    if (songList.isEmpty) {
      songList = [
        'No songs added',
        'No songs added',
        'No songs added',
        'No songs added'
      ];
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 45),
              Row(
                children: [
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      'assets/images/icons/allow-left.png',
                      width: vww(context, 5),
                      height: 20,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Playlist',
                        style: TextStyle(
                          fontSize: 21,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.1
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: List.generate(
                    songList
                        .length, // Generate as many text widgets as there are songs
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: _buildSongContainer(songList[index], index + 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
      ),
    );
  }

  Widget _buildSongContainer(String songTitle, int index) {
    Color borderColor =
        (index % 2 == 0) ? kColorHereButton : kColorButtonPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
      width: double.infinity, // Make the container take full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: borderColor, width: 2.0),
      ),
      child: Text(
        songTitle, // Display the song title or "No songs added"
        style: const TextStyle(
            fontSize: 13, fontFamily: 'inter', letterSpacing: -0.1),
      ),
    );
  }
}
