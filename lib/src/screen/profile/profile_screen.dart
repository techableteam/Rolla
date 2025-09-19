import 'dart:convert';

import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/home/home_follower_screen.dart';
import 'package:RollaTravel/src/screen/home/home_view_screen.dart';
import 'package:RollaTravel/src/screen/profile/edit_profile.dart';
import 'package:RollaTravel/src/screen/profile/profile_following_screen.dart';
import 'package:RollaTravel/src/screen/profile/profile_map_widget.dart';
import 'package:RollaTravel/src/screen/settings/settings_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/translate/en.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:RollaTravel/src/utils/stop_marker_provider.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 4;
  bool isLiked = false;
  bool showLikesDropdown = false;
  String? followingCount;
  String? garageImageUrl;
  String? username;
  String? happyPlaceText;
  String? realName;
  String? bioText;
  String? userImageUrl;
  int? garageId;
  bool _isLoading = false;
  final logger = Logger();
  List<Map<String, dynamic>>? userTrips;
  Map<String, dynamic>? userInfo;
  int likes = 0;
  bool isLoadingTrips = true;
  LatLng? startPoint;
  LatLng? endPoint;
  List<LatLng> locations = [];
  late List<dynamic> dropPinsData = [];

  bool _isSelectMode = false;
  final List<int> _selectedMapIndices = [];

  @override
  void initState() {
    super.initState();
    _loadUserTrips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (mounted) {
        setState(() {
          this.keyboardHeight = keyboardHeight;
        });
      }
    });
  }

  Future<void> _loadUserTrips() async {
    try {
      final apiService = ApiService();
      final result = await apiService.fetchUserTrips(GlobalVariables.userId!);

      if (result.isNotEmpty) {
        final trips = result['trips'] as List<dynamic>;
        final userInfoList = result['userInfo'] as List<dynamic>?;
        // logger.i(userInfoList);
        final now = DateTime.now();
        List<Map<String, dynamic>> filteredTrips = [];

        for (var trip in trips) {
          if (trip['droppins'] != null) {
            List<dynamic> originalDroppins =
                List<dynamic>.from(trip['droppins']);
            List<dynamic> filteredDroppins = [];
            List<dynamic> filteredStopLocations = [];

            for (int i = 0; i < originalDroppins.length; i++) {
              final droppin = originalDroppins[i];
              bool includeDroppin = true;

              try {
                final delayStr = droppin['deley_time'];
                if (delayStr == null || delayStr.isEmpty) {
                  includeDroppin = true; 
                } else {
                  final delayTime = DateTime.parse(delayStr);
                  includeDroppin = !delayTime.isAfter(now);
                }
              } catch (e) {
                logger.e('Error parsing deley_time: $e');
                includeDroppin = true; // Include if error parsing
              }

              if (includeDroppin) {
                filteredDroppins.add(droppin);
                filteredStopLocations.add(trip['stop_locations'][i]);
              }
            }

            // Only add the trip if it has valid droppins
            if (filteredDroppins.isNotEmpty) {
              Map<String, dynamic> filteredTrip =
                  Map<String, dynamic>.from(trip);
              filteredTrip['droppins'] = filteredDroppins;
              filteredTrip['stop_locations'] = filteredStopLocations;
              filteredTrips.add(filteredTrip);
            }
          } else {
            // Add the trip if it has no droppins
            filteredTrips.add(Map<String, dynamic>.from(trip));
          }
        }
        // logger.i(userInfoList);
        // Extract user info and set state
        if (userInfoList != null && userInfoList.isNotEmpty) {
          final user = Map<String, dynamic>.from(userInfoList.first);

          setState(() {
            username = user['rolla_username'] ?? '@unknown';
            happyPlaceText = user['happy_place'];
            bioText = user['bio'] ?? "";
            realName = '${user['first_name']} ${user['last_name']}';

            if(user['photo'] != null && user['photo'].toString().isNotEmpty){
              GlobalVariables.userImageUrl = user['photo'];
            }

            final rawFollowing = user['following_user_id'];

            if (rawFollowing != null && rawFollowing.toString().isNotEmpty) {
              final parsedFollowing = jsonDecode(rawFollowing.toString());

              if (parsedFollowing is List) {
                followingCount = parsedFollowing.length.toString();
              } else {
                followingCount = "0";
              }
            } else {
              followingCount = "0";
            }

            final garageList = user['garage'] as List<dynamic>?;
            if (garageList != null && garageList.isNotEmpty) {
              setState(() {
                GlobalVariables.garageLogoUrl = garageList.first['logo_path'];
                garageImageUrl = garageList.first['logo_path'];
                GlobalVariables.garage = garageList.first['id'].toString();
              });
              logger.i(GlobalVariables.garageLogoUrl);
            } else {
              garageImageUrl = null;
              GlobalVariables.garageLogoUrl = garageImageUrl;
            }
          });
        }

        // Collect all droppins from filtered trips
        List<dynamic> allDroppins = [];
        for (var trip in filteredTrips) {
          if (trip['droppins'] != null) {
            allDroppins.addAll(trip['droppins']);
          }
        }

        // Update state with filtered trips and droppins
        setState(() {
          userTrips =
              filteredTrips.reversed.toList().cast<Map<String, dynamic>>();
          dropPinsData =
              allDroppins.isNotEmpty ? allDroppins.reversed.toList() : [];
          isLoadingTrips = false;
        });
      } else {
        setState(() {
          userTrips = [];
          dropPinsData = [];
          isLoadingTrips = false;
        });
        logger.i("No trips found for user.");
      }
    } catch (error) {
      logger.e('Error fetching user trips: $error');
      setState(() {
        userTrips = [];
        dropPinsData = [];
        isLoadingTrips = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showLoadingDialog() {
    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SpinningLoader(), // Progress bar
              SizedBox(width: 20),
              Text("Loading..."), // Loading text
            ],
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (_isLoading) {
      Navigator.of(context).pop();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSelectTrip(int tripId) {
    setState(() {
      if (_selectedMapIndices.contains(tripId)) {
        _selectedMapIndices.remove(tripId); // Deselect the trip
      } else {
        _selectedMapIndices.add(tripId); // Select the trip
      }
      logger.i('Selected trip IDs: $_selectedMapIndices');
    });
  }

  void _onSelectButtonPressed() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedMapIndices.clear();
    });
  }

  void _onDeleteButtonPressed() async {
    final prefs = await SharedPreferences.getInstance();
    int? localTripId = prefs.getInt('tripId');
    final apiService = ApiService();
    bool allDeletedSuccessfully = true;
    _showLoadingDialog();
    for (int tripId in _selectedMapIndices) {
      try {
        if (tripId == localTripId) {
          await prefs.remove("tripId");
          await prefs.remove("dropcount");
          await prefs.remove("destination_text");
          await prefs.remove("start_date");
          await prefs.remove("caption_text");
          ref.read(isTripStartedProvider.notifier).state = false;
          GlobalVariables.isTripStarted = false;
          ref.read(staticStartingPointProvider.notifier).state =
              ref.read(movingLocationProvider);
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
          GlobalVariables.droppinCount = 0;
          ref.read(pathCoordinatesProvider.notifier).state = [];
        }
        final result = await apiService.deleteTrip(tripId);

        if (result['statusCode'] != true) {
          allDeletedSuccessfully = false;
          logger.e('Failed to delete trip with ID: $tripId');
          break;
        }
      } catch (e) {
        allDeletedSuccessfully = false;
        logger.e('Error deleting trip with ID: $tripId. $e');
        break;
      }
    }
    _hideLoadingDialog();

    if (allDeletedSuccessfully) {
      setState(() {
        _isSelectMode = !_isSelectMode;
        _selectedMapIndices.clear();
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  void _onFollowers() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomeFollowScreen(
                  userid: GlobalVariables.userId!,
                  fromUser: "You",
                )));
  }

  void _onFollowing() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            ProfileFollowingScreen(userid: GlobalVariables.userId!),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _onSettingButtonClicked() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            const SettingsScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _onEditButtonClicked() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>EditProfileScreen(
          username: username!,
          happyPlace: happyPlaceText ?? '',
          realName: realName!,
          bio: bioText ?? '',
          selectedImage: null,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _goViewScreen(String viewlist, String imagePath, int dropid) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeViewScreen(
        viewdList: viewlist, 
        imagePath: imagePath,
        droppinId: dropid,
        )),
    );
  }

  Future<void> _showImageDialog(
    List<dynamic> droppins, 
    int droppinIndex,   
  ) async {
    final apiservice = ApiService();
    int viewcount = droppins[droppinIndex]['viewed_count'] ?? 0;
    // logger.i(droppins[droppinIndex]);
    // Get the initial liked_users and viewlist
    List<dynamic> likedUsers = droppins[droppinIndex]['liked_users'];
    bool isLiked = likedUsers.map((user) => user['id']).contains(GlobalVariables.userId);
    int droppinlikes = likedUsers.length;

    // Show dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption and Close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final text = droppins[droppinIndex]['image_caption'] ?? '';
                        final textSpan = TextSpan(
                          text: text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontFamily: 'inter',
                            letterSpacing: -0.1,
                          ),
                        );
                        final textPainter = TextPainter(
                          text: textSpan,
                          textAlign: TextAlign.start,
                          textDirection: TextDirection.ltr,
                          maxLines: 3,
                        )..layout(maxWidth: constraints.maxWidth - 40);
                        int lineCount = textPainter.computeLineMetrics().length;
                        double height = lineCount * 24.0; 
                        height = height < 50 ? 50 : (height > 80 ? 80 : height);
                        return SizedBox(
                          height: height,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    fontFamily: 'inter',
                                    letterSpacing: -0.1,
                                  ),
                                  overflow: TextOverflow.ellipsis, 
                                  maxLines: 3,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.black),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // PageView for swiping through images
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: PageView.builder(
                      controller: PageController(initialPage: droppinIndex),
                      itemCount: droppins.length,
                      itemBuilder: (context, index) {
                        final droppin = droppins[index];
                        return Image.network(
                          droppin['image_path'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 100),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return const Center(
                                child: SpinningLoader(),
                              );
                            }
                          },
                        );
                      },
                      onPageChanged: (index) {
                        setState(() {
                          droppinIndex = index;
                          likedUsers = droppins[droppinIndex]['liked_users'];
                          isLiked = likedUsers.map((user) => user['id']).contains(GlobalVariables.userId);
                          droppinlikes = likedUsers.length;
                          if (droppins[droppinIndex]['viewed_count'] != null && droppins[droppinIndex]['viewed_count'].isNotEmpty) {
                            viewcount = droppins[droppinIndex]['viewed_count'];
                          } else {
                            viewcount = 0;
                          }
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  // Like and View count buttons
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final response = await apiservice.toggleDroppinLike(
                              userId: GlobalVariables.userId!,
                              droppinId: droppins[droppinIndex]['id'],
                              flag: !isLiked,
                            );
                            if (response != null && response['statusCode'] == true) {
                              setState(() {
                                isLiked = !isLiked;
                                if (isLiked) {
                                  droppinlikes++;
                                  droppins[droppinIndex]['liked_users'].add({
                                    'id' : GlobalVariables.userId!,
                                    'photo': GlobalVariables.userImageUrl,
                                    'first_name': GlobalVariables.realName?.split(' ')[0],
                                    'last_name': GlobalVariables.realName?.split(' ')[1],
                                    'rolla_username': GlobalVariables.userName,
                                  });
                                } else {
                                  droppinlikes--;
                                  droppins[droppinIndex]['liked_users'].removeWhere((user) =>
                                      user['rolla_username'] == GlobalVariables.userName);
                                }
                                setState(() {
                                  likes = _calculateTotalLikes(droppins);
                                });
                              });
                              logger.i(response['message']);
                            } else {
                              logger.e('Failed to toggle like');
                            }
                          },
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showLikesDropdown = !showLikesDropdown;
                            });
                          },
                          child: Text(
                            '$droppinlikes likes',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: -0.1,
                              fontFamily: 'inter',
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _goViewScreen(
                              droppins[droppinIndex]['view_count'], 
                              droppins[droppinIndex]['image_path'],
                              droppins[droppinIndex]['id'],                              
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF933F10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$viewcount Views',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: -0.1,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showLikesDropdown)
                    Column(
                      children: likedUsers.map((user) {
                        final photo = user['photo'] ?? '';
                        final firstName = user['first_name'] ?? 'Unknown';
                        final lastName = user['last_name'] ?? '';
                        final username = user['rolla_username'] ?? '@unknown';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 2,
                                  ),
                                  image: photo.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: photo.isEmpty ? const Icon(Icons.person, size: 20) : null,
                              ),
                              const SizedBox(width: 5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$firstName $lastName',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: -0.1,
                                      fontFamily: 'inter',
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      letterSpacing: -0.1,
                                      color: Colors.grey,
                                      fontFamily: 'inter',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _calculateTotalLikes(List<dynamic> droppins) {
    return droppins.fold<int>(
      0,
      (sum, droppin) => sum + (droppin['liked_users'].length as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return;
          }
        },
        child: isLoadingTrips
            ? const Center(child: SpinningLoader())
            : SingleChildScrollView(
                child: Container(
                  decoration: const BoxDecoration(
                    color: kColorWhite,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: vww(context, 0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: vhh(context, 5)),
                      Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          Positioned(
                            top: vhh(context, 0),
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/icons/logo.png',
                                  width: 90,
                                  height: 80,
                                ),
                                const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "@$username",
                                      style: const TextStyle(
                                        color: kColorBlack,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'inter',
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(width: 2,),
                                    Image.asset(
                                        'assets/images/icons/verify1.png',
                                        width: vww(context, 5),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                const SizedBox(width: 10,),
                                Row(
                                  children: [
                                    if (_isSelectMode)
                                      SizedBox(
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed: _onDeleteButtonPressed,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kColorStafGrey,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 0, vertical: 2),
                                          ),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'inter',
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (_isSelectMode)
                                      const SizedBox(
                                        width: 3,
                                      ),
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        onPressed: _onSelectButtonPressed,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kColorStafGrey,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                        ),
                                        child: Text(
                                          _isSelectMode ? 'Cancel' : 'Select',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            fontFamily: 'inter',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 10,
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: vhh(context, 7.5)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Container(),
                                Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/icons/trips1.png',
                                      width: vww(context, 20),
                                    ),
                                    Text(
                                      userTrips?.length.toString() ?? "0",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: kColorButtonPrimary,
                                        fontFamily: 'interBold',
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: vhh(context, 15),
                                  width: vhh(context, 15),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: kColorHereButton,
                                        width: 2,
                                      ),
                                      image: GlobalVariables.userImageUrl !=
                                              null
                                          ? DecorationImage(
                                              image: NetworkImage(GlobalVariables
                                                  .userImageUrl!), // Use NetworkImage for URL
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                                ),
                                Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/icons/follower1.png',
                                      width: vww(context, 21),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _onFollowers();
                                      },
                                      child: Text(
                                        followingCount?? "0",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: kColorButtonPrimary,
                                          fontFamily: 'interBold',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: vww(context, 2)),
                        child: Column(
                          children: [
                            SizedBox(height: vhh(context, 1)),
                            Text(
                              realName ?? "",
                              style: const TextStyle(
                                  color: kColorBlack,
                                  fontSize: 17,
                                  letterSpacing: -0.1,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'inter'),
                            ),
                            SizedBox(height: vhh(context, 0.5)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10), // ✅ Horizontal padding
                              child: Text(
                                bioText ?? "",
                                maxLines: 1, // ✅ Limit to one line
                                overflow: TextOverflow.ellipsis, // ✅ Truncate if too long
                                style: const TextStyle(
                                  color: kColorGrey,
                                  fontSize: 15,
                                  letterSpacing: -0.1,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'inter',
                                ),
                              ),
                            ),

                            SizedBox(height: vhh(context, 2)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: vww(context, 30),
                                  height: 23,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kColorStrongBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      shadowColor:
                                          Colors.black.withValues(alpha: 0.9),
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2, vertical: 2),
                                    ),
                                    onPressed: () {
                                      _onEditButtonClicked();
                                    },
                                    child: Text("Edit Profile",
                                        style: TextStyle(
                                            color: kColorWhite,
                                            fontSize: 36.sp,
                                            letterSpacing: -0.1,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'inter')),
                                  ),
                                ),
                                SizedBox(
                                  width: vww(context, 30),
                                  height: 23,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kColorStrongBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      shadowColor:
                                          Colors.black.withValues(alpha: 0.9),
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2, vertical: 2),
                                    ),
                                    onPressed: () {
                                      _onFollowing();
                                    },
                                    child: Text("Following",
                                        style: TextStyle(
                                            color: kColorWhite,
                                            fontSize: 36.sp,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.1,
                                            fontFamily: 'inter')),
                                  ),
                                ),
                                SizedBox(
                                  width: vww(context, 30),
                                  height: 23,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kColorStrongBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      shadowColor:
                                          Colors.black.withValues(alpha: 0.9),
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2, vertical: 2),
                                    ),
                                    onPressed: () {
                                      _onSettingButtonClicked();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.settings, // Settings icon
                                          size: 16,
                                          color: kColorWhite,
                                        ),
                                        const SizedBox(
                                            width:
                                                2), // Spacing between icon and text
                                        Text(
                                          'Settings',
                                          style: TextStyle(
                                              color: kColorWhite,
                                              fontSize: 36.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.1,
                                              fontFamily:
                                                  'inter' // Customize font size
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: vhh(context, 1)),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                   const Text(
                                      happyplace,
                                      style: TextStyle(
                                          color: kColorBlack,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.1,
                                          fontFamily: 'inter'),
                                    ),
                                    Text(
                                      happyPlaceText ?? "",
                                      style: const TextStyle(
                                          color: kColorButtonPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.1,
                                          fontFamily: 'inter'),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      mygarage,
                                      style: TextStyle(
                                          color: kColorBlack,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.1,
                                          fontFamily: 'inter'),
                                    ),
                                    garageImageUrl != null
                                        ? Image.network(
                                            garageImageUrl!,
                                            width: 25, // Adjust width as needed
                                            height:
                                                25, // Adjust height as needed
                                          )
                                        : const Text(""),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: vhh(context, 1)),
                            SizedBox(
                              height: 100,
                              child: (dropPinsData).isEmpty
                                  ? const Center(
                                      child: Text("No drop pins available",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              letterSpacing: -0.1,
                                              fontFamily: 'inter')),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: dropPinsData.length,
                                      itemBuilder: (context, index) {
                                        final dropPin = dropPinsData[index]
                                            as Map<String, dynamic>;
                                        final String imagePath =
                                            dropPin['image_path'] ?? '';
                                        // final String caption =
                                        //     dropPin['image_caption'] ??
                                        //         'No caption';
                                        // final List<dynamic> likedUsers =
                                        //     dropPin['liked_users'] ?? [];

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          child: GestureDetector(
                                            onTap: () {
                                              // _showImageDialog(
                                              //     imagePath,
                                              //     caption,
                                              //     likedUsers.length,
                                              //     likedUsers);
                                              _showImageDialog(dropPinsData, index);
                                            },
                                            child: imagePath.isNotEmpty
                                                ? Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.black
                                                              .withValues(
                                                                  alpha: 0.5),
                                                          Colors.transparent
                                                        ],
                                                        begin: Alignment
                                                            .bottomCenter,
                                                        end:
                                                            Alignment.topCenter,
                                                      ),
                                                    ),
                                                    child: Image.network(
                                                      imagePath,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        } else {
                                                          return const Center(
                                                              child:
                                                                  SpinningLoader());
                                                        }
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Icon(
                                                            Icons.broken_image,
                                                            size: 100);
                                                      },
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.image_not_supported,
                                                    size: 100),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        color: kColorWhite,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Divider(
                                height: 1,
                                thickness: 2,
                                color: kColorHereButton,
                              ),
                            ),
                            SizedBox(height: vhh(context, 1)),
                            userTrips == null
                                ? const Center(child: SpinningLoader())
                                : userTrips!.isEmpty
                                    ? const Center(
                                        child: Text("No trips to display"))
                                    : Column(
                                        children: List.generate(
                                          (userTrips!.length / 2).ceil(),
                                          (rowIndex) => Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    height: 110,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.black,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: TripMapWidget(
                                                      trip: userTrips![
                                                          rowIndex * 2],
                                                      index: rowIndex * 2,
                                                      isSelectMode:
                                                          _isSelectMode,
                                                      selectedMapIndices:
                                                          _selectedMapIndices,
                                                      onSelectTrip:
                                                          _onSelectTrip,
                                                      onDeleteButtonPressed:
                                                          _onDeleteButtonPressed,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 12,
                                                  ),
                                                  if (rowIndex * 2 + 1 <
                                                      userTrips!.length)
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.4,
                                                      height: 110,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: Colors.black,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: TripMapWidget(
                                                        trip: userTrips![
                                                            rowIndex * 2 + 1],
                                                        index: rowIndex * 2 + 1,
                                                        isSelectMode:
                                                            _isSelectMode,
                                                        selectedMapIndices:
                                                            _selectedMapIndices,
                                                        onSelectTrip:
                                                            _onSelectTrip,
                                                        onDeleteButtonPressed:
                                                            _onDeleteButtonPressed,
                                                      ),
                                                    ),
                                                  if (rowIndex * 2 + 1 >=
                                                      userTrips!.length)
                                                    SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.4),
                                                ],
                                              ),
                                              if (rowIndex <
                                                  (userTrips!.length / 2)
                                                          .ceil() -
                                                      1)
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                        height:
                                                            vhh(context, 1)),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
