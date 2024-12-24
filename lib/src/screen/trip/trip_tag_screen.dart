import 'package:flutter/material.dart';
import 'package:RollaTravel/src/utils/index.dart';

class TripTagSearchScreen extends StatefulWidget {
  const TripTagSearchScreen({super.key});

  @override
  TripTagSettingScreenState createState() => TripTagSettingScreenState();
}

class TripTagSettingScreenState extends State<TripTagSearchScreen> {
  final TextEditingController _searchTagController = TextEditingController();

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Spacing from the top
              Row(
                children: [
                  const SizedBox(width: 20),
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
                      child: Text(
                        'Tag Rolla users',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'KadawBold',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/images/icons/add_car1.png',
                    width: vww(context, 6),
                  ),
                  const SizedBox(width: 30,)
                ],
              ),

              Row(
                children: [
                  const SizedBox(width: 20,),
                  const Icon(Icons.search, size: 24, color: Colors.black),
                  const SizedBox(width: 5,),
                  SizedBox(
                    height: 30,
                    width: vww(context, 85),
                    child: TextField(
                      controller: _searchTagController,
                      decoration: InputDecoration(
                          hintText: 'Search Rolla users and add them to your trip',
                          hintStyle: const TextStyle(fontSize: 14, fontFamily: 'Kadaw',), // Set font size for hint text
                          contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0), // Set inner padding
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: const BorderSide(color: Colors.black, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: const BorderSide(color: Colors.black, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: const BorderSide(color: Colors.black, width: 1.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        style: const TextStyle(fontSize: 15, fontFamily: 'Kadaw',),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}