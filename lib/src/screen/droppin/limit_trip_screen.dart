import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:RollaTravel/src/utils/index.dart';

class LimitDropPinScreen extends ConsumerStatefulWidget{
  const LimitDropPinScreen({super.key});
  @override
  ConsumerState<LimitDropPinScreen> createState() => LimitDropPinScreenState();
}

class LimitDropPinScreenState extends ConsumerState<LimitDropPinScreen> with WidgetsBindingObserver{
  double screenHeight = 0;
  final int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }
  
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: vhh(context, 5),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Image.asset(
                  'assets/images/icons/logo.png',
                  width: 90,
                  height: 80,
                ),
              ),
              const Spacer(),
              const Center(
                child: Text(
                  "Maximum of 7 pins/trip. You have \nreached the limit. To drop more pins, \nplease start a new trip",
                  style: TextStyle(
                    fontFamily: 'inter',
                    fontSize: 17,
                    letterSpacing: -0.1,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/images/icons/logo.png',
                  width: 90,
                  height: 80,
                ),
              ),
              SizedBox(
                height: vhh(context, 2),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }

}