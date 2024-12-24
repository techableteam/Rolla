import 'package:RollaTravel/src/constants/app_button.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/auth/login_userflow.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class SignupStep2Screen extends ConsumerStatefulWidget {
  final String firstName;
  final String lastName;
  final String emailAddress;
  const SignupStep2Screen({
    super.key, 
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
  });

  @override
  ConsumerState<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends ConsumerState<SignupStep2Screen> {
  final _usernameController = TextEditingController();
  final _passwordController= TextEditingController();
  final _rePasswordController = TextEditingController();
  final logger = Logger();
  // String get userName => _usernameController.text;
  // String get password => _passwordController.text;
  // String get rePassword => _rePasswordController.text;
  bool isPasswordVisible = false;
  double screenHeight = 0;
  double keyboardHeight = 0;
  final bool _isKeyboardVisible = false;
  bool _isLoading = false;
  bool isChecked = false;
  String? _selectedOption;
  String? userNameError;
  String? passwordError;
  String? rePasswordError;

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  void _onCreateAccount() async{
    if (_usernameController.text.isEmpty) {
      setState(() {
        userNameError = "Username is required";
      });
      return;
    } else if (_passwordController.text.isEmpty) {
      setState(() {
        passwordError = "Password is required";
      });
      return;
    } else if (_rePasswordController.text.isEmpty) {
      setState(() {
        rePasswordError = "Re-enter password is required";
      });
      return;
    } else if (_passwordController.text != _rePasswordController.text) {
      setState(() {
        rePasswordError = "Passwords do not match";
      });
      return;
    } else if(_selectedOption == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select how you heard about us.'),
        ),
      );
      return;
    } else {
      logger.i(_selectedOption);
      setState(() {
        _isLoading = true; // Show loading spinner
      });
      final apiService = ApiService();
      try {
        final response = await apiService.register(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.emailAddress,
          password: _passwordController.text,
          rollaUsername: _usernameController.text,
          hearRolla: _selectedOption!
        );

        if (response['success'] == true) {
          // Navigate to LoginUserFlowScreen on successful registration
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginUserFlowScreen(),
              ),
            );
          }
        } else {
          // Show error message for failed registration
          _showErrorDialog(response['message']);
        }
      } catch (e) {
        // Handle unexpected errors
        _showErrorDialog('An unexpected error occurred. Please try again.');
      } finally {
        setState(() {
          _isLoading = false; // Hide loading spinner
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: vhh(context, 8),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Image.asset(
                            'assets/images/icons/allow-left.png',
                            width: vww(context, 15),
                            height: 20,
                          ),
                        ),
                        
                        Image.asset(
                          'assets/images/icons/logo.png',
                          width: vww(context, 25),
                        ),

                        Container(width: vww(context, 15),),
                      ],
                    ),
                    SizedBox(height: vhh(context, 3),),
                    SizedBox(
                      width: vw(context, 38),
                      height: vh(context, 6.5),
                      child: TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        cursorColor: kColorGrey,
                        style: const TextStyle(color: kColorBlack, fontSize: 14, fontFamily: 'Kadaw'),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: kColorGrey, width: 1),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: kColorBlack, width: 1.5),
                          ),
                          errorText: userNameError,
                          hintText: "Rolla Username",
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
                        onChanged: (value) {
                          setState(() {
                            if (value.length < 4) {
                              userNameError = 'Username must be at least 6 characters.';
                            } else if(value.isEmpty){
                              userNameError = "username is required";
                            }
                            else {
                              userNameError = null; // No error
                            }
                          });
                        },
                      ),
                    ),

                    SizedBox(
                      width: vw(context, 38),
                      height: vh(context, 6.5),
                      child: TextField(
                        controller: _passwordController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        obscureText: true,
                        cursorColor: kColorGrey,
                        style: const TextStyle(color: kColorBlack, fontSize: 14, fontFamily: 'Kadaw'),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: kColorGrey, width: 1),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: kColorBlack, width: 1.5),
                          ),
                          errorText: passwordError,
                          hintText: password_title,
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
                        onChanged: (value) {
                          setState(() {
                            if (value.length < 6) {
                              passwordError = 'Password must be at least 6 characters.';
                            } else if(value.isEmpty){
                              passwordError = "Password is required";
                            }
                            else {
                              passwordError = null; // No error
                            }
                          });
                        },
                      ),
                    ),

                    SizedBox(
                      width: vw(context, 38),
                      height: vh(context, 6.5),
                      child: TextField(
                        controller: _rePasswordController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        obscureText: true,
                        cursorColor: kColorGrey,
                        style: const TextStyle(color: kColorBlack, fontSize: 14, fontFamily: 'Kadaw'),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: kColorGrey, width: 1),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: kColorBlack, width: 1.5),
                          ),
                          errorText: rePasswordError, 
                          hintText: re_enter_password,
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
                        onChanged: (value) {
                        setState(() {
                          if (value != _passwordController.text) {
                            rePasswordError = 'Passwords do not match.';
                          } else if (value.length < 6) {
                            rePasswordError = 'Password must be at least 6 characters.';
                          } else if(value.isEmpty){
                            rePasswordError = 'Re-enter password is required.';
                          } 
                          else {
                            rePasswordError = null; // No error
                          }
                        });
                      },
                      ),
                    ),

                    SizedBox(
                      height: vhh(context, 5),                     
                    ),
                    
                    Padding(
                      padding: EdgeInsets.only(top: vhh(context, 1), left: vww(context, 10), right: vww(context, 10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            how_did_you_hear,
                            style: TextStyle(fontSize: 14, fontFamily: 'KadawBold'),
                          ),
                          SizedBox(height: vhh(context, 1)),
                          RadioListTile<String>(
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: EdgeInsets.zero, // Remove extra padding
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4), // Adjust density to reduce spacing
                            title: const Padding(
                              padding: EdgeInsets.only(left: 20), // Indent the text by approximately 10 inches
                              child: Text(i_saw_ad, style: TextStyle(fontFamily: 'Kadaw'),),
                            ),
                            value: i_saw_ad,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            title: const Padding(
                              padding: EdgeInsets.only(left: 20), // Indent the text by approximately 10 inches
                              child: Text(recommendation, style: TextStyle(fontFamily: 'Kadaw'),),
                            ),
                            value: recommendation,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            title: const Padding(
                              padding: EdgeInsets.only(left: 20), // Indent the text by approximately 10 inches
                              child: Text(other, style: TextStyle(fontFamily: 'Kadaw'),),
                            ),
                            value: other,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    _isLoading ? const CircularProgressIndicator() 
                      : Padding(
                        padding: EdgeInsets.only(left: vww(context, 15), right: vww(context, 15), top: vhh(context, 2)),
                        child: ButtonWidget(
                          btnType: ButtonWidgetType.createAccountTitle,
                          borderColor: kColorCreateButton,
                          textColor: kColorWhite,
                          fullColor: kColorCreateButton,
                          onPressed: () {
                            _onCreateAccount();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
        ),
      )
    );
  }
}
