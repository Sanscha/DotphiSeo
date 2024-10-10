// // import 'dart:math';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/cupertino.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import '../main.dart';
// // import '../model/login_model.dart';
// // import 'leads_screen.dart';
// //
// //
// // class NotificationServices{
// //
// //   FirebaseMessaging messaging = FirebaseMessaging.instance ;
// //   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
// //
// //   void  requestNotificationPermission()async{
// //
// //     NotificationSettings settings = await messaging.requestPermission(
// //         alert: true,
// //         announcement: true,
// //         badge: true,
// //         carPlay: true,
// //         criticalAlert: true,
// //         provisional: true,
// //         sound: true
// //     );
// //
// //     if(settings.authorizationStatus == AuthorizationStatus.authorized){
// //       print('user granted permission');
// //
// //     }else if(settings.authorizationStatus == AuthorizationStatus.authorized){
// //       print('user granted provisional permission');
// //     }else{
// //       print('user denied permission');
// //     }
// //   }
// //
// //
// //   void initLocalNotifications(BuildContext context, RemoteMessage message)async{
// //     var androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
// //
// //
// //     var initializationSetting = InitializationSettings(
// //       android: androidInitializationSettings,
// //     );
// //     await _flutterLocalNotificationsPlugin.initialize(
// //         initializationSetting,
// //         onDidReceiveNotificationResponse: (payload){
// //         }
// //     );
// //   }
// //
// //
// //   void firebaseInit(){
// //
// //     FirebaseMessaging.onMessage.listen((message) {
// //       if (kDebugMode) {
// //         print(message.notification!.title.toString());
// //         print(message.notification!.body.toString());
// //       }
// //       // showNotification(message);
// //     });
// //   }
// //
// //   Future<void> showNotification(RemoteMessage message)async{
// //
// //     AndroidNotificationChannel channel = AndroidNotificationChannel(
// //         Random.secure().nextInt(100000).toString(),
// //         'High Importance Notification',
// //         importance: Importance.max
// //     );
// //
// //     AndroidNotificationDetails androidNotificationDetails =  AndroidNotificationDetails(
// //         channel.id.toString(),
// //         channel.name.toString(),
// //         channelDescription: 'your channel description',
// //         importance: Importance.high,
// //         priority: Priority.high,
// //         ticker: 'ticker'
// //       // 'High Importance Notification'
// //     );
// //
// //     NotificationDetails notificationDetails = NotificationDetails(
// //       android: androidNotificationDetails,
// //     );
// //
// //     Future.delayed(Duration.zero, (){
// //       _flutterLocalNotificationsPlugin.show(
// //           1,
// //           message.notification!.title.toString(),
// //           message.notification!.body.toString(),
// //           notificationDetails);
// //     });
// //   }
// //
// //
// //
// //
// //   Future<String> getDeviceToken()async{
// //     String? token = await messaging.getToken();
// //     return token!;
// //   }
// //   void  isTokenRefresh()async{
// //     messaging.onTokenRefresh.listen((event) {
// //       event.toString();
// //       print('refresh');
// //     });
// //   }
// // }
// //
// //
// //
// // class NotificationHandler {
// //   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
// //   FlutterLocalNotificationsPlugin();
// //
// //   static Future<void> initialize() async {
// //     FirebaseMessaging messaging = FirebaseMessaging.instance;
// //
// //     // Configure local notifications
// //     const AndroidInitializationSettings initializationSettingsAndroid =
// //     AndroidInitializationSettings('@mipmap/ic_launcher');
// //     const InitializationSettings initializationSettings =
// //     InitializationSettings(
// //       android: initializationSettingsAndroid,
// //     );
// //     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
// //
// //     // Request permission for notifications
// //     await messaging.requestPermission();
// //
// //     // Configure Firebase messaging
// //     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
// //       _showLocalNotification(message);
// //     });
// //
// //     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
// //       _handleNotificationTap(message);
// //     });
// //
// //     // Check if the app was opened from a terminated state
// //     RemoteMessage? initialMessage =
// //     await FirebaseMessaging.instance.getInitialMessage();
// //     if (initialMessage != null) {
// //       _handleNotificationTap(initialMessage);
// //     }
// //   }
// //
// //   static void _showLocalNotification(RemoteMessage message) async {
// //     const AndroidNotificationDetails androidPlatformChannelSpecifics =
// //     AndroidNotificationDetails(
// //       'channel_id',
// //       'channel_name',
// //       importance: Importance.max,
// //       priority: Priority.high,
// //       icon: '@mipmap-hdpi/ic_launcher.png',
// //     );
// //     const NotificationDetails platformChannelSpecifics = NotificationDetails(
// //       android: androidPlatformChannelSpecifics,
// //     );
// //
// //     await flutterLocalNotificationsPlugin.show(
// //       0,
// //       message.notification?.title,
// //       message.notification?.body,
// //       platformChannelSpecifics,
// //       payload: message.data.toString(),
// //     );
// //   }
// //
// //   static Future<void> _handleNotificationTap(RemoteMessage message) async {
// //     // Handle the notification tap event here
// //     // You can navigate to a specific screen or perform any other action
// //     SharedPreferences prefs = await SharedPreferences.getInstance();
// //     String clientId = prefs.getString('clientId') ?? '';
// //     String email = prefs.getString('email') ?? '';
// //     String phone = prefs.getString('phone') ?? '';
// //     String username = prefs.getString('username') ?? '';
// //     String status = prefs.getString('status') ?? '';
// //     String created = prefs.getString('created') ?? '';
// //     String modified = prefs.getString('modified') ?? '';
// //     String project_id = prefs.getString('project_id') ?? '';
// //     String projectUniqueCode = prefs.getString('project_unique_code') ?? '';
// //     // For example, if you want to navigate to the ApiScreen when the notification is tapped:
// //     Navigator.push(
// //       MyApp.navigatorKey.currentContext!,
// //       MaterialPageRoute(
// //         builder: (context) => ApiScreen(
// //           user: User(
// //             clientId: clientId,
// //             email: email,
// //             phone: phone,
// //             username: username,
// //             status: status,
// //             created: created,
// //             modified: modified,
// //             project_id: project_id,
// //             project_unique_code: projectUniqueCode, /* Add the necessary fields from the notification */
// //           ),
// //           selectedProjectCode: projectUniqueCode,
// //           projectUrl: '',
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
//
//
//
// static Future<void> _handleNotificationTap(RemoteMessage message) async {
// SharedPreferences prefs = await SharedPreferences.getInstance();
// String clientId = prefs.getString('clientId') ?? '';
// String email = prefs.getString('email') ?? '';
// String phone = prefs.getString('phone') ?? '';
// String username = prefs.getString('username') ?? '';
// String status = prefs.getString('status') ?? '';
// String created = prefs.getString('created') ?? '';
// String modified = prefs.getString('modified') ?? '';
// String project_id = prefs.getString('project_id') ?? '';
// String projectUniqueCode = prefs.getString('project_unique_code') ?? '';
//
// // Extract the notification type from the payload
// String notificationType = message.data['notificationType'];
//
// switch (notificationType) {
// case 'enquiry':
// // Redirect to the appropriate screen for the 'enquiry' notification
// Navigator.pushReplacement(
// MyApp.navigatorKey.currentContext!,
// MaterialPageRoute(
// builder: (context) => ApiScreen(
// user: User(
// clientId: clientId,
// email: email,
// phone: phone,
// username: username,
// status: status,
// created: created,
// modified: modified,
// project_id: project_id,
// project_unique_code: projectUniqueCode, /* Add the necessary fields from the notification */
// ),
// selectedProjectCode: projectUniqueCode,
// projectUrl: '',
// ),
// ),
// );
// break;
// case 'liveChat':
// // Redirect to the appropriate screen for the 'liveChat' notification
// Navigator.pushReplacement(
// MyApp.navigatorKey.currentContext!,
// MaterialPageRoute(
// builder: (context) => LivechatScreenn(
// user: User(
// clientId: clientId,
// email: email,
// phone: phone,
// username: username,
// status: status,
// created: created,
// modified: modified,
// project_id: project_id,
// project_unique_code: projectUniqueCode, /* Add the necessary fields from the notification */
// ),
// selectedProjectCode: projectUniqueCode,
// projectUrl: '',
// ),
// ),
// );
// break;
// // Add more cases if needed for other notification types
// default:
// // Handle other cases or do nothing
// break;
// }
// }





