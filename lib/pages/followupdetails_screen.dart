import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FollowupdetailsScreen extends StatefulWidget {
  final Map<String, dynamic> followUp;
  const FollowupdetailsScreen({super.key, required this.followUp});

  @override
  State<FollowupdetailsScreen> createState() => _FollowupdetailsScreenState();
}

class _FollowupdetailsScreenState extends State<FollowupdetailsScreen> {
  List<Map<String, dynamic>> activities = [];
  final TextEditingController _messageController = TextEditingController();
  String? _filePath;

  // Method to save activities for a specific user
  Future<void> saveActivities(List<Map<String, dynamic>> activities) async {
    final prefs = await SharedPreferences.getInstance();
    String activitiesJson = jsonEncode(activities);

    // Use the user's name or another unique identifier as the key
    String userKey = widget.followUp['name']; // or widget.followUp['seoId'] if SEO ID is used
    await prefs.setString(userKey, activitiesJson);
  }

  // Method to load activities for a specific user
  Future<void> loadActivities() async {
    final prefs = await SharedPreferences.getInstance();

    // Use the user's name or another unique identifier as the key
    String userKey = widget.followUp['name']; // or widget.followUp['seoId']
    String? activitiesJson = prefs.getString(userKey);

    if (activitiesJson != null) {
      List<dynamic> decodedList = jsonDecode(activitiesJson);
      setState(() {
        activities = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  // Method to add an activity
  void _addActivity(String type, String details) async {
    setState(() {
      activities.add({
        'type': type,
        'details': details,
        'date': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      });
    });

    // Save updated activities to SharedPreferences
    await saveActivities(activities);
  }

  void _sendSMS(BuildContext context, String message, String recipient) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message will be sent through sms!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS.')),
      );
      throw 'Could not launch SMS';
    }
  }

  Future<void> _sendWhatsAppMessage(BuildContext context, String message, String recipient) async {
    bool fileSelected = _filePath != null && _filePath!.isNotEmpty;

    // If a file is selected, share the file along with the message
    if (fileSelected) {
      try {
        // Convert the file path to an XFile
        XFile xFile = XFile(_filePath!);

        // Use Share.shareXFiles to share the file along with the message
        await Share.shareXFiles(
          [xFile], // Pass the XFile as a list
          text: message.isNotEmpty
              ? message
              : null, // Share the message if it's not empty
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File and message shared successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share file and message: $e')),
        );
      }
    }

    // Send only the message via WhatsApp if it's present
    if (message.isNotEmpty) {
      final Uri whatsappUri = Uri(
        scheme: 'https',
        host: 'wa.me',
        path: recipient,
        queryParameters: {
          'text': message, // The message to send
        },
      );

      try {
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message sent through WhatsApp!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message via WhatsApp.')),
          );
          throw 'Could not launch WhatsApp';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }

    // Handle the case where neither file nor message is present
    if (!fileSelected && message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file or message to send.')),
      );
    }
  }
  void launchDialer(String phoneNumber) async {
    // Clean the phone number by removing 'p:+91' or any similar prefix
    String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'^p:\+91'), '');

    final url = 'tel:$cleanedPhoneNumber'; // Create the URL to dial the number

    if (await canLaunch(url)) {
      await launch(url); // Launch the dialer with the cleaned phone number
    } else {
      print('Could not launch the dialer');
    }
  }


  @override
  void initState() {
    super.initState();
    loadActivities();  // Load activities when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.followUp['name']}:',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  Text(
                    widget.followUp['phone'].replaceAll(RegExp(r'^p:'), ''),
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width / 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async{
                          _addActivity('Follow up via', 'WhatsApp');
                          final phoneNumber =
                                widget.followUp['phone']?.replaceAll(RegExp(r'^p:\+91'),'');
                            final whatsappUrl = 'https://wa.me/$phoneNumber';
                            final whatsappInstalled = await canLaunch(whatsappUrl);
                            if (whatsappInstalled) {
                              launch(whatsappUrl);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                  Text('WhatsApp is not installed on your device.'),
                                ),
                              );
                            }
                        },
                        child: Image.asset(
                          'assets/images/whatsapp.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _addActivity('Follow up via', 'Text-message');
                          launch(
                              'sms:${widget.followUp['phone']?.replaceAll(RegExp(r'^p:\+91'), '') ?? 'No phone'}');
                        },
                        child: Image.asset(
                          'assets/images/sms.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _addActivity('Follow up via', 'Call');
                          launch(
                              'tel:${widget.followUp['phone']?.replaceAll(RegExp(r'^p:\+91'), '') ?? 'No phone'}'
                          );
                          },
                        child: Image.asset(
                          'assets/images/telephone.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 15),
              Column(
                children: [
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                        onPressed: () {
                          _addActivity('Status Changed', 'Interested');
                        },
                        child: Text('Interested',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            )),
                      ),
                      SizedBox(width: 15),
                      TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                        onPressed: () {
                          _addActivity('Status Changed', 'Not Connected');
                        },
                        child: Text('Not Connected',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            )),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                        onPressed: () {
                          _addActivity('Status Changed', 'In Progress');
                        },
                        child: Text('In Progress',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            )),
                      ),
                      SizedBox(width: 15),
                      TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                        onPressed: () {
                          _addActivity('Status Changed', 'Not Answered');
                        },
                        child: Text('Not Answered',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            )),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                        onPressed: () {
                          _addActivity('Status Changed', 'Converted');
                        },
                        child: Text('Converted',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            )),
                      ),
                      SizedBox(width: 15),
                      TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                        onPressed: () {
                          _addActivity('Status Changed', 'Visited');
                        },
                        child: Text('Visited',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            )),
                      ),
                      SizedBox(width: 15),
                      TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                        onPressed: () {
                          _addActivity('Status Changed', 'Dead');
                        },
                        child: Text('Dead',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Divider(),
              SizedBox(height: 5,),
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Follow up',style:
                    TextStyle( fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,),),
                    GestureDetector(
                      onTap: (){
                        _addActivity('Followup date changed', 'Date');
                      },
                      child: Text("Set follow up",
                        style: TextStyle( fontSize: 15,
                          color: Colors.blue.shade900,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,),),
                    )
                  ],
                ),
              ),
              SizedBox(height: 15),
              Divider(),
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timeline',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Container(
                height: 300,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 3,
                        color: Colors.black,
                        height: double.infinity,
                        margin: EdgeInsets.only(left: 15),
                      ),
                    ),
                    ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 30.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 12),
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${activity['type']}: ${activity['details']}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    activity['date'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
