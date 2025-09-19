import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/auth/signin_screen.dart';
import 'package:RollaTravel/src/screen/profile/block_screen.dart';
import 'package:RollaTravel/src/screen/profile/profile_screen.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/back_button_header.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/utils/stop_marker_provider.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 5;
  bool isPrivateAccount = true;
  final logger = Logger();
  final GlobalKey _backButtonKey = GlobalKey();
  double backButtonWidth = 0;

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
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ref.read(isTripStartedProvider.notifier).state = false;
    GlobalVariables.isTripStarted = false;
    ref.read(staticStartingPointProvider.notifier).state = ref.read(movingLocationProvider);
    ref.read(movingLocationProvider.notifier).state = null;
    ref.read(markersProvider.notifier).state = [];
    ref.read(totalDistanceProvider.notifier).state = 0.0;
    GlobalVariables.totalDistance = 0.0;
    GlobalVariables.tripCaption = null;
    GlobalVariables.song1 = null;
    GlobalVariables.song2 = null;
    GlobalVariables.song3 = null;
    GlobalVariables.song4 = null;
    GlobalVariables.editDestination = null;
    GlobalVariables.selectedUserIds = [];
    ref.read(pathCoordinatesProvider.notifier).state = [];

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SigninScreen()),
      );
    }
  }

  void _goBlockedAccountScreen () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUserScreen()));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'inter',
              letterSpacing: -0.1,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'inter',
              letterSpacing: -0.1,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "No",
                style: TextStyle(
                  fontFamily: 'inter',
                  letterSpacing: -0.1,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (title == "Logout") {
                  _logout();
                } else {
                  _logout();
                }
              },
              child: const Text(
                "Yes",
                style: TextStyle(
                  fontFamily: 'inter',
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onBackPressed() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
              const ProfileScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = _backButtonKey.currentContext?.findRenderObject() as RenderBox;
      setState(() {
        backButtonWidth = renderBox.size.width;
      });
    });

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return;
          }
        },
        child: Scaffold(
          backgroundColor: kColorWhite,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: FocusScope(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: vhh(context, 90),
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: kColorWhite,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: vhh(context, 6)),
                        BackButtonHeader(
                          onBackPressed: _onBackPressed,
                          title: settings,
                          backButtonKey: _backButtonKey,
                          backButtonWidth: backButtonWidth,
                        ),
                        SizedBox(height: vhh(context, 3)),
                        const Divider(color: kColorStrongGrey, thickness: 1, height: 1,),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                privateaccount,
                                style: TextStyle(
                                  fontSize: 16,
                                  letterSpacing: -0.1,
                                  fontFamily: 'inter',
                                ),
                              ),
                              SizedBox(height: vhh(context, 1)),
                              Text(
                                privateaccountdescrition1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontFamily: 'inter',
                                  letterSpacing: -0.1,
                                ),
                              ),
                              SizedBox(height: vhh(context, 2)),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: vhh(context, 3),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _goBlockedAccountScreen();
                              },
                              child: const Text(
                                'Blocked accounts',
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                  letterSpacing: -0.1,
                                  fontFamily: 'interBold',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: vh(context, 4),),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showConfirmationDialog(
                                  title: "Logout",
                                  message: "Are you sure you want to logout?");
                              },
                              child: const Text(
                                'Log out',
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                  letterSpacing: -0.1,
                                  fontFamily: 'interBold',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                logoutdescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: 'inter',
                                  letterSpacing: -0.1,
                                  fontSize: 13,
                                ),
                                softWrap: true, // Ensures the text wraps to the next line
                                overflow: TextOverflow.visible, // Ensures overflow is handled
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: vh(context, 4),),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showConfirmationDialog(
                                  title: "Delete Account",
                                  message:
                                      "Are you sure you want to delete your account?");
                              },
                              child: const Text(
                                deleteaccount,
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                  letterSpacing: -0.1,
                                  fontFamily: 'interBold',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                deletedescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: 'inter',
                                  letterSpacing: -0.1,
                                  fontSize: 13,
                                ),
                                softWrap: true, // Ensures the text wraps to the next line
                                overflow: TextOverflow.visible, // Ensures overflow is handled
                              ),
                            ),
                          ],
                        ),

                      
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