// static Future<void> _handleNotificationTap(RemoteMessage message) async {
// String notificationType = message.data['notification_type'];
//
//
// SharedPreferences prefs = await SharedPreferences.getInstance();
// String clientId = prefs.getString('clientId') ?? '';
// String email = prefs.getString('email') ?? '';
// String phone = prefs.getString('phone') ?? '';
// String username = prefs.getString('username') ?? '';
// String status = prefs.getString('status') ?? '';
// String created = prefs.getString('created') ?? '';
// String modified = prefs.getString('modified') ?? '';
// String project_id = prefs.getString('project_id') ?? '';
// String projectUniqueCode = prefs.getString('project_unique_code') ?? '';
//
// if (notificationType == 'api') {
// // Handle redirection for API notification
// // Example: Redirect to ApiScreen
// Navigator.pushReplacement(
// MyApp.navigatorKey.currentContext!,
// MaterialPageRoute(
// builder: (context) => ApiScreen(
// user: User(
// clientId: clientId,
// email: email,
// phone: phone,
// username: username,
// status: status,
// created: created,
// modified: modified,
// project_id: project_id,
// project_unique_code: projectUniqueCode, /* Add the necessary fields from the notification */
// ),
// selectedProjectCode: projectUniqueCode,
// projectUrl: '',
// ),
// ),
// );
// } else if (notificationType == 'livechat') {
// // Handle redirection for Livechat notification
// // Example: Redirect to LiveChatScreen
// Navigator.pushReplacement(
// MyApp.navigatorKey.currentContext!,
// MaterialPageRoute(
// builder: (context) => LivechatScreenn(
// user: User(
// clientId: clientId,
// email: email,
// phone: phone,
// username: username,
// status: status,
// created: created,
// modified: modified,
// project_id: project_id,
// project_unique_code: projectUniqueCode, /* Add the necessary fields from the notification */
// ),
// selectedProjectCode: projectUniqueCode,
// projectUrl: '',
// ),
// ),
// );
// }
//
// // You can add more conditions for additional notification types if needed.
// }
