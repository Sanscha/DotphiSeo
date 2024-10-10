// import 'package:firebase_messaging/firebase_messaging.dart';
//
// class FirebaseMessagingService {
//   FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//
//   Future<void> initialize() async {
//     _firebaseMessaging = FirebaseMessaging.instance;
//
//     // Configure Firebase messaging
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _handleMessage(message);
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _handleMessage(message);
//     });
//
//     // Request permission for notifications
//     NotificationSettings settings = await _firebaseMessaging.requestPermission();
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('User granted permission');
//     } else {
//       print('User declined permission');
//     }
//
//     // Retrieve the token
//     String? token = await _firebaseMessaging.getToken();
//     print('FCM Token: $token');
//   }
//
//   Future<void> _handleMessage(RemoteMessage message) async {
//     print('Received message: ${message.notification?.title}');
//     // Handle the notification as desired
//   }
// }
