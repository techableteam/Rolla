import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/home/home_screen.dart';
import 'package:RollaTravel/src/screen/home/home_user_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/back_button_header.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final int? userid;
  const NotificationScreen({super.key, required this.userid});

  @override
  ConsumerState<NotificationScreen> createState() => NotificationScreenState();
}

class NotificationScreenState extends ConsumerState<NotificationScreen> with WidgetsBindingObserver {
  final int _currentIndex = 5;
  List<Map<String, dynamic>> followers = [];
  final logger = Logger();
  bool isloding = false;

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
      followers = await apiservice.fetchNotificationUsers(widget.userid!);
      logger.i(followers);
      if (mounted) setState(() {});
    } catch (e) {
      logger.i('Error loading followers: $e');
    }
  }

  Future<void> _acceptButton (int userId) async {
    try {
      final apiservice = ApiService();
      final result = await apiservice.requestFollowAccept(GlobalVariables.userId!, userId);
      logger.i(result);
      if(result['statusCode'] == true){
        if(!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationScreen(userid: GlobalVariables.userId,)),
        );
        _loadFollowers();
      }
    } catch (e) {
      logger.i('Error loading followers: $e');
    }
  }

  Future<void> _acceptRequestCloseButton (int userId, String fromItem) async {
    try {
      final apiservice = ApiService();
      if(fromItem == "follow"){
        final result = await apiservice.viewAcceptNotification(GlobalVariables.userId!, userId);
        logger.i(result);
        if(result['statusCode'] == true){
          _loadFollowers();
        }
      } else if (fromItem == "tag") {
        final result = await apiservice.viewedTaged(GlobalVariables.userId!, userId);
        logger.i(result);
        if(result['statusCode'] == true){
          _loadFollowers();
        }
      } else if (fromItem == "comment"){
        final result = await apiservice.viewedCommented(GlobalVariables.userId!, userId);
        logger.i(result);
        if(result['statusCode'] == true){
          _loadFollowers();
        }
      } else if (fromItem == "like"){
        final result = await apiservice.viewedliked(GlobalVariables.userId!, userId);
        logger.i(result);
        if(result['statusCode'] == true){
          _loadFollowers();
        }
      } else if(fromItem == "followed"){
        final result = await apiservice.tappedFollowed(GlobalVariables.userId!, userId);
        logger.i(result);
        if(result['statusCode'] == true){
          _loadFollowers();
        }
      }
    } catch (e) {
      logger.i('Error loading followers: $e');
    }
  }

  Future<void> _denyButton (int userId) async {
    try {
      final apiservice = ApiService();
      final result = await apiservice.removePendingFollow(GlobalVariables.userId!, userId);
      logger.i(result);
      if(result['statusCode'] == true){
        if(!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationScreen(userid: GlobalVariables.userId,)),
        );
        _loadFollowers();
      }
    } catch (e) {
      logger.i('Error loading followers: $e');
    }
  }

  String _getFollowStatusText(String from, String username) {
    switch (from) {
      case 'pending':
        return 'Requested to follow you';
      case 'follow':
        return 'You accepted @$username follow request.';
      case 'tag':
        return "Tagged you in @$username's post";
      case 'comment':
        return 'commented on your post';
      case 'like':
        return 'liked your post';
      case 'followed':
        return '@$username accepted your follow request';
      default:
        return 'Unknown status';
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('MM/dd/yyyy').format(parsedDate);
    } catch (e) {
      return '';
    }
  }

  Future<void> _markViewed(String fromItem, int userId) {
    final api = ApiService();
    final me = GlobalVariables.userId!;
    switch (fromItem) {
      case 'follow':
        return api.viewedFollowingNotification(me, userId);
      case 'pending':
        return api.viewedPendingNotification(me, userId);
      case 'followed':
        return api.viewedFollowedNotification(me, userId);
      case 'tag':
        return api.viewedTagNotification(me, userId);
      case 'comment':
        return api.viewedCommentNotification(me, userId);
      case 'like':
        return api.viewedlikeNotification(me, userId);
      default:
        return Future.value();
    }
  }

  /// Marks MANY notifications as viewed (batch).
  Future<void> _markManyViewed(Iterable<Map<String, dynamic>> items) async {
    final futures = <Future>[];
    for (final f in items) {
      final fromItem = f['from'] as String?;
      final userId = f['id'] as int?;
      if (fromItem != null && userId != null) {
        futures.add(_markViewed(fromItem, userId));
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void _onBackPressed() async {
    final unviewedFollowers = followers.where((f) => f['viewed'] == false);

    setState(() => isloding = true);

    try {
      await _markManyViewed(unviewedFollowers);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const HomeScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      logger.e("Error while marking followers as viewed: $e");
    } finally {
      if (mounted) setState(() => isloding = false);
    }
  }

  Future<void> _onItemTap(Map<String, dynamic> follower) async {
    // logger.i(follower);
    final apiservice = ApiService();
    final from = follower['from'] as String?;
    final tripId = follower['tripId'];
    final userId = follower['id'] as int?;

    if (from == null || userId == null) return;

    setState(() {
      for (var f in followers) {
        if (f['viewed'] == false) f['viewed'] = true;
      }
    });

    try {
      await _markManyViewed(followers.where((f) => f['viewed'] == false));



      if (mounted) {
        if (from == 'tag') {
          try {
            final result = await apiservice.clickedCommentNotification(GlobalVariables.userId!, userId);
            logger.i(result);

            if (result['statusCode'] == true) {
              await Future.wait([
                _loadFollowers(),
              ]);

              if (mounted) {
                GlobalVariables.homeTripID = tripId;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              }
            } else {
              logger.e("Error in pending notification: ${result['message']}");
            }
          } catch (e) {
            logger.e('Error during pending notification handling: $e');
          }
        } else if (from == 'comment') {
          try {
            final result = await apiservice.clickedCommentNotification(GlobalVariables.userId!, userId);
            logger.i(result);

            if (result['statusCode'] == true) {
              await Future.wait([
                _loadFollowers(),
              ]);

              if (mounted) {
                GlobalVariables.homeTripID = follower['trip'];
                GlobalVariables.openComment = true;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              }
            } else {
              logger.e("Error in pending notification: ${result['message']}");
            }
          } catch (e) {
            logger.e('Error during pending notification handling: $e');
          }
        } else if (from == 'like') {
          try {
            final result = await apiservice.clickedlikeNotification(GlobalVariables.userId!, userId);
            logger.i(result);

            if (result['statusCode'] == true) {
              await Future.wait([
                _loadFollowers(),
              ]);

              if (mounted) {
                GlobalVariables.homeTripID = tripId;
                GlobalVariables.likedDroppinId = follower['likeid'];
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              }
            } else {
              logger.e("Error in pending notification: ${result['message']}");
            }
          } catch (e) {
            logger.e('Error during pending notification handling: $e');
          }
        } else if (from == 'followed') {
          try {
            final result = await apiservice.clickedFollowedNotification(GlobalVariables.userId!, userId);
            logger.i(result);

            if (result['statusCode'] == true) {
              await Future.wait([
                _loadFollowers(),
              ]);

              if (mounted) {
                GlobalVariables.homeTripID = tripId;
                Navigator.push(context, MaterialPageRoute(builder: (_) => HomeUserScreen(userId: userId)));
              }
            } else {
              logger.e("Error in pending notification: ${result['message']}");
            }
          } catch (e) {
            logger.e('Error during pending notification handling: $e');
          }
        } else if (from == 'follow') {
          try {
            final result = await apiservice.clickedFollowingNotification(GlobalVariables.userId!, userId);
            logger.i(result);

            if (result['statusCode'] == true) {
              await Future.wait([
                _loadFollowers(),
              ]);

              if (mounted) {
                GlobalVariables.homeTripID = tripId;
                Navigator.push(context, MaterialPageRoute(builder: (_) => HomeUserScreen(userId: userId)));
              }
            } else {
              logger.e("Error in pending notification: ${result['message']}");
            }
          } catch (e) {
            logger.e('Error during pending notification handling: $e');
          }
        } 
        else if (from == 'pending') {
          try {
            final result = await apiservice.clickedPendingNotification(GlobalVariables.userId!, userId);
            logger.i(result);

            if (result['statusCode'] == true) {
              await Future.wait([
                _loadFollowers(),
              ]);

              if (mounted) {
                GlobalVariables.homeTripID = tripId;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HomeUserScreen(userId: userId)),
                );
              }
            } else {
              logger.e("Error in pending notification: ${result['message']}");
            }
          } catch (e) {
            logger.e('Error during pending notification handling: $e');
          }
        }
      }
    } catch (e) {
      logger.e('Failed to mark viewed for $from/$userId: $e');
      // Make sure to check if the widget is still mounted before updating the UI
      if (mounted) {
        setState(() {
          for (var f in followers) {
            if (f['viewed'] == true) f['viewed'] = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextForBack = _backButtonKey.currentContext;
      if (contextForBack != null) {
        final RenderBox renderBox = contextForBack.findRenderObject() as RenderBox;
        final width = renderBox.size.width;
        if (backButtonWidth != width) {
          setState(() {
            backButtonWidth = width;
          });
        }
      }
    });

    if (isloding) {
      return const Scaffold(
        body: Center(child: SpinningLoader()),
      );
    }

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
              SizedBox(height: vhh(context, 7),),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
                child: BackButtonHeader(
                  onBackPressed: _onBackPressed,
                  title: 'Notifications',
                  backButtonKey: _backButtonKey,
                  backButtonWidth: backButtonWidth,
                ),
              ),
              SizedBox(height: vhh(context, 0.5),),
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
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20),
                      child: InkWell(
                        onTap: () => _onItemTap(follower), // <- use safe handler
                        child: Container(
                          decoration: BoxDecoration(
                            color: follower['clicked'] == true
                                ? Colors.white
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                height: vhh(context, 6),
                                width: vhh(context, 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: kColorHereButton,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: follower['photo'] != null
                                      ? Image.network(
                                          follower['photo'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
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
                                          fontSize: 13,
                                          letterSpacing: -0.1,
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.verified,
                                          color: Colors.blue, size: 14),
                                    ],
                                  ),
                                  follower['from'] == 'pending'?
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.4, // Adjust width to fit your layout
                                      child: Text(
                                        _getFollowStatusText(follower['from'], follower['rolla_username']),
                                        maxLines: 1, // Ensure it's a single line
                                        overflow: TextOverflow.ellipsis, // Show "..." for overflow
                                        style: const TextStyle(
                                          fontFamily: 'inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ) 
                                    : SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.6, // Adjust width to fit your layout
                                      child: Text(
                                        _getFollowStatusText(follower['from'], follower['rolla_username']),
                                        maxLines: 1, // Ensure it's a single line
                                        overflow: TextOverflow.ellipsis, // Show "..." for overflow
                                        style: const TextStyle(
                                          fontFamily: 'inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    _formatDate(follower['follow_date'] ?? ''),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: kColorStrongGrey,
                                      fontFamily: 'inter',
                                      letterSpacing: -0.1,
                                    ),
                                  )
                                ],
                              ),
                              const Spacer(),
                              follower['from'] == 'pending'
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          height: 23,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _acceptButton(follower['id']);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                                side: BorderSide(
                                                  color: Colors.grey.withValues(alpha: 0.4),
                                                  width: 0.5,
                                                ),
                                              ),
                                              padding: EdgeInsets.zero,
                                              shadowColor: Colors.black.withValues(alpha: 0.4),
                                              elevation: 4,
                                            ),
                                            child: const Text(
                                              'Accept',
                                              style: TextStyle(
                                                fontFamily: 'inter',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.1,
                                                color: kColorGreen,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        SizedBox(
                                          width: 60,
                                          height: 23,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _denyButton(follower['id']);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                                side: BorderSide(
                                                  color: Colors.grey.withValues(alpha: 0.4),
                                                  width: 0.5,
                                                ),
                                              ),
                                              padding: EdgeInsets.zero,
                                              shadowColor: Colors.black.withValues(alpha: 0.4),
                                              elevation: 4,
                                            ),
                                            child: const Text(
                                              'Deny',
                                              style: TextStyle(
                                                fontFamily: 'inter',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.1,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        _acceptRequestCloseButton(follower['id'], follower['from']);
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
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
