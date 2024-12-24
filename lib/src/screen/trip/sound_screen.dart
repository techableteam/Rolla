import 'package:flutter/material.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';

class SoundScreen extends ConsumerStatefulWidget {
  final String initialSound;

  const SoundScreen({super.key, required this.initialSound});

  @override
  ConsumerState<SoundScreen> createState() => SoundScreenState();
}

class SoundScreenState extends ConsumerState<SoundScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 2;
  final TextEditingController _soundController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _soundController = TextEditingController(text: widget.initialSound);
  }

  @override
  void dispose() {
    super.dispose();
    _soundController.dispose();
  }

  Future<bool> _onWillPop() async {
    return false;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context, _soundController.text);
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
                        'My soundtrack',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'KadawBold'
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the space taken by the IconButton
                ],
              ),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 24, color: Colors.black),
                    const SizedBox(width: 8),

                    Expanded(
                      child: TextField(
                        controller: _soundController,
                        decoration: InputDecoration(
                            hintText: 'Search locations',
                            hintStyle: const TextStyle(fontSize: 16, fontFamily: 'Kadaw'), // Set font size for hint text
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Set inner padding
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              borderSide: const BorderSide(color: Colors.black, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              borderSide: const BorderSide(color: Colors.black, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              borderSide: const BorderSide(color: Colors.black, width: 1.0),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          style: const TextStyle(fontSize: 16, fontFamily: 'Kadaw'),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
      ), 
    );
  }
}