import 'package:dotphi_seo_app/pages/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../drawer.dart';
import '../model/login_model.dart';

class AnalyticsScreen extends StatefulWidget {
  final User user;
  final String projectUrl;


  AnalyticsScreen({required this.user,required this.projectUrl,
  });
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
    Container(
    decoration: BoxDecoration(
    image: DecorationImage(
        image: AssetImage('assets/images/bgseo.jpg'),
    fit: BoxFit.cover,
    ),
    ),
    ),
    Scaffold(
    backgroundColor: Colors.transparent,

    appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 5,
    toolbarHeight: 50,
    toolbarOpacity: 0.7,
    shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
    bottomRight: Radius.circular(25),
    bottomLeft: Radius.circular(25),
    ),
    ),

    title:  Text(
    'Analytics',
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color:Colors.blue.shade900),
    ),
    ),
      body: WebView(
        initialUrl: 'https://www.googletagmanager.com/gtag/js?id=UA-207906808-1',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    )] );
  }
}