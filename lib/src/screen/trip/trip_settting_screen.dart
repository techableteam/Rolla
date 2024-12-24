import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';

class TripSetttingScreen extends StatefulWidget {
  const TripSetttingScreen({super.key});

  @override
  TripSetttingScreenState createState() => TripSetttingScreenState();
}

class TripSetttingScreenState extends State<TripSetttingScreen> {
  int _privacySelected = 0;
  int _mapStyleSelected = 2; 
  int _selectedUnit = 1;
  final int _currentIndex = 2;

  Future<bool> _onWillPop() async {
    return false;
  }

  Widget _buildRadioOption(String label, int value, int groupValue, Function(int) onChanged) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25), 
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: "Kadaw"
              ),
            ),
            Radio<int>(
              value: value,
              groupValue: groupValue,
              activeColor: kColorHereButton,
              onChanged: (int? newValue) => onChanged(newValue!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildunitsOption(
      String label, int value, int groupValue, Function(int) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: "Kadaw"
          ),
        ),
        Radio<int>(
          value: value,
          groupValue: groupValue,
          activeColor: Colors.blue, // Blue for selected state
          onChanged: (int? newValue) => onChanged(newValue!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and close button aligned at the top
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/icons/logo.png',
                      height: vhh(context, 12),
                    ),

                    // Title with icon
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/icons/setting.png',
                          height: vhh(context, 2.5),
                        ),
                        const SizedBox(width: 5), // Spacing between icon and text
                        const Text(
                          'Trip Settings',
                          style: TextStyle(
                            fontSize: 21,
                            fontFamily: "Kadaw"
                          ),
                        ),
                      ],
                    ),

                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, size: 30),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the screen
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: vww(context, 80),
                child: const Divider(
                  thickness: 0.6, // Set the thickness of the line
                  color: Colors.grey, // Optional: Set the color of the Divider
                ),
              ),

              const Text(
                'Privacy',
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: "Kadaw"
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  'Delay display of dropped pins on my map for:',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Kadaw",
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Privacy radio buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRadioOption('0 mins', 0, _privacySelected, (value) {
                    setState(() => _privacySelected = value);
                  }),
                  _buildRadioOption('30 mins', 1, _privacySelected, (value) {
                    setState(() => _privacySelected = value);
                  }),
                  _buildRadioOption('2 hrs', 2, _privacySelected, (value) {
                    setState(() => _privacySelected = value);
                  }),
                  _buildRadioOption('12 hrs', 3, _privacySelected, (value) {
                    setState(() => _privacySelected = value);
                  }),
                ],
              ),
 
              const SizedBox(height: 30),

              // Map Style Section
              const Text(
                'Map Style',
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: "Kadaw"
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Container(
                          height: vhh(context, 10),
                          width: vww(context, 18),
                          color: Colors.grey[300], // Placeholder for the map image
                        ),
                        Radio<int>(
                          value: index,
                          groupValue: _mapStyleSelected,
                          activeColor: kColorHereButton,
                          onChanged: (value) {
                            setState(() {
                              _mapStyleSelected = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),
              const Text(
                'Units of distance',
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: "Kadaw"
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute items evenly
                  children: [
                    _buildunitsOption("Miles", 0, _selectedUnit, (value) {
                      setState(() => _selectedUnit = value);
                    }),
                    _buildunitsOption("Kilometers", 1, _selectedUnit, (value) {
                      setState(() => _selectedUnit = value);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}