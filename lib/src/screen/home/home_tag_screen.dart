// import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:logger/logger.dart';
import 'package:RollaTravel/src/services/api_service.dart';

class HomeTagScreen extends ConsumerStatefulWidget {
  final String? taglist;
  const HomeTagScreen({super.key, required this.taglist});

  @override
  ConsumerState<HomeTagScreen> createState() => HomeTagScreenState();
}

class HomeTagScreenState extends ConsumerState<HomeTagScreen> with WidgetsBindingObserver{
  final int _currentIndex = 0;
  final logger = Logger();
  List<dynamic> taggedUsers = []; 
  List<Map<String, dynamic>> followers = [];
  bool isLoading = true; 

  @override
  void initState() {
    super.initState();
    // logger.i(widget.taglist);
    WidgetsBinding.instance.addObserver(this);    
    fetchTaggedUsers();
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

  // Future<void> fetchTaggedUsers() async {
  //   final apiservice = ApiService();
  //   if (widget.taglist != null && widget.taglist != "[]") {
  //     followers = await apiservice.fetchFollowers(GlobalVariables.userId!);
  //     // logger.i(followers);

  //     // Clean up the tag list and convert it into a list of integers
  //     String cleanedTagList = widget.taglist!.replaceAll('[', '').replaceAll(']', '');
  //     List<int> tagIds = cleanedTagList.split(',').map((id) {
  //       try {
  //         return int.parse(id.trim());  
  //       } catch (e) {
  //         logger.e('Error parsing ID: $id');
  //         return null; 
  //       }
  //     }).where((id) => id != null).cast<int>().toList(); 
  //     // logger.i(tagIds);

  //     // Filter followers to only include those whose ID is in tagIds
  //     final matchingFollowers = followers.where((follower) => tagIds.contains(follower['id'])).toList();
  //     // logger.i('Matching Followers: $matchingFollowers');

  //     // Fetch user data for each matching follower
  //     for (var follower in matchingFollowers) {
  //       try {
  //         final userData = await ApiService().fetchUserInfo(follower['id']);
  //         // logger.i('Fetched user info for ID ${follower['id']}: $userData'); 
  //         setState(() {
  //           taggedUsers.add(userData);
  //         });
  //       } catch (e) {
  //         logger.e('Error fetching user info for ID ${follower['id']}: $e');
  //       }
  //     }
  //   }
  //   // logger.i(taggedUsers);

  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  Future<void> fetchTaggedUsers() async {
  final apiservice = ApiService();
  if (widget.taglist != null && widget.taglist != "[]") {
    // Clean up the tag list and convert it into a list of integers
    String cleanedTagList = widget.taglist!.replaceAll('[', '').replaceAll(']', '');
    List<int> tagIds = cleanedTagList.split(',').map((id) {
      try {
        return int.parse(id.trim());  
      } catch (e) {
        logger.e('Error parsing ID: $id');
        return null; 
      }
    }).where((id) => id != null).cast<int>().toList(); 
    // logger.i(tagIds);

    // Fetch user data for each ID in tagIds
    for (var id in tagIds) {
      try {
        final userData = await apiservice.fetchUserInfo(id);
        // logger.i('Fetched user info for ID $id: $userData'); 
        setState(() {
          taggedUsers.add(userData);
        });
      } catch (e) {
        logger.e('Error fetching user info for ID $id: $e');
      }
    }
  }

  setState(() {
    isLoading = false;
  });
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
              Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 8.0, right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: vhh(context, 5)),
                        IconButton(
                          icon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset('assets/images/icons/allow-left.png', width: 20, height: 20),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,  // Ensures the column takes minimum space required
                          children: [
                            SizedBox(height: vhh(context, 5)),
                            const Text(
                              "Users tagged in this post",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                                fontFamily: 'inter',
                              ),
                            ),
                            Image.asset("assets/images/icons/add_car.png", width: vww(context, 8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20,),
                  ],
                ),
              ),
              SizedBox(
                width: vww(context, 80),
                child: const Divider(
                  thickness: 0.6, 
                  color: Colors.grey,
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: SpinningLoader()) // Show loading while fetching data
                    : taggedUsers.isEmpty
                        ? const Center(child: Text('No users found.')) // Show message if no users are found
                        : ListView.builder(
                            itemCount: taggedUsers.length,
                            itemBuilder: (context, index) {
                              final user = taggedUsers[index];
                              final fullName = '${user['first_name']} ${user['last_name']}';
                              final userImageUrl = user['photo'];
                              final rollaUsername = user['rolla_username'];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 20),
                                child: Row(
                                  children: [
                                    Container(
                                      height: vhh(context, 6),
                                      width: vhh(context, 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(
                                          color: kColorHereButton,
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(userImageUrl ?? ""),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "@$rollaUsername",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'interBold',
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            const Icon(Icons.verified,
                                                color: Colors.blue, size: 16),
                                          ],
                                        ),
                                        Text(
                                          fullName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey,
                                            fontFamily: 'inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Image.asset("assets/images/icons/reference.png"),
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

