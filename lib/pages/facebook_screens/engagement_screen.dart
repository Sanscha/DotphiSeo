import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class EngagementScreen extends StatefulWidget {
  final int numberOfPosts;
  final String selectedPageName;
  final int pageViews;
  final int totalReactions;
  final int totalEngagements ; // Variable to store the total engagement count
  final double totalEngagementRate ;
  final int totalImpressions ;
  final double totalVVR;

  // Constructor to initialize the variables
  EngagementScreen({
    required this.numberOfPosts,
    required this.selectedPageName,
    required this.pageViews,
    required this.totalReactions,
    required this.totalEngagements,
    required this.totalEngagementRate,
    required this.totalImpressions,
    required this.totalVVR

  });

  @override
  State<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends State<EngagementScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Text('Engagement',style: TextStyle(color: Colors.blue.shade900,fontFamily: 'Poppins',fontSize: 20,fontWeight: FontWeight.bold),),
        ],
      ),),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(

          child: Column(
            children: [
              Text(widget.selectedPageName,style: TextStyle(fontFamily: 'Poppins',fontSize: 15,fontWeight: FontWeight.w600),),
              SizedBox(height: 30,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text('Posts by Profile:',style: TextStyle(fontFamily: 'Poppins',fontSize: 15,fontWeight: FontWeight.w600),),
                          Text(widget.numberOfPosts.toString(),style: TextStyle(fontFamily: 'Poppins',fontSize: 15,),),
                        ],
                      ),
                    ),
                  ),
                  Container(

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15)),
                    child: Center(
                      child: Column(
                        children: [
                          Text('Page Views:',style: TextStyle(fontFamily: 'Poppins',fontSize: 15,fontWeight: FontWeight.w600),),
                          Text(widget.pageViews.toString(),style: TextStyle(fontFamily: 'Poppins',fontSize: 15,),),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text('Total Reactions:',style: TextStyle(fontFamily: 'Poppins',fontSize: 15,fontWeight: FontWeight.w600),),
                          Text(widget.totalReactions.toString(),style: TextStyle(fontFamily: 'Poppins',fontSize: 15,),),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text('Public Engagements:',style: TextStyle(fontFamily: 'Poppins',fontSize: 15,fontWeight: FontWeight.w600),),
                          Text(widget.totalEngagements.toString(),style: TextStyle(fontFamily: 'Poppins',fontSize: 15,),),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Center(
                      child: Column(
                        children: [
                          Text('Total Reactions:',style: TextStyle(fontFamily: 'Poppins',fontSize: 15,fontWeight: FontWeight.w600),),
                          Text(widget.totalReactions.toString(),style: TextStyle(fontFamily: 'Poppins',fontSize: 15,),),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    child: Center(
                      child: Column(
                        children: [
                          Text('Public Engagements:',style: TextStyle(fontFamily: 'Poppins',fontSize: 15,fontWeight: FontWeight.w600),),
                          Text(widget.totalEngagements.toString(),style: TextStyle(fontFamily: 'Poppins',fontSize: 15,),),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
