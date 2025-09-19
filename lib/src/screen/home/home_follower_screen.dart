import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/home/home_user_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/back_button_two_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:logger/logger.dart';

class HomeFollowScreen extends ConsumerStatefulWidget {
  final int? userid;
  final String? fromUser;
  const HomeFollowScreen({super.key, required this.userid, required this.fromUser});

  @override
  ConsumerState<HomeFollowScreen> createState() => HomeFollowScreenState();
}

class HomeFollowScreenState extends ConsumerState<HomeFollowScreen> with WidgetsBindingObserver {
  final int _currentIndex = 0;
  List<Map<String, dynamic>> followers = [];
  final logger = Logger();

  final GlobalKey _backButtonKey = GlobalKey();
  double backButtonWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFollowers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  Future<void> _loadFollowers() async {
    try {
      final apiservice = ApiService();
      followers = await apiservice.fetchFollowers(widget.userid!);
      logger.i(followers);
      setState(() {});
    } catch (e) {
      logger.i('Error loading followers: $e');
    }
  }

  void onBackPressed() {
    Navigator.pop(context);
  }

  void clickItem(Map<String, dynamic> follower) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeUserScreen(userId: follower['id'],)),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox =
          _backButtonKey.currentContext?.findRenderObject() as RenderBox;
      setState(() {
        backButtonWidth = renderBox.size.width;
      });
    });

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
              BackButtonTwoHeader(
                onBackPressed: onBackPressed, 
                title: 'Followers', 
                fromUser: widget.fromUser!, 
                backButtonKey: _backButtonKey, 
                backButtonWidth: backButtonWidth
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: followers.length,
                  itemBuilder: (context, index) {
                    final follower = followers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          clickItem(follower);
                        },
                        child: Row(
                          children: [
                            Container(
                              height: 50, // Adjust the size as needed
                              width: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kColorHereButton, // Adjust border color
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
                                      "@${follower['rolla_username']}",
                                      style: const TextStyle(
                                        fontFamily: 'inter',
                                        fontSize: 15,
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
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontFamily: 'inter',
                                    letterSpacing: -0.1,
                                  ),
                                )
                              ],
                            ),
                            const Spacer(),
                            Image.asset("assets/images/icons/reference.png"),
                          ],
                        ),
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
