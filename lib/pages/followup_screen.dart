import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'followupdetails_screen.dart';

class FollowupScreen extends StatefulWidget {
  final String? projectUniqueCode;
  final String? campaignId;

  const FollowupScreen({
    this.projectUniqueCode,
    this.campaignId,
  });

  @override
  State<FollowupScreen> createState() => _FollowupScreenState();
}

class _FollowupScreenState extends State<FollowupScreen> {
  List<Map<String, dynamic>> _followUps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Call the API function in initState
    getFollowUps(
      projectUniqueCode: widget.projectUniqueCode,
      campaignId: widget.campaignId,
    );
  }

  Future<void> launchDialer(String phoneNumber) async {
    final Uri dialUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(dialUri)) {
      await launchUrl(dialUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  // Future<void> showFollowUpNotification(String title, String body) async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //   AndroidNotificationDetails(
  //     'followup_channel', // Channel ID
  //     'Follow-Up Notifications', // Channel name
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     icon: 'assets/images/dotphi.png', // Custom icon for notification
  //   );
  //
  //   const NotificationDetails platformChannelSpecifics =
  //   NotificationDetails(android: androidPlatformChannelSpecifics);
  //
  //   await flutterLocalNotificationsPlugin.show(
  //     0, // Notification ID
  //     title,
  //     body,
  //     platformChannelSpecifics,
  //   );
  // }

  Future<void> getFollowUps({String? projectUniqueCode, String? campaignId,}) async {
    final url = Uri.parse('https://clients.dotphi.com/Api/login/followup_list');

    final body = {
      if (projectUniqueCode != null) 'project_unique_code': projectUniqueCode,
      if (campaignId != null) 'campaign_id': campaignId,
    };

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _followUps = List<Map<String, dynamic>>.from(data['data']);
            print(_followUps);
            isLoading = false; // Data loaded
          });

          // Check for follow-up dates close to today and show notifications
          // checkAndShowFollowUpNotifications();
        } else {
          print('Error: ${data['message']}');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // void checkAndShowFollowUpNotifications() {
  //   DateTime today = DateTime.now();
  //   for (var followUp in _followUps) {
  //     String? followUpDateStr = followUp['followup'];
  //     if (followUpDateStr != null) {
  //       DateTime followUpDate = DateTime.parse(followUpDateStr);
  //
  //       // Check if the follow-up date is today or within the next 2 days
  //       if (followUpDate.isAtSameMomentAs(today) ||
  //           followUpDate.isBefore(today.add(Duration(days: 2)))) {
  //         showFollowUpNotification(
  //           'Follow-Up Reminder',
  //           'You have a follow-up with ${followUp['name']} due on ${followUpDate.toLocal()}',
  //         );
  //       }
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Follow-ups',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ),
      ),
      body: Container(
        child: isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitCircle(
              color: Colors.blue.shade900,
              size: 100.0,
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )
            : _followUps.isEmpty
            ? Container(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/nodata.png',
            height: 150,
            width: 150,
          ),
        )
            : ListView.builder(
          itemCount: _followUps.length,
          itemBuilder: (context, index) {
            final followUp = _followUps[index];
            return GestureDetector(
              onTap: (){Navigator.push(context, MaterialPageRoute(builder: (context)=>FollowupdetailsScreen(followUp: followUp)));},
              child: Container(
                margin: EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Row(
                    children: [
                      Image.asset(
                        followUp['source'] == 'seo_data'
                            ? 'assets/images/email.gif'
                            : followUp['source'] == 'paid_leads'
                            ? 'assets/images/advertising.gif'
                            : followUp['source'] == 'live_leads'
                            ? 'assets/images/chatleads.gif'
                            : 'assets/images/unknown_user.png',
                        width: 40,
                        height: 40,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    followUp['name'] ??
                                        'Unknown Name',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  followUp['followup'] ??
                                      'Unknown Date',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 10),
                                Text(
                                  followUp['phone']
                                      ?.replaceAll(
                                      RegExp(r'[^0-9]'), '')
                                      ?.replaceFirst(
                                      RegExp(r'^91'), '') ??
                                      'No phone',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
