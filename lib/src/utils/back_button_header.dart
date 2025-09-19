import 'package:flutter/material.dart';
import 'package:RollaTravel/src/constants/app_styles.dart';

class BackButtonHeader extends StatelessWidget {
  final VoidCallback onBackPressed;
  final String title;
  final GlobalKey backButtonKey;
  final double backButtonWidth;

  const BackButtonHeader({
    super.key,
    required this.onBackPressed,
    required this.title,
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
            padding: const EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 5),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/icons/allow-left.png',
              width: MediaQuery.of(context).size.width * 0.035,
            ),
          ),
        ),
        Center(
          child: Text(
            title,
            style: const TextStyle(
              color: kColorBlack,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
              fontFamily: 'inter',
            ),
          ),
        ),
        SizedBox(width: backButtonWidth),
      ],
    );
  }
}
