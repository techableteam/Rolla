import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:RollaTravel/src/services/api_service.dart';
import 'package:RollaTravel/src/utils/location.permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RollaTravel/src/app.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const tripUploadTask = "uploadTripTask";
final logger = Logger();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); 
      
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == tripUploadTask || task.startsWith("uploadTripTask_")) {
      final prefs = await SharedPreferences.getInstance();

      final String? taskKey = inputData?['taskKey'];
      if (taskKey == null) {
        // No key, fail gracefully
        await sendNotification("Trip Upload Failed", "Task key missing.");
        return Future.value(false);
      }

      final int? tripId = prefs.getInt('${taskKey}_tripId');
      final int? userId = prefs.getInt('${taskKey}_userId');

      logger.i("uerid : $userId");

      if (userId == null) {
        await sendNotification("Trip Upload Failed", "User ID not found.");
        return Future.value(false);
      }

      ApiService apiService = ApiService();
      Map<String, dynamic> response;

      try {
        final startAddress = prefs.getString('${taskKey}_startAddress') ?? '';
        final stopAddressesString = prefs.getString('${taskKey}_stopAddressesString') ?? '';
        final formattedDestination = prefs.getString('${taskKey}_formattedDestination') ?? '';
        final tripCaption = prefs.getString('${taskKey}_tripCaption') ?? '';
        final tripStartDate = prefs.getString('${taskKey}_tripStartDate') ?? '';
        final tripEndDate = prefs.getString('${taskKey}_tripEndDate') ?? '';
        final tripMiles = prefs.getString('${taskKey}_tripMiles') ?? '';
        final tripSound = prefs.getString('${taskKey}_tripSound') ?? '';
        final tripTag = prefs.getString('${taskKey}_tripTag') ?? '';
        final startLocationString = prefs.getString('${taskKey}_startLocation') ?? '';
        final destinationLocationString = prefs.getString('${taskKey}_destinationLocation') ?? '';
        final mapStyleString = prefs.getString('${taskKey}_mapstyle') ?? '';
        final droppinsJson = prefs.getString('${taskKey}_droppins') ?? '[]';
        final stopLocationsJson = prefs.getString('${taskKey}_stopLocations') ?? '[]';
        final tripCoordinatesJson = prefs.getString('${taskKey}_tripCoordinates') ?? '[]';

        List<dynamic> droppinsDynamic = jsonDecode(droppinsJson);
        List<dynamic> stopLocationsDynamic = jsonDecode(stopLocationsJson);
        List<dynamic> tripCoordinatesDynamic = jsonDecode(tripCoordinatesJson);

        List<Map<String, dynamic>> droppins = List<Map<String, dynamic>>.from(droppinsDynamic);

        List<Map<String, double>> stopLocations = stopLocationsDynamic.map<Map<String, double>>((item) {
          return item.map<String, double>((key, value) => MapEntry(key.toString(), (value as num).toDouble()));
        }).toList();

        List<Map<String, double>> tripCoordinates = tripCoordinatesDynamic.map<Map<String, double>>((item) {
          return item.map<String, double>((key, value) => MapEntry(key.toString(), (value as num).toDouble()));
        }).toList();
        if (tripId != null) {
          response = await apiService.updateTrip(
            tripId: tripId,
            userId: userId,
            startAddress: startAddress,
            stopAddresses: stopAddressesString,
            destinationAddress: "Destination address for DropPin",
            destinationTextAddress: formattedDestination,
            tripStartDate: tripStartDate,
            tripCaption: tripCaption,
            tripEndDate: tripEndDate,
            tripMiles: tripMiles,
            tripSound: tripSound,
            tripTag: tripTag,
            stopLocations: stopLocations,
            tripCoordinates: tripCoordinates,
            droppins: droppins,
            startLocation: startLocationString,
            destinationLocation: destinationLocationString,
            mapStyle: mapStyleString
          );

          if (response['success'] == true) {
            await _removeTaskPrefs(prefs, taskKey);
            await prefs.setInt("tripId", response['trip']['id']);
            await prefs.setInt("dropcount", response['trip']['droppins'].length);
            await sendNotification("Trip Upload Successful", "Your trip details have been successfully uploaded.");
          } else {
            await sendNotification("Trip Upload Failed", "There was an issue uploading your trip.");
          }
        } else {
          logger.i("create trip working");
          response = await apiService.createTrip(
            userId: userId,
            startAddress: startAddress,
            stopAddresses: stopAddressesString,
            destinationAddress: "Destination address for DropPin",
            destinationTextAddress: formattedDestination,
            tripStartDate: tripStartDate,
            tripEndDate: "",
            tripMiles: tripMiles,
            tripCaption: tripCaption,
            tripTag: tripTag,
            tripSound: tripSound,
            stopLocations: stopLocations,
            tripCoordinates: tripCoordinates,
            droppins: droppins,
            startLocation: startLocationString,
            destinationLocation: destinationLocationString,
            mapstyle: mapStyleString,
            delayTime: tripStartDate //for running
          );

          if (response['success'] == true) {
            await _removeTaskPrefs(prefs, taskKey);
            logger.i(response['trip']);
            await prefs.setInt("tripId", response['trip']['id']);
            await prefs.setInt("droppinId", response['trip']['droppins'][0]['id']);
            await prefs.setInt("dropcount", response['trip']['droppins'].length);
            await sendNotification("Trip Creation Successful", "Your new trip has been successfully created.");
          } else {
            await sendNotification("Trip Upload Failed", "There was an issue creating your trip.");
          }
        }
      } catch (e) {
        logger.e("eroor : $e");
        await sendNotification("Trip Upload Failed", "An error occurred while uploading your trip.");
        return Future.value(false);
      }

      return Future.value(true);
    }
    return Future.value(false);
  });
}

Future<void> _removeTaskPrefs(SharedPreferences prefs, String taskKey) async {
  await prefs.remove('${taskKey}_tripId');
  await prefs.remove('${taskKey}_userId');
  await prefs.remove('${taskKey}_startAddress');
  await prefs.remove('${taskKey}_stopAddressesString');
  await prefs.remove('${taskKey}_formattedDestination');
  await prefs.remove('${taskKey}_tripCaption');
  await prefs.remove('${taskKey}_tripStartDate');
  await prefs.remove('${taskKey}_tripEndDate');
  await prefs.remove('${taskKey}_tripMiles');
  await prefs.remove('${taskKey}_tripSound');
  await prefs.remove('${taskKey}_tripTag');
  await prefs.remove('${taskKey}_startLocation');
  await prefs.remove('${taskKey}_destinationLocation');
  await prefs.remove('${taskKey}_stopLocations');
  await prefs.remove('${taskKey}_droppins');
  await prefs.remove('${taskKey}_tripCoordinates');
}

Future<void> sendNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'trip_upload_channel',
    'Trip Uploads',
    channelDescription: 'Notification channel for trip upload status',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'trip_upload_payload',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  await PermissionService().checkAndRequestLocationPermission();
  await _requestCameraPermissionAtStartup();
  runApp(const ProviderScope(child: RollaTravel()));
}

Future<void> _requestCameraPermissionAtStartup() async {
  await Permission.camera.request();
}
