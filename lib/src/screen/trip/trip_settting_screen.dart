import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/trip/start_trip.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:flutter/material.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:RollaTravel/src/widget/bottombar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

class TripSetttingScreen extends StatefulWidget {
  const TripSetttingScreen({super.key});

  @override
  TripSetttingScreenState createState() => TripSetttingScreenState();
}

class TripSetttingScreenState extends State<TripSetttingScreen> {
  int _privacySelected = 0;
  int _mapStyleSelected = 0;
  final int _currentIndex = 5;
  final logger = Logger();

  final GlobalKey _backButtonKey = GlobalKey();
  double backButtonWidth = 0;

  final List<String> _mapStyles = [
    "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw",
    "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw",
    "https://api.mapbox.com/styles/v1/mapbox/light-v10/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw",
    "https://api.mapbox.com/styles/v1/mapbox/dark-v10/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw",
  ];

  @override
  void initState() {
    super.initState();
    _mapStyleSelected = GlobalVariables.mapStyleSelected;
    _privacySelected = GlobalVariables.delaySetting;
  }

  Widget _buildRadioOption(
      String label, int value, int groupValue, Function(int) onChanged) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                fontFamily: "inter"),
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

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = _backButtonKey.currentContext?.findRenderObject() as RenderBox;
      setState(() {
        backButtonWidth = renderBox.size.width;
      });
    });

    return Scaffold(
      backgroundColor: kColorWhite,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      key: _backButtonKey,
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 5),
                        child: Image.asset('assets/images/icons/allow-left.png', width: 20, height: 20),
                      ),
                      onPressed: () {
                        Navigator.push(context,
                          MaterialPageRoute(
                            builder: (context) => 
                            const StartTripScreen()));
                      },
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Image.asset(
                            'assets/images/icons/setting.png',
                            height: vhh(context, 2.5),
                          ),
                          const SizedBox(width: 5), 
                          const Text(
                            'Trip Settings',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                              fontFamily: "inter",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: backButtonWidth),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Divider(
                  thickness: 1.2,
                  color: kColorStrongGrey,
                ),
              ),

              const Text(
                'Privacy',
                style: TextStyle(
                  fontSize: 17, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  fontFamily: "inter"),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  'Delay display of dropped pins on my map for:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                    fontFamily: "inter",
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
                    GlobalVariables.delaySetting = _privacySelected;
                  }),
                  _buildRadioOption('30 mins', 1, _privacySelected, (value) {
                    setState(() => _privacySelected = value);
                    GlobalVariables.delaySetting = _privacySelected;
                  }),
                  _buildRadioOption('2 hrs', 2, _privacySelected, (value) {
                    setState(() => _privacySelected = value);
                    GlobalVariables.delaySetting = _privacySelected;
                  }),
                  _buildRadioOption('12 hrs', 3, _privacySelected, (value) {
                    setState(() => _privacySelected = value);
                    GlobalVariables.delaySetting = _privacySelected;
                  }),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Map Style',
                style: TextStyle(
                  fontSize: 17, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  fontFamily: "inter"),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 4.5 - 2,
                          height: 80,
                          color: Colors.grey[300],
                          child: FlutterMap(
                            options: const MapOptions(
                              initialCenter: LatLng(43.1557, -77.6157),
                              initialZoom: 6.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: _mapStyles[index],
                                additionalOptions: const {
                                  'access_token': 'pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw',
                                },
                              ),
                            ],
                          ),
                        ),
                        Radio<int>(
                          value: index,
                          groupValue: _mapStyleSelected,
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            setState(() {
                              _mapStyleSelected = value!;
                              GlobalVariables.mapStyleSelected = _mapStyleSelected;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
