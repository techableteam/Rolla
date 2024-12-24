import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:logger/logger.dart';

class HomeFollowScreen extends ConsumerStatefulWidget  {
  const HomeFollowScreen({super.key});

  @override
   ConsumerState<HomeFollowScreen> createState() => HomeFollowScreenState();
}

class HomeFollowScreenState extends ConsumerState<HomeFollowScreen> {
  final int _currentIndex = 0;
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
      followers = await apiservice.fetchFollowers(GlobalVariables.userId!);
      logger.i(followers);
      setState(() {}); // Refresh the UI with the fetched data
    } catch (e) {
      // Handle errors here
      logger.i('Error loading followers: $e');
    }
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Center(
          child: Column(
            children: [
              SizedBox(height: vhh(context, 5),),
              Row(
                children: [
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
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
                            'Followers',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'KadawBold',
                            ),
                          ),
                          Text(
                            'List of the users who follow you',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontFamily: 'Kadaw',
                            ),
                          ),
                        ],
                      ),
                      
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the space taken by the IconButton
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: followers.length,
                  itemBuilder: (context, index) {
                  final follower = followers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20),
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
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
                                      fontFamily: 'KadawBold',
                                      fontSize: 15
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                                ],
                              ),
                              Text(
                                follower['first_name'] + " " + follower['last_name'], 
                                style: const  TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Kadaw',),)
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

