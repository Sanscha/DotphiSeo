import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GrowthaudienceScreen extends StatefulWidget {
  List<dynamic> posts;

  GrowthaudienceScreen({
    required this.posts ,super.key});

  @override
  State<GrowthaudienceScreen> createState() => _GrowthaudienceScreenState();
}

class _GrowthaudienceScreenState extends State<GrowthaudienceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Growth & Audience",style: TextStyle(color: Colors.blue.shade900,fontFamily: 'Poppins',fontSize: 20,fontWeight: FontWeight.bold),),
        ));
  }
}