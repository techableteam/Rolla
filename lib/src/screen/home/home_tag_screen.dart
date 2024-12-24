import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';

class HomeTagScreen extends ConsumerStatefulWidget {
  const HomeTagScreen({super.key});

  @override
  ConsumerState<HomeTagScreen> createState() => HomeTagScreenState();
}

class HomeTagScreenState extends ConsumerState<HomeTagScreen> {
  final int _currentIndex = 0;
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
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/icons/logo.png',
                        height: vhh(context, 12)),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(height: vhh(context, 5)),
                          const Text(
                            "Users tagged in this post",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontFamily: 'Kadaw',
                            ),
                          ),
                          Image.asset("assets/images/icons/add_car.png",
                              width: vww(context, 8)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 30),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the screen
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: vww(context, 80), // Set the width of the Divider
                child: const Divider(
                  thickness: 0.6, // Set the thickness of the line
                  color: Colors.grey, // Optional: Set the color of the Divider
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            height: vhh(context, 6),
                            width: vhh(context, 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: kColorHereButton,
                                width: 2,
                              ),
                              image: const DecorationImage(
                                image: AssetImage(
                                    "assets/images/background/image1.png"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "@smith",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'KadawBold',
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(Icons.verified,
                                      color: Colors.blue, size: 16),
                                ],
                              ),
                              Text(
                                "Brain Smith",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                  fontFamily: 'Kadaw',
                                ),
                              )
                            ],
                          ),
                          const Spacer(),
                          Image.asset("assets/images/icons/reference.png"),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
      ),
    );
  }
}
