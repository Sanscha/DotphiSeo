import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../model/login_model.dart';
import '../my_app.dart';
import '../pages/leads_screen.dart';
import '../pages/livechat.dart';
import 'package:http/http.dart' as http;



class NotificationServices{

  FirebaseMessaging messaging = FirebaseMessaging.instance ;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void  requestNotificationPermission()async{

    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true
    );
    if(settings.authorizationStatus == AuthorizationStatus.authorized){
      print('user granted permission');

    }else if(settings.authorizationStatus == AuthorizationStatus.authorized){
      print('user granted provisional permission');
    }else{
      print('user denied permission');
    }
  }


  void initLocalNotifications(BuildContext context, RemoteMessage message)async{
    var androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSetting = InitializationSettings(
      android: androidInitializationSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(
        initializationSetting,
        onDidReceiveNotificationResponse: (payload){
        }
    );
  }

  void firebaseInit(){
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title.toString());
        print(message.notification!.body.toString());
      }
      // showNotification(message);
    });
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    NotificationHandler._showLocalNotification(message);
  }

  Future<void> showNotification(RemoteMessage message)async{

    AndroidNotificationChannel channel = AndroidNotificationChannel(
        Random.secure().nextInt(100000).toString(),
        'High Importance Notification',
        importance: Importance.max
    );

    AndroidNotificationDetails androidNotificationDetails =  AndroidNotificationDetails(
        channel.id.toString(),
        channel.name.toString(),
        channelDescription: 'your channel description',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker'
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    Future.delayed(Duration.zero, (){
      _flutterLocalNotificationsPlugin.show(
          1,
          message.notification!.title.toString(),
          message.notification!.body.toString(),
          notificationDetails);
    });
  }
  Future<String> getDeviceToken()async{
    String? token = await messaging.getToken();
    return token!;
  }
  void  isTokenRefresh()async{
    messaging.onTokenRefresh.listen((event) {
      event.toString();
      print('refresh');
    });
  }
}


class NotificationHandler {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static List<String> notificationHistory = [];

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    notificationHistory = prefs.getStringList('notificationHistory') ?? [];

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    notificationHistory = prefs.getStringList('notificationHistory') ?? [];

    DateTime now = DateTime.now();
    String date = DateFormat('yyyy-MM-dd').format(now);

    String newNotification =
        "$date - ${message.notification?.title}: ${message.notification?.body}";
    bool isDuplicate = notificationHistory.contains(newNotification);

    if (!isDuplicate) {
      notificationHistory.insert(0, newNotification);
      int maxHistorySize = 10; // Set your desired maximum size
      if (notificationHistory.length > maxHistorySize) {
        notificationHistory.removeLast();
      }
      prefs.setStringList('notificationHistory', notificationHistory);
    }
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    String notificationType = message.data['notification_type'];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String clientId = prefs.getString('clientId') ?? '';
    String email = prefs.getString('email') ?? '';
    String phone = prefs.getString('phone') ?? '';
    String username = prefs.getString('username') ?? '';
    String status = prefs.getString('status') ?? '';
    String created = prefs.getString('created') ?? '';
    String modified = prefs.getString('modified') ?? '';
    String project_id = prefs.getString('project_id') ?? '';
    String projectUniqueCode = prefs.getString('project_unique_code') ?? '';

    if (notificationType == 'api') {
      Navigator.pushReplacement(
        MyApp.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => ApiScreen(
            user: User(
              clientId: clientId,
              email: email,
              phone: phone,
              username: username,
              status: status,
              created: created,
              modified: modified,
              project_id: project_id,
              project_unique_code: projectUniqueCode,
            ),
            selectedProjectCode: projectUniqueCode,
            projectUrl: '',
          ),
        ),
      );
    } else if (notificationType == 'livechat') {

      Navigator.pushReplacement(
        MyApp.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => LivechatScreenn(
            user: User(
              clientId: clientId,
              email: email,
              phone: phone,
              username: username,
              status: status,
              created: created,
              modified: modified,
              project_id: project_id,
              project_unique_code: projectUniqueCode,
            ),
            selectedProjectCode: projectUniqueCode,
            projectUrl: '',
          ),
        ),
      );
    }
  }
  static Future<void> sendNotificationToBackend(
      String title, String description) async {
    final url = Uri.parse('https://clients.dotphi.com/application/controllers/Api/notification.php'); // Replace with your PHP backend URL

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': title,
          'description': description,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Notification sent to backend successfully');
      } else {
        print('Failed to send notification to backend');
      }
    } catch (error) {
      print('Error sending notification to backend: $error');
    }
  }

}