import 'package:RollaTravel/src/utils/spinner_loader.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Common {
  static void showSuccessMessage(String msg, BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(msg),
      primaryColor: Colors.green,
      foregroundColor: Colors.black,
      showProgressBar: false,
      animationDuration: const Duration(milliseconds: 300),
      autoCloseDuration: const Duration(seconds: 3),
      animationBuilder: (context, animation, alignment, child) {
        return RotationTransition(
          turns: animation,
          child: child,
        );
      },
    );
  }

  static void showErrorMessage(String msg, BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: Text(msg),
      primaryColor: Colors.red,
      foregroundColor: Colors.black,
      showProgressBar: false,
      animationDuration: const Duration(milliseconds: 300),
      autoCloseDuration: const Duration(seconds: 3),
      animationBuilder: (context, animation, alignment, child) {
        return RotationTransition(
          turns: animation,
          child: child,
        );
      },
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SpinningLoader(), // Spinner
              SizedBox(height: 20),
              Text(
                "Loading...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<String?> getAddressFromLocation(LatLng location) async {
    const String accessToken =
        "pk.eyJ1Ijoicm9sbGExIiwiYSI6ImNseGppNHN5eDF3eHoyam9oN2QyeW5mZncifQ.iLIVq7aRpvMf6J3NmQTNAw";
    final String url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${location.longitude},${location.latitude}.json?access_token=$accessToken";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          return data['features'][0]['place_name'];
        } else {
          return "Address not found";
        }
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
