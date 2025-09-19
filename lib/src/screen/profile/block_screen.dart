import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/settings/settings_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:logger/logger.dart';

class BlockedUserScreen extends ConsumerStatefulWidget {
  const BlockedUserScreen({super.key});

  @override
  ConsumerState<BlockedUserScreen> createState() => BlockedUserScreenState();
}

class BlockedUserScreenState extends ConsumerState<BlockedUserScreen> {
  final int _currentIndex = 5;
  double keyboardHeight = 0;
  List<Map<String, dynamic>> followers = [];
  final logger = Logger();

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

    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    try {
      final apiservice = ApiService();
      followers = await apiservice.fetchBlockUsers(GlobalVariables.userId!);
      // logger.i(followers);
      setState(() {});
    } catch (e) {
      logger.i('Error loading followers: $e');
    }
  }

  void unblockClicked(userid) async {
    try {
      final apiservice = ApiService();
      final result = await apiservice.blockUser(GlobalVariables.userId!, userid!);

      if (result['statusCode'] == true) {
        if(!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const BlockedUserScreen()),
        );
      }
    } catch (e) {
      logger.i('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          return; 
        }
      },
      child: Scaffold(
        backgroundColor: kColorWhite,
        body: Center(
          child: Column(
            children: [
              SizedBox(
                height: vhh(context, 6),
              ),
              Row(
                children: [
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                    },
                    child: Image.asset(
                      'assets/images/icons/allow-left.png',
                      width: vww(context, 5),
                      height: 20,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Blocked Account',
                            style: TextStyle(
                              fontSize: 21,
                              letterSpacing: -0.1,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: vh(context, 2),),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),),

              Expanded(
                child: ListView.builder(
                  itemCount: followers.length,
                  itemBuilder: (context, index) {
                    final follower = followers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            height: 50, // Adjust the size as needed
                            width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey, // Adjust border color
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: follower['photo'] != null
                                  ? Image.network(
                                      follower['photo'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.error),
                                    )
                                  : const Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    follower['rolla_username'] ?? ' ',
                                    style: const TextStyle(
                                      fontFamily: 'inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.verified,
                                      color: Colors.blue, size: 16),
                                ],
                              ),
                              Text(
                                '${follower['first_name'] ?? ''} ${follower['last_name'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'inter',
                                  letterSpacing: -0.1,
                                ),
                              )
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              unblockClicked(follower['id']);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 5),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red, width: 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'unblock user',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                          )

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
