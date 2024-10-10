import 'package:dotphi_seo_app/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'model/login_model.dart';


class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();
  final User user;

  const MyApp({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DotphiSeo',
      home:
      SplashScreen(user: user, selectedProjectCode: user.project_unique_code,projectUrl: '',),
      debugShowCheckedModeBanner: false,
    );
  }
}
