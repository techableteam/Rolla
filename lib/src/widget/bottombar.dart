import 'package:RollaTravel/src/constants/app_styles.dart';
import 'package:RollaTravel/src/screen/home/home_screen.dart';
import 'package:RollaTravel/src/screen/home/map_location_screen.dart';
import 'package:RollaTravel/src/screen/profile/profile_screen.dart';
import 'package:RollaTravel/src/screen/search/search_%20screen.dart';
import 'package:RollaTravel/src/screen/trip/start_trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/utils/global_variable.dart';

class BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  const BottomNavBar({required this.currentIndex, super.key});

  void onTabTapped(BuildContext context, WidgetRef ref, int index) {
    if (index == currentIndex) {
      if (index == 0) {
        ref.read(homeTabReselectedProvider.notifier).state++;
      }
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SearchScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const StartTripScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MapLocationScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProfileScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth > 600 ? 15.0 : 13.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildIconTab(
                context,
                ref,
                index: 0,
                label: "Home",
                assetImage: "assets/images/icons/homeBottom.png",
                selected: currentIndex == 0,
                fontSize: fontSize,
              ),
              _buildIconTab(
                context,
                ref,
                index: 1,
                label: "Search",
                assetImage: "assets/images/icons/searchBottom.png",
                selected: currentIndex == 1,
                fontSize: fontSize,
              ),
              _buildIconTab(
                context,
                ref,
                index: 2,
                label: "Start Trip", // "Start Trip"
                assetImage: "assets/images/icons/tripBottom.png",
                selected: currentIndex == 2,
                fontSize: fontSize,
              ),
              _buildIconTab(
                context,
                ref,
                index: 3,
                label: "Map", // "Map" / "Drop Pin"
                assetImage: "assets/images/icons/mapBottom.png",
                selected: currentIndex == 3,
                fontSize: fontSize,
              ),
              _buildProfileTab(
                context,
                ref,
                index: 4,
                label: "Profile",
                selected: currentIndex == 4,
                fontSize: fontSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generic tab (icon or asset image + label)
  Widget _buildIconTab(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required String label,
    IconData? icon,
    String? assetImage,
    required bool selected,
    required double fontSize,
  }) {
    final color = selected ? kColorHereButton : kColorBlack;

    return Expanded(
      child: InkWell(
        onTap: () => onTabTapped(context, ref, index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetImage != null)
              // Use your custom image for the center tab
              Image.asset(
                assetImage,
                width: 38,
                height: 33,
                // comment this line if you don't want tint on selection
                color: color,
              )
            else if (icon != null)
              Icon(icon, size: 24, color: color),
            const SizedBox(height: 0),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'inter',
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile tab with avatar ring and label (matched to other tabs)
  Widget _buildProfileTab(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required String label,
    required bool selected,
    required double fontSize,
  }) {
    final color = selected ? kColorHereButton : kColorBlack;

    // Keep the visual area consistent with other tabs (approx 38x33)
    final avatar = CircleAvatar(
      radius: 14, // ~28px diameter
      backgroundColor: Colors.transparent,
      backgroundImage: (GlobalVariables.userImageUrl != null)
          ? NetworkImage(GlobalVariables.userImageUrl!)
          : null,
      child: (GlobalVariables.userImageUrl == null)
          ? Icon(Icons.person, size: 18, color: color)
          : null,
    );

    return Expanded(
      child: InkWell(
        onTap: () => onTabTapped(context, ref, index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Match icon/image box size for consistent alignment
            SizedBox(
              width: 38,
              height: 33,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? kColorHereButton : Colors.grey,
                    width: 2,
                  ),
                ),
                child: avatar,
              ),
            ),
            const SizedBox(height: 1), // same spacing as other tabs
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'inter',
                fontSize: fontSize,
                fontWeight: FontWeight.bold, // match others
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
