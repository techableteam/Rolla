import 'package:RollaTravel/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';

class BackButtonTwoHeader extends StatelessWidget {
  final VoidCallback onBackPressed;
  final String title;
  final String fromUser;
  final GlobalKey backButtonKey;
  final double backButtonWidth;

  const BackButtonTwoHeader({
    super.key,
    required this.onBackPressed,
    required this.title,
    required this.fromUser,
    required this.backButtonKey,
    required this.backButtonWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          key: backButtonKey,
          onTap: onBackPressed,
          child: Container(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 3, bottom: 10),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/icons/allow-left.png',
              width: vww(context, 5),
              height: 20,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kColorBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.1,
                    fontFamily: 'inter',
                  ),
                ),
                Text(
                  'List of the users who follow $fromUser',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    letterSpacing: -0.1,
                    fontFamily: 'inter',
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: backButtonWidth),  
      ],
    );
  }
}
