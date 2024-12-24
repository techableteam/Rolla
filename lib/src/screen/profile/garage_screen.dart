import 'package:RollaTravel/src/screen/profile/edit_profile.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/index.dart';
import 'package:logger/logger.dart';

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  List<dynamic> carData = [];
  int? selectedCarId;
  final ApiService apiService = ApiService();
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    loadCarData();
  }

  Future<void> loadCarData() async {
    try {
      final data = await apiService.fetchCarData();
      setState(() {
        carData = data;
      });
    } catch (e) {
      logger.i('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding for proper spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // Add spacing at the top
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                  },
                  child: Image.asset(
                    'assets/images/icons/allow-left.png',
                    width: vww(context, 3),
                  ),
                ),
                
                const Text(
                  'My Garage',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'KadawBold'
                  ),
                ),

                Container(),
              ],
            ),
            const SizedBox(height: 18),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Center the column vertically
                  children: [
                    Text(
                      'Adding a vehicle to your garage will result in the vehicle maker\'s logo appearing in your profile.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Kadaw',
                      ),
                      textAlign: TextAlign.center, // Center-align the text within the column
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16), // Spacing before the list
            Expanded(
              child: carData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: carData.length,
                      itemBuilder: (context, index) {
                        final car = carData[index];
                        return Column(
                          children: [
                            SizedBox(
                              height: 40, // Set the height of the ListTile
                              child: ListTile(
                                leading: Image.network(
                                  car['logo_path'],
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Display a placeholder icon on error
                                    return const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 40,
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    // Show a progress indicator while the image is loading
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  fit: BoxFit.cover, // Ensures the image fits within the specified size
                                ),
                                title: Text(
                                  car['car_type'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                trailing: selectedCarId == car['id']
                                    ? const Icon(Icons.check, color: Colors.blue)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedCarId = car['id'];
                                    GlobalVariables.garage = car['id'].toString();
                                    GlobalVariables.garageLogoUrl = car['logo_path'];
                                  });
                                },
                              ),
                            ),
                            const Divider(), // Adds a divider between items
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
