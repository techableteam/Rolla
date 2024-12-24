import 'dart:math';

import 'package:flutter/material.dart';

const Color kColorWhite = Color(0xFFFFFFFF);
const Color kColorBlack = Color(0xFF000000);
const Color kColorGrey = Color(0XFFA7A7A7);
const Color kColorButtonPrimary = Color(0XFF933F10);
const Color kColorHereButton = Color(0XFF19B4D7);
const Color kColorCreateButton = Color(0XFF4D9750);
const Color kColorStrongGrey = Color(0XFF95989C);


// ------------------------ Message -------------------------------- //

const Color mColorIcon = Color(0XFF9095A0);

Color getRandomColor() {
  Random random = Random();
  return Color.fromRGBO(
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
    1,
  );
}

const kEnableBorder = OutlineInputBorder(
  borderSide: BorderSide(color: kColorGrey, width: 1),
  borderRadius: BorderRadius.all(Radius.circular(15)),
);
const kFocusBorder = OutlineInputBorder(
  borderSide: BorderSide(color: kColorBlack, width: 1),
  borderRadius: BorderRadius.all(Radius.circular(15)),
);

const TextStyle iamgeModalCaptionTextStyle = TextStyle(
  fontSize: 15,
  color: Colors.grey,
  fontFamily: 'KadawBold',
);