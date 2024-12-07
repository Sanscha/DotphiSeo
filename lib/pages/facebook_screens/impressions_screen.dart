import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImpressionsScreen extends StatefulWidget {
  const ImpressionsScreen({super.key});

  @override
  State<ImpressionsScreen> createState() => _ImpressionsScreenState();
}

class _ImpressionsScreenState extends State<ImpressionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Impressions",style: TextStyle(color: Colors.blue.shade900,fontFamily: 'Poppins',fontSize: 20,fontWeight: FontWeight.bold),),
        ));
  }
}
