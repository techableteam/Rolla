import 'package:RollaTravel/src/constants/app_button.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/auth/signup_step2_screen.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupStep1Screen extends ConsumerStatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  ConsumerState<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends ConsumerState<SignupStep1Screen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _useremailController= TextEditingController();
  final _countryController = TextEditingController();
  bool isPasswordVisible = false;
  double screenHeight = 0;
  double keyboardHeight = 0;
  final bool _isKeyboardVisible = false;
  bool isChecked = false;
  String? firstNameError;
  String? lastNameError;
  String? emailAddressError;

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
    _firstNameController.addListener(() {
      _validateFirstName(_firstNameController.text);
    });

    _lastNameController.addListener(() {
      _validateLastName(_lastNameController.text);
    });

    _useremailController.addListener(() {
      _validateEmailAddress(_useremailController.text);
    });

  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _useremailController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  void _validateFirstName(String value) {
    setState(() {
      if (value.isEmpty) {
        firstNameError = 'First name is required';
      } else {
        firstNameError = null; // No error
      }
    });
  }

  void _validateLastName(String value) {
    setState(() {
      if (value.isEmpty) {
        lastNameError = 'Last name is required';
      } else {
        lastNameError = null; // No error
      }
    });
  }

  void _validateEmailAddress(String value) {
    setState(() {
      if (value.isEmpty) {
        emailAddressError = 'Email address is required';
      } else {
        emailAddressError = null; // No error
      }
    });
  }

  void _onPressContinue(){
    setState(() {
      if (_firstNameController.text.isEmpty) {
        firstNameError = 'First name is required';
      } else {
        firstNameError = null; // No error
      }

      if (_lastNameController.text.isEmpty) {
        lastNameError = 'Last name is required';
      } else {
        lastNameError = null; // No error
      }

      if (_useremailController.text.isEmpty) {
        emailAddressError = 'Email address is required';
      } else {
        emailAddressError = null; // No error
      }
    });

    if(firstNameError == null && lastNameError == null && emailAddressError == null){
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => SignupStep2Screen(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          emailAddress: _useremailController.text,
        ),
      ));
    }
    
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
                      height: vhh(context, 10),
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

                    SizedBox(height: vhh(context, 5),),
                    SizedBox(
                      width: vw(context, 38),
                      height: vh(context, 6.5),
                      child: TextField(
                        controller: _firstNameController,
                        keyboardType: TextInputType.name,
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
                          hintText: "First name",
                          errorText: (firstNameError != null && firstNameError!.isNotEmpty) ? firstNameError : null,
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
                      child: TextField(
                        controller: _lastNameController,
                        keyboardType: TextInputType.name,
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
                          hintText: "Last name",
                          errorText: (lastNameError != null && lastNameError!.isNotEmpty) ? lastNameError : null,
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
                      child: TextField(
                        controller: _useremailController,
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
                          hintText: "Email address",
                          errorText: (emailAddressError != null && emailAddressError!.isNotEmpty) ? emailAddressError : null,
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

                    Padding(
                      padding: EdgeInsets.only(left: vww(context, 15), right: vww(context, 15), top: vhh(context, 5)),
                      child: ButtonWidget(
                        btnType: ButtonWidgetType.continueText,
                        borderColor: kColorButtonPrimary,
                        textColor: kColorWhite,
                        fullColor: kColorButtonPrimary,
                        onPressed: () {
                          if(firstNameError == null && lastNameError == null && emailAddressError == null){
                            _onPressContinue();
                          }
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
