import 'package:RollaTravel/src/screen/auth/signin_screen.dart';
import 'package:RollaTravel/src/screen/home/home_screen.dart';
// import 'package:RollaTravel/src/screen/profile/profile_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (username != null && username.isNotEmpty) {
      _handleLogin(username, password!);
    } else {
      _goLoginScreen();
    }
  }

  Future<void> _handleLogin(String userName, String passWord) async {
    try {
      final response = await _apiService.login(
        userName,
        passWord,
      );

      if (response['token'] != null && response['token'].isNotEmpty) {
        final Map<String, dynamic>? userData = response['userData'] != null
            ? response['userData'] as Map<String, dynamic>
            : null;

        final List<dynamic>? dropPinsData = response['droppins'] != null
            ? response['droppins'] as List<dynamic>
            : null;

        final List<dynamic>? garagesData = response['garages'] != null
            ? response['garages'] as List<dynamic>?
            : null;

        if (dropPinsData != null) {
          GlobalVariables.dropPinsData = dropPinsData;
        }
        if (userData != null) {
          // logger.i("splash userdata : $userData");
          GlobalVariables.userId = userData['id'];
          GlobalVariables.userName = userData['rolla_username'];
          GlobalVariables.realName =
              '${userData['first_name']} ${userData['last_name']}';
          GlobalVariables.happyPlace = userData['happy_place'];
          GlobalVariables.bio = userData['bio'];
          if (userData['garage'] != null && userData['garage'].isNotEmpty) {
            GlobalVariables.garageLogoUrl = userData['garage'][0]['logo_path'];
          }
          GlobalVariables.userImageUrl = userData['photo'];
          GlobalVariables.followingIds = userData['following_user_id'];
        }

        if (garagesData != null && garagesData.isNotEmpty) {
          GlobalVariables.garageLogoUrl = garagesData[0]['logo_path'];
        }

        GlobalVariables.odometer = response['trip_miles_sum'];
        GlobalVariables.tripCount = response['total_trips'];
        if (response['trips'] != null && response['trips'].isNotEmpty) {
          int tripId = response['trips'][0];  
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt("tripId", tripId);
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if(!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Login error: $e\nStack trace: $stackTrace');
      _showErrorDialog('Network not working now...');
    } finally {
      // setState(() {
      //   _isLoading = false;
      // });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _goLoginScreen() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SigninScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: FocusScope(
          child: Container(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: vh(context, 35)),
                Image.asset(
                  'assets/images/icons/rolla_white_icon.png',
                  width: 150.0,
                  height: 150.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
