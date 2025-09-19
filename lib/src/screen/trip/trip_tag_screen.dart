import 'dart:convert';

import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/home/home_screen.dart';
import 'package:RollaTravel/src/screen/trip/start_trip.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/back_button_header.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:RollaTravel/src/utils/index.dart';

class TripTagSearchScreen extends StatefulWidget {
  const TripTagSearchScreen({super.key});

  @override
  TripTagSettingScreenState createState() => TripTagSettingScreenState();
}

class TripTagSettingScreenState extends State<TripTagSearchScreen> {
  bool isLoading = false;
  final TextEditingController _searchTagController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> allUserData = [];
  List<dynamic> filteredUserData = [];
  final int _currentIndex = 5;
  List<int> selectedUserIds = [];

  final GlobalKey _backButtonKey = GlobalKey();
  double backButtonWidth = 0;

  @override
  void initState() {
    super.initState();
    _searchTagController.addListener(_filterResults);
    selectedUserIds = List<int>.from(GlobalVariables.selectedUserIds);
    getAllUserData();
  }

  @override
  void dispose() {
    _searchTagController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  Future<void> getAllUserData() async {
    setState(() => isLoading = true);
    final authService = ApiService();

    try {
      final userresponse = await authService.fetchUserInfo(GlobalVariables.userId!);
      logger.i(userresponse);
      final response = await authService.fetchAllUserData();
      
      if (response.containsKey("status") && response.containsKey("data")) {
        setState(() {
          allUserData = response["data"];
          
          List<dynamic> followingUsers = [];
          List<dynamic> followedUsers = [];

          if (userresponse?['following_user_id'] != null) {
            followingUsers = List.from(jsonDecode(userresponse?['following_user_id'] ?? '[]'));
          }
          if (userresponse?['followed_user_id'] != null) {
            followedUsers = List.from(jsonDecode(userresponse?['followed_user_id'] ?? '[]'));
          }
          Set<int> uniqueUserIds = <int>{};

          for (var user in followingUsers) {
            uniqueUserIds.add(user['id']);
          }

          for (var user in followedUsers) {
            uniqueUserIds.add(user['id']);
          }

          filteredUserData = allUserData
              .where((user) => uniqueUserIds.contains(user['id']) && user['id'] != GlobalVariables.userId)
              .toList();

          isLoading = false;
        });
      } else {
        logger.e("Failed to fetch user data.");
        setState(() => isLoading = false);
      }
    } catch (e) {
      logger.e("Error fetching user data: $e");
      setState(() => isLoading = false);
    }
  }


  void _filterResults() {
    String query = _searchTagController.text.toLowerCase();
    setState(() {
      filteredUserData = allUserData
          .where((user) {
            final fullName = '${user['first_name']} ${user['last_name']}';
            final email = user['email'] ?? '';
            return (fullName.toLowerCase().contains(query) ||
                email.toLowerCase().contains(query)) &&
                user['id'] != GlobalVariables.userId;
          })
          .toList();
    });
  }

  void _onBackPressed() {
     GlobalVariables.selectedUserIds = selectedUserIds;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const StartTripScreen()));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = _backButtonKey.currentContext?.findRenderObject() as RenderBox;
      setState(() {
        backButtonWidth = renderBox.size.width;
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return;
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: kColorWhite,
          ),
          padding: EdgeInsets.symmetric(horizontal: vww(context, 4)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: vhh(context, 7)),
              BackButtonHeader(
                onBackPressed: _onBackPressed,
                title: 'Tag Rolla users',
                backButtonKey: _backButtonKey,
                backButtonWidth: backButtonWidth,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/images/icons/add_car1.png',
                    width: vww(context, 8),
                  ),
                  const SizedBox(
                    width: 30,
                  )
                ],
              ),

              Row(
                children: [
                  const SizedBox(
                    width: 20,
                  ),
                  const Icon(Icons.search, size: 24, color: Colors.black),
                  const SizedBox(
                    width: 5,
                  ),
                  SizedBox(
                    height: 30,
                    width: vww(context, 80),
                    child: TextField(
                      controller: _searchTagController,
                      focusNode: _searchFocusNode, 
                      decoration: InputDecoration(
                        hintText:
                            'Search Rolla users and add them to your trip',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                          fontFamily: 'inter',
                        ), // Set font size for hint text
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 5.0), // Set inner padding
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide:
                              const BorderSide(color: Colors.black, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide:
                              const BorderSide(color: Colors.black, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide:
                              const BorderSide(color: Colors.black, width: 1.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                        fontFamily: 'inter',
                      ),
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () {
                        _searchFocusNode.unfocus();
                      },
                    ),
                  ),
                ],
              ),
              isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: SpinningLoader(),
                  )
                : Expanded(
                  child: _buildUserList(),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: filteredUserData.length,
      itemBuilder: (context, index) {
        final user = filteredUserData[index];
        final fullName = '${user['first_name']} ${user['last_name']}';
        final userImageUrl = user['photo'];
        final userid = user['id'];
        final rollaUsername = user['rolla_username'];

        // Check if the current user is selected (pre-select checkboxes)
        bool isSelected = selectedUserIds.contains(userid);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
          child: GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) => HomeUserScreen(
              //             userId: userid,
              //           )),
              // );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kColorGrey, width: 0.6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: userImageUrl != null && userImageUrl.isNotEmpty
                        ? Image.network(
                            userImageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    size: 60, color: Colors.grey),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              } else {
                                return const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Center(
                                    child: SpinningLoader(),
                                  ),
                                );
                              }
                            },
                          )
                        : const Icon(Icons.person,
                            size: 60, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.1,
                            fontFamily: 'inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "@$rollaUsername",
                          style: const TextStyle(
                            fontSize: 14,
                            letterSpacing: -0.1,
                            fontFamily: 'inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Custom checkbox to select/deselect the user
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedUserIds.remove(userid); // Deselect the user ID
                        } else {
                          selectedUserIds.add(userid); // Select the user ID
                        }
                      });
                    },
                    child: Container(
                      width: 24,  // Size of the checkbox
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,  // Round shape
                        color: isSelected ? kColorHereButton : Colors.grey[300],  // Background color
                        border: Border.all(
                          color: isSelected ? kColorHereButton : Colors.grey,  // Border color
                          width: 2,  // Border width
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 15)  // Check mark when selected
                          : null,  // Empty when not selected
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


}
