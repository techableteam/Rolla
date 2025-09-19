import 'package:RollaTravel/src/screen/home/home_screen.dart';
import 'package:RollaTravel/src/screen/home/home_sound_screen.dart';
import 'package:RollaTravel/src/screen/home/home_tag_screen.dart';
import 'package:RollaTravel/src/screen/home/home_user_screen.dart';
import 'package:RollaTravel/src/screen/home/home_view_screen.dart';
import 'package:RollaTravel/src/screen/profile/profile_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:flutter/material.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final int dropIndex;
  final Function(int) onLikesUpdated;
  final bool openComment;

  const PostWidget({
    super.key,
    required this.post,
    required this.dropIndex,
    required this.onLikesUpdated,
    required this.openComment,
  });

  @override
  PostWidgetState createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> with WidgetsBindingObserver {
  late MapController mapController;
  List<LatLng> routePoints = [];
  bool showComments = false;
  bool isAddComments = false;
  bool isLiked = false;
  bool showLikesDropdown = false;
  bool isView = false;
  final TextEditingController _addCommitController = TextEditingController();
  List<String>? stopAddresses;
  List<LatLng> locations = [];
  LatLng? startPoint;
  LatLng? lastDropPoint;
  LatLng? endPoint;
  bool isLoading = true;
  final ApiService apiService = ApiService();
  int likes = 0;
  bool isFollowing = false;
  int viewcount = 0;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    WidgetsBinding.instance.addObserver(this);

    if (widget.openComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          showComments = true;
          GlobalVariables.openComment = false;
        });
      });
    }

    if (GlobalVariables.likedDroppinId != null) {
      final filteredDroppins = widget.post['droppins'].where((droppin) {
        try {
          final delay = DateTime.parse(droppin['deley_time']);
          return delay.isBefore(DateTime.now());
        } catch (_) {
          return true;
        }
      }).toList();

      int index = filteredDroppins.indexWhere((d) => d['id'] == GlobalVariables.likedDroppinId);
      if (index != -1 && widget.post['user']['id'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showImageDialog(filteredDroppins, index, widget.post['user']['id']);
          GlobalVariables.likedDroppinId = null;
        });
      }
    }
  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRoutePoints();
      startAndendMark();
      _getlocaionts().then((_) {
        setState(() {
          isLoading = false;
          likes = _calculateTotalLikes(widget.post['droppins']);
        });
      });
    });
    // logger.i(widget.post['droppins']);
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

  String get mapStyleUrl {
    const accessToken =
        'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw';
    final styleId = () {
      final style = widget.post['map_style'];
      // logger.i(style);
      switch (style) {
        case "1":
          return 'satellite-v9';
        case "2":
          return 'light-v10';
        case "3":
          return 'dark-v10';
        case '0':
        case null:
        default:
          return 'streets-v11';
      }
    }();

    return "https://api.mapbox.com/styles/v1/mapbox/$styleId/tiles/{z}/{x}/{y}?access_token=$accessToken";
  }

  Future<void> startAndendMark() async {
    try {
      if (widget.post['start_location'] != null &&
          widget.post['start_location'].toString().contains("LatLng")) {
        final regex =
            RegExp(r"LatLng\(latitude:([\d\.-]+), longitude:([\d\.-]+)\)");
        final match = regex.firstMatch(widget.post['start_location']);

        if (match != null) {
          final double startlatitude = double.parse(match.group(1)!);
          final double startlongitude = double.parse(match.group(2)!);
          setState(() {
            startPoint = LatLng(startlatitude, startlongitude);
          });
        }
      } else {
        final startCoordinates =
            await getCoordinates(widget.post['start_address']);
        setState(() {
          startPoint = LatLng(
              startCoordinates['latitude']!, startCoordinates['longitude']!);
        });
      }
    } catch (e) {
      logger.e('Failed to fetch start address coordinates: $e');
    }

    try {
      if (widget.post['destination_location'] != null) {
        final locationString = widget.post['destination_location'];
        final regex = RegExp(
            r"LatLng\(\s*latitude:\s*([\d\.-]+),\s*longitude:\s*([\d\.-]+)\s*\)");
        final match = regex.firstMatch(locationString ?? '');
        if (match != null) {
          final double endlatitude = double.parse(match.group(1)!);
          final double endlongitude = double.parse(match.group(2)!);
          setState(() {
            endPoint = LatLng(endlatitude, endlongitude);
          });
        } else {
          logger.i("No match found for destination location.");
        }
      }
    } catch (e) {
      logger.e('Failed to fetch destination address coordinates: $e');
    }
  }

  void _adjustZoom() {
    if (lastDropPoint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bounds = LatLngBounds(
          LatLng(
              lastDropPoint!.latitude - 0.03, lastDropPoint!.longitude - 0.03),
          LatLng(
              lastDropPoint!.latitude + 0.03, lastDropPoint!.longitude + 0.03),
        );

        final center = bounds.center;

        mapController.move(center, 12.0);
      });
    }
  }

  int _calculateTotalLikes(List<dynamic> droppins) {
    return droppins.fold<int>(
      0,
      (sum, droppin) => sum + (droppin['liked_users'].length as int),
    );
  }

  void _initializeRoutePoints() {
    if (widget.post['trip_coordinates'] != null) {
      setState(() {
        routePoints =
            List<Map<String, dynamic>>.from(widget.post['trip_coordinates'])
                .map((coord) {
                  if (coord['latitude'] is double &&
                      coord['longitude'] is double) {
                    return LatLng(coord['latitude'], coord['longitude']);
                  } else {
                    logger.e('Invalid coordinate data: $coord');
                    return null;
                  }
                })
                .where((latLng) => latLng != null)
                .cast<LatLng>()
                .toList();
      });
    }
  }

  Future<void> _getlocaionts() async {
    List<LatLng> tempLocations = [];
    
    if (widget.post['stop_locations'] != null) {
      try {
        final stopLocations = List<Map<String, dynamic>>.from(widget.post['stop_locations']);
        final droppins = List<Map<String, dynamic>>.from(widget.post['droppins']); // Assuming droppins is part of widget.post
        
        for (int i = 0; i < stopLocations.length; i++) {
          final location = stopLocations[i];
          final droppin = droppins[i];
          
          final latitude = double.parse(location['latitude'].toString());
          final longitude = double.parse(location['longitude'].toString());
          
          // Parse deley_time to DateTime and compare to current time
          final deleyTime = DateTime.parse(droppin['deley_time']);
          final currentTime = DateTime.now();
          
          // If deley_time is greater than current time, skip the location
          if (deleyTime.isAfter(currentTime)) {
            continue;
          }
  
          // Add valid locations to tempLocations
          tempLocations.add(LatLng(latitude, longitude));
  
          // Update lastDropPoint with the latest valid point
          if (tempLocations.isNotEmpty) {
            lastDropPoint = tempLocations.last;
          }
        }
      } catch (e) {
        logger.e('Failed to process stop locations: $e');
      }
    }
  
    setState(() {
      locations = tempLocations;
      if (tempLocations.isNotEmpty) {
        lastDropPoint = tempLocations.last;
      }
    });
  
    _adjustZoom();
  }
  

  Future<Map<String, double>> getCoordinates(String address) async {
    String accessToken =
        'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw';
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json?access_token=$accessToken',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coordinates = data['features'][0]['geometry']['coordinates'];
      return {'longitude': coordinates[0], 'latitude': coordinates[1]};
    } else {
      throw Exception('Failed to fetch coordinates');
    }
  }

  bool hasUserViewed(String? viewlist, int userId) {
    if (viewlist == null || viewlist.trim().isEmpty) {
      return false;
    }

    List<int> viewedIds = viewlist
        .split(',')
        .map((e) => e.trim()) // Remove spaces
        .where((e) => e.isNotEmpty) // Clean up empty entries
        .map(int.parse) // Convert to int
        .toList();

    return viewedIds.contains(userId);
  }

  Future<void> _goViewScreen(String viewlist, String imagePath, int droppinId) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeViewScreen(
        viewdList: viewlist, 
        imagePath: imagePath,
        droppinId: droppinId,
      )),
    );
  }

  Future<void> addCount(
    int userid, 
    int droppinid, 
    List<dynamic> droppins, 
    int droppinIndex) async{
    try{
      final apiservice = ApiService();
      final result = await apiservice.markDropinAsViewed(
        userId: userid,
        dropinId: droppinid,
      );
      if (result['statusCode'] == true) {
        setState(() {
          viewcount = result['data']['viewed_count'];
          droppins[droppinIndex]['viewed_count'] = viewcount;
        });
      }else {
        logger.e("Failed to mark as viewed: ${result['message']}");
      }
    }catch(error){
      logger.e("Error while calling API: $error");
    }
  }

  Future<void> _updateViewedCount(
      List<dynamic> droppins, int droppinIndex, int incrementNumber) async {
    try {
      final apiservice = ApiService();
      final result = await apiservice.markDropinWithNumberAsViewed(
        userId: GlobalVariables.userId!,
        dropinId: droppins[droppinIndex]['id'],
        incrementNumber: incrementNumber,
      );
      if (result['statusCode'] == true) {
        logger.i("Successfully updated viewed count for droppin");
      } else {
        logger.e("Failed to update viewed count: ${result['message']}");
      }
    } catch (error) {
      logger.e("Error updating viewed count: $error");
    }
  }

  Future<void> _showImageDialog(
    List<dynamic> droppins,
    int droppinIndex,
    int droppinUserId,
  ) async {

    // if(GlobalVariables.userId != droppinUserId){
    //   await addCount(GlobalVariables.userId!, droppins[droppinIndex]['id'], droppins, droppinIndex);
    // }else {
    //   if(droppins[droppinIndex]['viewed_count'] == null){
    //     setState(() {
    //       viewcount = 0;
    //     });
    //   }else{
    //     setState(() {
    //       viewcount = droppins[droppinIndex]['viewed_count'];
    //     });
    //   }
    // }

     if (GlobalVariables.userId != droppinUserId) {
      // If the current user is not the one who posted the droppin, increment the count manually
      setState(() {
        droppins[droppinIndex]['viewed_count'] =
            (droppins[droppinIndex]['viewed_count'] ?? 0) + 1;
        viewcount = droppins[droppinIndex]['viewed_count'];
      });
    } else {
      // If the current user is the one who posted the droppin, keep the existing count or reset to 0 if null
      setState(() {
        viewcount = droppins[droppinIndex]['viewed_count'] ?? 0;
      });
    }

    final apiservice = ApiService();
    
    List<dynamic> likedUsers = droppins[droppinIndex]['liked_users'];
    bool isLiked = likedUsers.map((user) => user['id']).contains(GlobalVariables.userId);
    int droppinlikes = likedUsers.length;
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // bool isSwpaLoading = false; // Define loading state

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          );
                        },
                        onPageChanged: (index) async {
                          // setState(() {
                          //   isSwpaLoading = true;
                          // });

                          if (GlobalVariables.userId != droppinUserId) {
                            setState(() {
                              droppins[index]['viewed_count'] =
                                  (droppins[index]['viewed_count'] ?? 0) + 1; 
                              viewcount = droppins[index]['viewed_count']; 
                            });
                          } else {
                            setState(() {
                              viewcount = droppins[index]['viewed_count'] ?? 0;
                            });
                          }

                          // if(GlobalVariables.userId != droppinUserId){
                          //   await addCount(GlobalVariables.userId!, droppins[index]['id'], droppins, droppinIndex);
                          // }else {
                          //   if(droppins[index]['viewed_count'] == null){
                          //     setState(() {
                          //       viewcount = 0;
                          //     });
                          //   }else{
                          //     setState(() {
                          //       viewcount = droppins[index]['viewed_count'];
                          //     });
                          //   }
                          // }
                          
                          setState(() {
                            droppinIndex = index;
                            likedUsers = droppins[droppinIndex]['liked_users'];
                            isLiked = likedUsers.map((user) => user['id']).contains(GlobalVariables.userId);
                            droppinlikes = likedUsers.length;
                            // isSwpaLoading = false; 
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
                                    'id': GlobalVariables.userId!,
                                    'photo': GlobalVariables.userImageUrl,
                                    'first_name': GlobalVariables.realName?.split(' ')[0],
                                    'last_name': GlobalVariables.realName?.split(' ')[1],
                                    'rolla_username': GlobalVariables.userName,
                                    'garage' : []
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
                        // if (isSwpaLoading)
                        //   // ignore: dead_code
                        //   const Center(
                        //     child: CircularProgressIndicator(), 
                        //   )
                        // else
                          GestureDetector(
                            onTap: () {
                              if (droppinUserId == GlobalVariables.userId) {
                                _goViewScreen(
                                  droppins[droppinIndex]['view_count'], 
                                  droppins[droppinIndex]['image_path'],
                                  droppins[droppinIndex]['id'] );
                              }
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
    ).then((_) {
      widget.onLikesUpdated(likes);
    });
  }

  Future<void> _showLikeDialog(BuildContext context, String imagePath,
      String followingId, int userId, int tripId) async {
    List<String> followingIds = followingId.split(',');
    isFollowing =
        followingIds.any((id) => int.tryParse(id) == GlobalVariables.userId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: const BorderSide(
              color: Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 300,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: kColorHereButton,
                      width: 2,
                    ),
                    image: imagePath.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imagePath),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imagePath.isEmpty
                      ? const Icon(Icons.person, size: 40) // Default icon
                      : null,
                ),
                const SizedBox(height: 16),
                // Mute Posts Button
                SizedBox(
                  width: 150,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.green, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      muteClicked(GlobalVariables.userId!, tripId);
                    },
                    child: const Text(
                      'Mute Posts',
                      style: TextStyle(
                        fontFamily: 'inter',
                        letterSpacing: -0.1,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 150,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      follow(userId);
                      Navigator.pop(context);
                    },
                    child: Text(
                      isFollowing ? 'Unfollow' : 'Follow',
                      style: const TextStyle(
                        fontFamily: 'inter',
                        letterSpacing: -0.1,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 150,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      blockClicked(userId);
                    },
                    child: const Text(
                      'Block User',
                      style: TextStyle(
                        fontFamily: 'inter',
                        letterSpacing: -0.1,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goTagScreen() {
    final followingData = widget.post['user']['following_user_id'];
    // logger.i(widget.post['user']['id']);
    if(widget.post['user']['id'] == GlobalVariables.userId){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeTagScreen(taglist: widget.post['trip_tags']),
        ),
      );
    } else {
      try {
        final List<dynamic> followingList = json.decode(followingData);
        // logger.i(followingList);
        for (var item in followingList) {
          final int id = item['id'];
          if (GlobalVariables.userId == id) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeTagScreen(taglist: widget.post['trip_tags']),
              ),
            );
            return;
          }
        }
      } catch (e) {
        logger.e("Invalid JSON in following_user_id: $e");
      }
    }
  }

  void _goUserScreen() {
    if (GlobalVariables.userId != widget.post['user_id']) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomeUserScreen(
                  userId: widget.post['user_id'],
                )),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  Future<void> _sendComment() async {
    final commentText = _addCommitController.text;
    if (commentText.isEmpty) {
      _showAlert('Error', 'Comment text cannot be blank.');
      return;
    }

    setState(() {
      isAddComments = false;
      isLoading = true;
    });

    final response = await apiService.sendComment(
      userId: GlobalVariables.userId!,
      tripId: widget.post['id'],
      content: commentText,
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      _showAlert('Success', 'Comment sent successfully.');
      logger.i('Comment sent successfully: ${response['comment']}');
      setState(() {
        widget.post['comments'].add({
          'user': {
            'rolla_username': GlobalVariables.userName,
            'photo': GlobalVariables.userImageUrl,
          },
          'content': commentText,
        });
      });
      _addCommitController.clear();
    } else {
      _showAlert('Error', 'Failed to send comment.');
      logger.e('Failed to send comment');
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void follow(userid) async {
    try {
      final apiservice = ApiService();
      final result =
          await apiservice.followUser(userid!, GlobalVariables.userId!);

      if (result['statusCode'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      logger.i('Error: $e');
    }
  }

  void muteClicked(userid, tripId) async {
    try {
      final apiservice = ApiService();
      final result = await apiservice.muteUser(userid!, tripId);

      if (result['statusCode'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      logger.i('Error: $e');
    }
  }

  void blockClicked(userid) async {
    try {
      final apiservice = ApiService();
      final result =
          await apiservice.blockUser(GlobalVariables.userId!, userid!);

      if (result['statusCode'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      logger.i('Error: $e');
    }
  }

  void _playListClicked() {
    if (widget.post['trip_sound'] == "tripSound") {
      // Show an alert
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("No Playlist"),
            content: const Text("There is no playlist available for this trip"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      // If 'trip_sound' is not "tripSound", navigate to the desired page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeSoundScreen(
            tripSound: widget.post['trip_sound'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateTime.parse(widget.post["updated_at"]);
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () {
                    _goUserScreen();
                  },
                  child: Container(
                    height: vhh(context, 7),
                    width: vhh(context, 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: kColorHereButton,
                        width: 1,
                      ),
                      image: widget.post['user']['photo'] != null
                          ? DecorationImage(
                              image: NetworkImage(widget.post['user']['photo']),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {},
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "@${widget.post['user']['rolla_username']}",
                  style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'inter',
                      letterSpacing: -0.1,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.verified, color: kColorHereButton, size: 18),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (GlobalVariables.userId == widget.post['user']['id']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('It is your post!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      _showLikeDialog(
                          context,
                          widget.post['user']['photo'],
                          widget.post['user']['following_user_id'],
                          widget.post['user']['id'],
                          widget.post['id']);
                    }
                  },
                  child: Image.asset(
                    "assets/images/icons/reference.png",
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
            ),
            SizedBox(height: vhh(context, 0.5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('destination',
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'inter',
                            letterSpacing: -0.1,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 3),
                    Text('soundtrack',
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'inter',
                            letterSpacing: -0.1,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 210,
                      child: Text(
                        widget.post['destination_text_address']
                                    .replaceAll(RegExp(r'[\[\]"]'), '') ==
                                "Edit destination"
                            ? " "
                            : widget.post['destination_text_address']
                                .replaceAll(RegExp(r'[\[\]"]'), ''),
                        style: const TextStyle(
                          fontSize: 13,
                          color: kColorButtonPrimary,
                          fontFamily: 'inter',
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            spreadRadius: 0.5,
                            blurRadius: 6,
                            offset: const Offset(-3, 5),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.brown, // Border color
                          width: 1, // Thin border
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: GestureDetector(
                        onTap: () {
                          _playListClicked();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/images/icons/music.png",
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'playlist',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.1,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: vhh(context, 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                widget.post['droppins'].where((droppin) {
                  try {
                    final delay = DateTime.parse(droppin['deley_time']);
                    return delay.isBefore(DateTime.now());
                  } catch (_) {
                    return true;
                  }
                }).toList().length,
                (index) {
                  final filteredDroppins =
                      widget.post['droppins'].where((droppin) {
                    try {
                      final delay = DateTime.parse(droppin['deley_time']);
                      return delay.isBefore(DateTime.now());
                    } catch (_) {
                      return true;
                    }
                  }).toList();

                  final droppin = filteredDroppins[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _showImageDialog(filteredDroppins, index, widget.post['user']['id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              spreadRadius: 0.5,
                              blurRadius: 6,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Text(
                            droppin['stop_index'].toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'inter',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: Colors.black,
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  isLoading
                      ? const Center(
                          child: SpinningLoader(),
                        )
                      : FlutterMap(
                          key: ValueKey(widget.post['map_style']),
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: lastDropPoint ??
                                startPoint ??
                                const LatLng(37.7749, -122.4194),
                            initialZoom: 12.0,
                          ),
                          children: [
                            TileLayer(
                              key: ValueKey(widget.post['map_style']),
                              urlTemplate: mapStyleUrl,
                              additionalOptions: const {
                                'access_token':
                                    'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw',
                              },
                            ),
                            MarkerLayer(
                              markers: [
                                ...locations.where((location) {
                                  final index = locations.indexOf(location);
                                  final droppin = widget.post['droppins'][index];
                                  try {
                                    final delay =
                                        DateTime.parse(droppin['deley_time']);
                                    return delay.isBefore(DateTime.now());
                                  } catch (_) {
                                    return true;
                                  }
                                }).map((location) {
                                  return Marker(
                                    width: 30.0,
                                    height: 30.0,
                                    point: location,
                                    child: GestureDetector(
                                      onTap: () {
                                        final filteredDroppins = widget.post['droppins'].where((droppin) {
                                          try {
                                            final delay = DateTime.parse(droppin['deley_time']);
                                            return delay.isBefore(DateTime.now());
                                          } catch (_) {
                                            return true;
                                          }
                                        }).toList();
                                        final index = locations.indexOf(location);
                                        _showImageDialog(filteredDroppins, index, widget.post['user']['id']);
                                      },
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: kColorBlack,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.4),
                                              spreadRadius: 0.5,
                                              blurRadius: 6,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${locations.indexOf(location) + 1}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                // if (startPoint != null)
                                //   Marker(
                                //     width: 80.0,
                                //     height: 80.0,
                                //     point: startPoint!,
                                //     child: const SizedBox(
                                //       width: 40,
                                //       height: 40,
                                //       child: Icon(Icons.flag,
                                //           color: Colors.red, size: 30),
                                //     ),
                                //   ),
                                // if (endPoint != null)
                                //   Marker(
                                //     width: 80.0,
                                //     height: 80.0,
                                //     point: endPoint!,
                                //     child: const SizedBox(
                                //       width: 40,
                                //       height: 40,
                                //       child: Icon(Icons.flag,
                                //           color: Colors.green, size: 30),
                                //     ),
                                //   ),
                              ],
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 4.0,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag:
                              'zoom_in_button_homescreen_tap1_${DateTime.now().millisecondsSinceEpoch}',
                          onPressed: () {
                            mapController.move(
                              mapController.camera.center,
                              mapController.camera.zoom + 1,
                            );
                          },
                          mini: true,
                          child: const Icon(Icons.zoom_in),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag:
                              'zoom_out_button_homescreen_tap2_${DateTime.now().millisecondsSinceEpoch}',
                          onPressed: () {
                            mapController.move(
                              mapController.camera.center,
                              mapController.camera.zoom - 1,
                            );
                          },
                          mini: true,
                          child: const Icon(Icons.zoom_out),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            if (isAddComments)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _addCommitController,
                        decoration: const InputDecoration(
                          hintText: 'add a comment',
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              letterSpacing: -0.1,
                              fontFamily: 'inter'),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 8.0,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'inter',
                          fontSize: 15,
                          letterSpacing: -0.1,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: kColorHereButton),
                    onPressed: _sendComment,
                  ),
                ],
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showLikesDropdown = true;
                        });
                      },
                      child: Text(
                        '$likes likes',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: widget.post['userId'] == GlobalVariables.userId
                              ? Colors.red
                              : Colors.grey,
                          fontSize: 13,
                          letterSpacing: -0.1,
                          fontFamily: 'inter',
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isAddComments =
                              !isAddComments; // Toggle the visibility of comments
                        });
                      },
                      child: Image.asset("assets/images/icons/messageicon.png",
                          width: vww(context, 4)),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () {
                        _goTagScreen();
                      },
                      child: Image.asset("assets/images/icons/add_car.png",
                          width: vww(context, 7)),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(widget.post['user']['rolla_username'],
                //         style: const TextStyle(
                //           fontWeight: FontWeight.bold,
                //           fontSize: 15,
                //           letterSpacing: -0.1,
                //           fontFamily: 'inter',
                //         )),
                //     const SizedBox(width: 15),
                //     Text(widget.post['trip_caption'] ?? " ",
                //         style: const TextStyle(
                //           color: kColorButtonPrimary,
                //           fontSize: 15,
                //           letterSpacing: -0.1,
                //           fontFamily: 'inter',
                //         )),
                //   ],
                // ),
                widget.post['trip_caption'] == null ||
                        widget.post['trip_caption'] == "null" ||
                        widget.post['trip_caption'].isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          widget.post['trip_caption'],
                          style: const TextStyle(
                            fontFamily: 'inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),

                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showComments = !showComments;
                      });
                    },
                    child: Text(
                      '${widget.post["comments"].length} comments',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        fontFamily: 'inter',
                      ),
                    ),
                  ),
                ),
                if (showComments)
                  Column(
                    children: widget.post['comments'].map<Widget>((comment) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              height: vhh(context, 3),
                              width: vhh(context, 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kColorHereButton,
                                  width: 2,
                                ),
                                image: comment['user']['photo'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            comment['user']['photo']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              comment['user']['rolla_username'] ??
                                  'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kColorHereButton,
                                fontSize: 13,
                                letterSpacing: -0.1,
                                fontFamily: 'inter',
                              ),
                            ),
                            const SizedBox(width: 5),
                            if (comment['user']['rolla_username'] != null)
                              const Icon(Icons.verified,
                                  color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                comment['content'] ?? '',
                                style: const TextStyle(
                                  fontFamily: 'inter',
                                  fontSize: 14,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                SizedBox(
                  height: vh(context, 4),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Text(
                      'last updated ${timeago.format(now.subtract(difference), locale: 'en_short')} ago',
                      style: const TextStyle(
                        fontFamily: 'inter',
                        color: Color(0xFF95989C),
                        fontSize: 11,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
          ],
        ));
  }
}
