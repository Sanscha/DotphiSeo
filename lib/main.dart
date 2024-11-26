import 'dart:convert';
import 'package:dotphi_seo_app/pages/todaysfollowup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'model/login_model.dart';
import 'my_app.dart';
import 'notification_services/notification_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Initialize notifications
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: androidInitializationSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle the notification tap event
      await onSelectNotification(response.payload);
    },
  );
}

// Handle the notification tap event and navigate to the target screen
Future<void> onSelectNotification(String? payload) async {
  if (payload != null) {
    // Decode the payload (which is a JSON string)
    final decodedPayload = jsonDecode(payload);

    // Extract data from the decoded payload
    final String? projectUniqueCode = decodedPayload['projectUniqueCode'];
    final String? campaignId = decodedPayload['campaignId'];

    // If data is valid, navigate to the TodaysfollowupScreen
    if (projectUniqueCode != null && campaignId != null) {
      // Using context from a widget to navigate, pass the payload data
      // This requires context, which should be passed when calling this function
      navigateToFollowUpScreen(projectUniqueCode, campaignId);
    }
  }
}

// Function to navigate to TodaysfollowupScreen
void navigateToFollowUpScreen(String projectUniqueCode, String campaignId) {
  // We use the MaterialApp to wrap the navigation in this simple example
  runApp(MaterialApp(
    home: TodaysfollowupScreen(
      projectUniqueCode: projectUniqueCode,
      campaignId: campaignId,
    ),
  ));
}

// Show notification with payload
void showInAppNotification({
  required String title,
  required String message,
  required String projectUniqueCode,
  required String campaignId,
}) async {
  // Create a map with your data
  final payloadData = {
    'projectUniqueCode': projectUniqueCode,
    'campaignId': campaignId,
  };

  // Convert the map to a JSON string
  final payload = jsonEncode(payloadData);

  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    'basic_channel',
    'Basic notifications',
    channelDescription: 'Notification channel for follow-up reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  final NotificationDetails notificationDetails =
  NotificationDetails(android: androidNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    0, // Unique notification ID
    title, // Notification title
    message, // Notification message
    notificationDetails,
    payload: payload, // Pass the JSON payload
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeNotifications(); // Initialize notifications
  User user = await getUser();

  // Run your app with the provided user data
  runApp(
    ChangeNotifierProvider(
      create: (context) => UnreadCountProvider(),
      child: MyApp(user: user),
    ),
  );
}
