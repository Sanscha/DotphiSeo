import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VideoviewsScreen extends StatefulWidget {
  const VideoviewsScreen({super.key});

  @override
  State<VideoviewsScreen> createState() => _VideoviewsScreenState();
}

class _VideoviewsScreenState extends State<VideoviewsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Video-Views",style: TextStyle(color: Colors.blue.shade900,fontFamily: 'Poppins',fontSize: 20,fontWeight: FontWeight.bold),),
        ));
  }
}
