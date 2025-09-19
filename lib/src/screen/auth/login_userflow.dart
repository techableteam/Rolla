import 'package:RollaTravel/src/constants/app_button.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/auth/signin_screen.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginUserFlowScreen extends ConsumerStatefulWidget {
  const LoginUserFlowScreen({super.key});

  @override
  ConsumerState<LoginUserFlowScreen> createState() =>
      _LoginUserFlowScreenState();
}

class _LoginUserFlowScreenState extends ConsumerState<LoginUserFlowScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final bool _isKeyboardVisible = false;
  int _carouselIndex = 0;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isKeyboardVisible == true) {
      screenHeight = MediaQuery.of(context).size.height;
    } else {
      screenHeight = 800;
      keyboardHeight = 0;
    }
    return PopScope(
        canPop: false, // Prevents default back navigation
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return; // Prevent pop action
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SizedBox.expand(
              child: SingleChildScrollView(
            child: FocusScope(
              child: Container(
                  decoration: const BoxDecoration(color: kColorWhite),
                  height: vhh(context, 100),
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: vww(context, 7), right: vww(context, 7)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: vhh(context, 10),
                        ),
                        Image.asset(
                          'assets/images/icons/logo.png',
                          width: vww(context, 25),
                        ),
                        SizedBox(
                          height: vhh(context, 2),
                        ),
                        const Text(
                          howtocreatepost,
                          style: TextStyle(
                              color: kColorGrey,
                              fontSize: 16,
                              fontFamily: 'inter'),
                        ),
                        SizedBox(
                          height: vhh(context, 2),
                        ),
                        SizedBox(
                          height: vhh(context, 50),
                          child: PageView(
                            onPageChanged: (index) {
                              setState(() {
                                _carouselIndex = index;
                              });
                            },
                            children: [
                              Image.asset(
                                'assets/images/icons/rolla_logo.png',
                              ),
                              Image.asset('assets/images/icons/rolla_logo.png'),
                              Image.asset('assets/images/icons/rolla_logo.png'),
                            ],
                          ),
                        ),

                        // Carousel Indicators
                        SizedBox(
                          height: vhh(context, 2),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: _carouselIndex == index ? 8 : 6,
                              height: _carouselIndex == index ? 8 : 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _carouselIndex == index
                                    ? Colors.brown
                                    : Colors.grey,
                              ),
                            );
                          }),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: vww(context, 15),
                              right: vww(context, 15),
                              top: vhh(context, 3)),
                          child: ButtonWidget(
                            btnType: ButtonWidgetType.loginText,
                            borderColor: kColorButtonPrimary,
                            textColor: kColorWhite,
                            fullColor: kColorButtonPrimary,
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SigninScreen(),
                                  ));
                            },
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
          )),
        ));
  }
}
