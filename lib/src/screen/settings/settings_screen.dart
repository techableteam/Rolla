import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/auth/signin_screen.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 0;
  bool isPrivateAccount = true;

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

  Future<bool> _onWillPop() async {
    return false;
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
            style: const TextStyle(fontFamily: 'Kadaw'),
          ),
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Kadaw'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "No",
                style: TextStyle(fontFamily: 'Kadaw'),
              ),
            ),
            TextButton(
              onPressed: () {
                if (title == "Logout") {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SigninScreen()));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SigninScreen()));
                }
              },
              child: const Text(
                "Yes",
                style: TextStyle(fontFamily: 'Kadaw'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
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
                        SizedBox(height: vhh(context, 10)),
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
                                width: vww(context, 5),
                              ),
                            ),
                            const Text(
                              settings,
                              style: TextStyle(
                                color: kColorBlack,
                                fontSize: 18,
                                fontFamily: 'KadawBold',
                              ),
                            ),
                            Container(),
                          ],
                        ),
                        SizedBox(height: vhh(context, 1)),
                        const Divider(color: kColorGrey, thickness: 1),

                        // Private Account Section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                private_account,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'KadawBold',
                                ),
                              ),
                              SizedBox(height: vhh(context, 1)),
                              Text(
                                private_account_descrition,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'KadawBold',
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile(
                                      value: true,
                                      groupValue: isPrivateAccount,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isPrivateAccount = value ?? true;
                                        });
                                      },
                                      title: const Text(private),
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile(
                                      value: false,
                                      groupValue: isPrivateAccount,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isPrivateAccount = value ?? false;
                                        });
                                      },
                                      title: const Text(
                                        public,
                                        style: TextStyle(fontFamily: 'Kadaw'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: vhh(context, 6),
                        ),
                        ListTile(
                          title: const Text(
                            logout,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              fontFamily: 'KadawBold',
                            ),
                          ),
                          subtitle: Text(
                            logout_description,
                            style: TextStyle(
                                color: Colors.grey[600], fontFamily: 'Kadaw'),
                          ),
                          onTap: () {
                            _showConfirmationDialog(
                                title: "Logout",
                                message: "Are you sure you want to logout?");
                          },
                        ),
                        ListTile(
                          title: const Text(
                            delete_account,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              fontFamily: 'KadawBold',
                            ),
                          ),
                          subtitle: Text(
                            delete_description,
                            style: TextStyle(
                                color: Colors.grey[600], fontFamily: 'Kadaw'),
                          ),
                          onTap: () {
                            _showConfirmationDialog(
                                title: "Delete Account",
                                message:
                                    "Are you sure you want to delete your account?");
                          },
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
