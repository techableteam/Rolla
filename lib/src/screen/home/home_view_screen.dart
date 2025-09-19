import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class HomeViewScreen extends StatefulWidget {
  final String viewdList;
  final String imagePath;
  final int droppinId;

  const HomeViewScreen(
      {super.key,
      required this.viewdList,
      required this.imagePath,
      required this.droppinId});

  @override
  HomeViewScreenState createState() => HomeViewScreenState();
}

class HomeViewScreenState extends State<HomeViewScreen> with WidgetsBindingObserver {
  List<dynamic> viewdUsers = [];
  bool isLoading = true;
  double keyboardHeight = 0;
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUsersFromViewlist(widget.viewdList);
    logger.i(widget.viewdList);
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

  Future<void> _fetchUsersFromViewlist(String viewlist) async {
    final userIds = viewlist.split(','); // Keep all IDs, don't convert to Set
    final apiService = ApiService();
    Map<String, int> userCounts = {}; // Map to store user counts
    Set<String> uniqueUserIds = {};  // Set to track unique user IDs
    List<String> usersToFetch = []; // List of unique user IDs to fetch

    // Preprocess to identify unique users and count their appearances
    for (var userId in userIds) {
      userCounts[userId] = (userCounts[userId] ?? 0) + 1;
      if (!uniqueUserIds.contains(userId)) {
        uniqueUserIds.add(userId);
        usersToFetch.add(userId);
      }
    }

    try {
      final userDataNested = await Future.wait(usersToFetch.map((userId) async {
        try {
          final response = await apiService.fetchUserTrips(int.parse(userId));
          if (response.isNotEmpty && response['userInfo'] != null) {
            return response['userInfo'];
          } else {
            logger.e("User data not found for userId: $userId");
            return [];
          }
        } catch (e) {
          logger.e("Error fetching user data for userId: $userId. Error: $e");
          return [];
        }
      }));

      final userData = userDataNested.expand((element) => element).toList();

      // Now we can create a list of users, and attach the count to each user
      final uniqueUsers = <String, dynamic>{};
      for (var user in userData) {
        final userId = user['id'].toString();
        if (!uniqueUsers.containsKey(userId)) {
          uniqueUsers[userId] = user;
        }
        final count = userCounts[userId] ?? 1;
        uniqueUsers[userId] = {...uniqueUsers[userId], 'count': count}; // Add count to the user
      }

      setState(() {
        viewdUsers = uniqueUsers.values.toList(); // Get the values (unique users)
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      logger.e("Error fetching users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: null,
      ),
      body: Column(
        children: [
          Image.network(
            widget.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF933F10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Viewers',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: -0.1,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              height: 1,
              color: Colors.grey,
            ),
          ),
          if (isLoading) const Center(child: SpinningLoader()),
          // ListView to enable scrolling
          if (!isLoading)
            Expanded(
              child: ListView.builder(
                itemCount: viewdUsers.length,
                itemBuilder: (context, index) {
                  final user = viewdUsers[index];
                  return LikedUserItem(user: user);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class LikedUserItem extends StatelessWidget {
  final dynamic user;

  const LikedUserItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final photo = user['photo'] ?? '';
    final firstName = user['first_name'] ?? 'Unknown';
    final lastName = user['last_name'] ?? '';
    final username = user['rolla_username'] ?? '@unknown';
    final count = user['count'] ?? 1; // Get the count of how many times this user is in the list

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
                  ? DecorationImage(
                      image: NetworkImage(photo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photo.isEmpty ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: 5),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '@ $username',
                        style: const TextStyle(
                            fontSize: 13,
                            letterSpacing: -0.1,
                            color: Colors.black,
                            fontFamily: 'inter',
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        'assets/images/icons/verify.png',
                        width: vww(context, 5),
                        height: 20,
                      ),
                    ],
                  ),
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: -0.1,
                      fontFamily: 'inter',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 4), 
                  const Text(
                    '*',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4), 
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  
                  
                ],
              ),
            ]
          )
        ],
      ),
    );
  }
}
