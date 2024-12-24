import 'package:RollaTravel/src/constants/app_button.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/auth/signup_step1_screen.dart';
import 'package:RollaTravel/src/screen/profile/profile_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/gestures.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
import 'package:logger/logger.dart';

class SigninScreen extends ConsumerStatefulWidget {
  const SigninScreen({super.key});

  @override
  ConsumerState<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends ConsumerState<SigninScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final logger = Logger();
  double screenHeight = 0;
  double keyboardHeight = 0;
  final bool _isKeyboardVisible = false;
  final _apiService = ApiService();
  bool _isLoading = false;
  String? usernameError;
  String? passwordError;

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
    _usernameController.addListener(() {
      _validateUsername(_usernameController.text);
    });

    _passwordController.addListener(() {
      _validatePassword(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateUsername(String value) {
    setState(() {
      if (value.isEmpty) {
        usernameError = 'Username is required';
      } else if (value.length < 3) {
        usernameError = 'Username must be at least 3 characters';
      } else {
        usernameError = null; // No error
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        passwordError = 'Password is required';
      } else if (value.length < 4) {
        passwordError = 'Password must be at least 6 characters';
      } else {
        passwordError = null; // No error
      }
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      if (_usernameController.text.isEmpty) {
        usernameError = 'Username is required';
      } else if (_usernameController.text.length < 3) {
        usernameError = 'Username must be at least 3 characters';
      } else {
        usernameError = null; // No error
      }

      if (_passwordController.text.isEmpty) {
        passwordError = 'Password is required';
      } else if (_passwordController.text.length < 4) {
        passwordError = 'Password must be at least 6 characters';
      } else {
        passwordError = null; // No error
      }
    });
   
    if (usernameError == null && passwordError == null) {
       setState(() {
        _isLoading = true;
      });
      
      try {
        final response = await _apiService.login(
          _usernameController.text,
          _passwordController.text,
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
            // Handle the case where userData is null
            GlobalVariables.userId = userData['id'];
            GlobalVariables.userName = userData['rolla_username'];
            GlobalVariables.realName = '${userData['first_name']} ${userData['last_name']}';
            GlobalVariables.happyPlace = userData['happy_place'];
            GlobalVariables.bio = userData['bio'];
            GlobalVariables.garage = userData['garage'];
            GlobalVariables.userImageUrl = userData['photo'];
            GlobalVariables.followingIds = userData['following_user_id'];
          }

          if(garagesData != null && garagesData.isNotEmpty) {
             GlobalVariables.garageLogoUrl = garagesData[0]['logo_path'];
          }
          
          GlobalVariables.odometer = response['trip_miles_sum'];
          GlobalVariables.tripCount = response['total_trips'];
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        } else {
          _showErrorDialog(response['message']);
        }
      } catch (e, stackTrace) {
          // Log and handle unexpected errors
          logger.e('Login error: $e\nStack trace: $stackTrace');
          _showErrorDialog('An unexpected error occurred. Please try again later.');
        } finally {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isKeyboardVisible == true) {
      screenHeight = MediaQuery.of(context).size.height;
    } else {
      screenHeight = 800;
      keyboardHeight = 0;
    }
    return WillPopScope (
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SizedBox.expand(
          child: SingleChildScrollView(
            child: FocusScope(
              child: Container(
                decoration: const BoxDecoration(
                  color: kColorWhite
                ),
                height: vhh(context, 100),
                child: Padding(padding: EdgeInsets.only(left: vww(context, 7), right: vww(context, 7)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: vhh(context, 15),
                      ),
                      Image.asset(
                        'assets/images/icons/logo.png',
                        width: vww(context, 24),
                      ),
                      SizedBox(height: vhh(context, 5),),
                      SizedBox(
                        width: vw(context, 38),
                        height: vh(context, 6.5),
                        child: TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          cursorColor: kColorGrey,
                          style: const TextStyle(color: kColorBlack, fontSize: 16, fontFamily: 'Kadaw'),
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: kColorGrey, width: 1),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: kColorBlack, width: 1.5),
                            ),
                            hintText: user_name,
                            errorText: (usernameError != null && usernameError!.isNotEmpty) ? usernameError : null,
                            hintStyle: const TextStyle(color: kColorGrey, fontSize: 14, fontFamily: 'Kadaw'),
                            contentPadding: const EdgeInsets.only(
                              top: -8, // Push hint closer to the top
                              bottom: -5, // Reduce space between text and underline
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.red, // Customize error message color
                              fontSize: 12, // Reduce font size of the error message
                              height: 0.5, // Adjust line height for tighter spacing
                              fontFamily: 'Kadaw'
                            ),
                            counterText: '',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: vw(context, 38),
                        height: vh(context, 6.5),
                        child: TextFormField(
                          controller: _passwordController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          cursorColor: kColorGrey,
                          obscureText: true,
                          style: const TextStyle(color: kColorBlack, fontSize: 16, fontFamily: 'Kadaw'),
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: kColorGrey, width: 1),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: kColorBlack, width: 1.5),
                            ),
                            hintText: password_title,
                            errorText: (passwordError != null && passwordError!.isNotEmpty) ? passwordError : null,
                            hintStyle: const TextStyle(color: kColorGrey, fontSize: 14, fontFamily: 'Kadaw'),
                            contentPadding: const EdgeInsets.only(
                              top: -8, // Push hint closer to the top
                              bottom: -5, // Reduce space between text and underline
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.red, // Customize error message color
                              fontSize: 12, // Reduce font size of the error message
                              height: 0.5, // Adjust line height for tighter spacing
                              fontFamily: 'Kadaw'
                            ),
                            counterText: '',
                          ),
                        ),
                      ),
                      _isLoading ? const CircularProgressIndicator() 
                      : Padding(
                          padding: EdgeInsets.only(left: vww(context, 15), right: vww(context, 15), top: vhh(context, 3)),
                          child: ButtonWidget(
                            btnType: ButtonWidgetType.loginText,
                            borderColor: kColorButtonPrimary,
                            textColor: kColorWhite,
                            fullColor: kColorButtonPrimary,
                            onPressed: () {
                              if (usernameError == null && passwordError == null) {
                                _handleLogin();
                              }else {
                                logger.i("Form validation failed or FormState is null.");
                              }
                            },
                          ),
                        ),
                          
                      
                      SizedBox( height: vhh(context, 3),),
                      SizedBox(height: vhh(context, 1)),
                      Padding(
                        padding: EdgeInsets.only(
                          left: vww(context, 10), 
                          right: vww(context, 10),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: dont_have_account,
                                style: TextStyle(
                                  color: kColorGrey,
                                  fontSize: 14,
                                  fontFamily: 'Kadaw'
                                ),
                              ),
                              TextSpan(
                                text: here_title,
                                style: const TextStyle(
                                  color: kColorHereButton,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: kColorHereButton,
                                  fontFamily: 'Kadaw'
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => const SignupStep1Screen(),
                                  )); 
                                },
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(
                        height: vhh(context, 15),
                      ),

                      Padding(
                        padding: EdgeInsets.only(
                          left: vww(context, 15), 
                          right: vww(context, 15),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: forgotPasswod,
                                style: TextStyle(
                                  color: kColorGrey,
                                  fontSize: 14,
                                  fontFamily: 'Kadaw'
                                ),
                              ),
                              TextSpan(
                                text: hereTitleNo,
                                style: const TextStyle(
                                  color: kColorHereButton,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: kColorHereButton,
                                  fontFamily: 'Kadaw'
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () {
                                },
                              ),
                              const TextSpan(
                                text: toReset,
                                style: TextStyle(
                                  color: kColorGrey,
                                  fontSize: 14,
                                  fontFamily: 'Kadaw'
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 5,),
                      Image.asset("assets/images/icons/us_flag.png",),
                    ],
                  ),
                )
              ),
            ),
          )
        ),
      )
    );
  }
}
