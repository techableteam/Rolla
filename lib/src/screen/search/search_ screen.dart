
import 'package:RollaTravel/src/screen/home/home_user_screen.dart';
import 'package:RollaTravel/src/screen/profile/profile_screen.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:logger/logger.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final int _currentIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final logger = Logger();
  
  bool isLoading = false;
  List<dynamic> allDropPinData = [];
  List<dynamic> filteredDropPinData = [];
  List<dynamic> allUserData = [];
  List<dynamic> filteredUserData = [];
  bool isUserDataFetched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterResults);
    getAllUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> getAllUserData() async {
    setState(() => isLoading = true);
    final authService = ApiService();

    try {
      final response = await authService.fetchAllUserData();
      if (response.containsKey("status") && response.containsKey("data")) {
        setState(() {
          allUserData = response["data"];
          filteredUserData = response["data"];
          isUserDataFetched = true;
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
    String query = _searchController.text.toLowerCase();

    setState(() {
      filteredUserData = allUserData.where((user) {
        final fullName = '${user['first_name']} ${user['last_name']}';
        final email = user['email'] ?? '';
        return fullName.toLowerCase().contains(query) ||
            email.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: vhh(context, 5)),
          Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/icons/logo.png',
                  width: 90,
                  height: 80,
                ),
                IconButton(icon: const Icon(Icons.search, size: 35), onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 35,
            width: vww(context, 90),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode, 
              decoration: InputDecoration(
                hintText: 'Search user accounts',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'inter',
                  letterSpacing: -0.1,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Colors.black, width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Colors.black, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Colors.black, width: 1.2),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'inter',
                letterSpacing: -0.1,
              ),
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                _searchFocusNode.unfocus();
              },
            ),
          ),
          isLoading
              ? const Expanded(
                  child: Center(
                    child: SpinningLoader(),
                  ),
                )
              : Expanded(
                 child: _buildUserList(),
                ),
        ],
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
          child: GestureDetector(
            onTap: () {
              if(userid == GlobalVariables.userId){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              }else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeUserScreen(userId: userid,)),
                );
              }
              
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
                  // Image
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
                        const SizedBox(height: 4),
                        // Text(
                        //   formattedDate,
                        //   style: const TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.grey,
                        //     letterSpacing: -0.1,
                        //     fontFamily: 'inter',
                        //   ),
                        // ),
                      ],
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
