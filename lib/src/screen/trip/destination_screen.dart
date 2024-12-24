import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class DestinationScreen extends ConsumerStatefulWidget{
  final String initialDestination;
  const DestinationScreen({super.key, required this.initialDestination});

  @override
  ConsumerState<DestinationScreen> createState() => DestinationScreenState();
}

class DestinationScreenState extends ConsumerState<DestinationScreen> {
  double screenHeight = 0;
  double keyboardHeight = 0;
  final int _currentIndex = 2;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  Future<List<String>> fetchAddressSuggestions(String query) async {
    final response = await http.get(
      Uri.parse('https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      return features.map((feature) => feature['place_name'] as String).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Spacing from the top
              Row(
                children: [
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      if(_searchController.text.isNotEmpty){
                        Navigator.pop(context, _searchController.text);
                      } else {
                        Navigator.pop(context, widget.initialDestination);
                      }
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
                        'Destination',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'KadawBold',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the space taken by the IconButton
                ],
              ),
              
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 24, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TypeAheadFormField(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search Locations", 
                            hintStyle: const TextStyle(fontSize: 16, fontFamily: 'Kadaw'), // Set font size for hint text
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Set inner padding
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
                          style: const TextStyle(fontSize: 16, fontFamily: 'Kadaw'), // Set font size for input text
                        ),
                        suggestionsCallback: (pattern) async {
                          return await fetchAddressSuggestions(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion),
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          _searchController.text = suggestion;
                        },
                      ),
                    ),
                  ],
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
