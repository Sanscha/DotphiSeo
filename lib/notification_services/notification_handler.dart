import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';

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

  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'basic_channel',
    'Basic notifications',
    channelDescription: 'Notification channel for follow-up reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  // Show the notification with the payload
  await flutterLocalNotificationsPlugin.show(
    0, // Unique notification ID
    title, // Notification title
    message, // Notification message
    notificationDetails,
    payload: payload, // Pass the JSON payload
  );
}
