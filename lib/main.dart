import 'package:dotphi_seo_app/notification_services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'model/login_model.dart';
import 'my_app.dart';
import 'notification_services/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  User user = await getUser();
  await Firebase.initializeApp();
  await NotificationHandler.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => UnreadCountProvider(),
      child: MyApp(user: user),
    ),
  );
}