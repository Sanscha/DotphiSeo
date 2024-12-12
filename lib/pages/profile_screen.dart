import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_model.dart';
import '../notification_services/notification_provider.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final User? user; // Made nullable
  final String? projectUrl; // Made nullable
  final String? selectedProjectCode; // Made nullable

  ProfileScreen({
    Key? key,
    this.user, // No longer required
    this.projectUrl, // No longer required
    this.selectedProjectCode, // No longer required
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool isLoggedIn = false;
  int notificationCount = 0; // Added notification count


  @override
  void initState() {
    checkLoginStatus();
    super.initState();
    user = widget.user;
  }

  void checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }


  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('isLoggedIn'); // Remove only the isLoggedIn preference
    // Do not remove selectedProjectCode here
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreenn()), // Make sure to replace LoginScreenn with LoginScreen
    );
  }



  @override
  Widget build(BuildContext context) {
    int unreadCount = Provider.of<UnreadCountProvider>(context).unreadCount;

    return Stack(
        children: [
          SafeArea(
            child: Container(
              color: Colors.white,
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/images/bg.jpg',
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white,
              // elevation: 5,
              toolbarHeight: 50,
              toolbarOpacity: 0.7,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap:
                      logout,
                    child:
                      Image.asset('assets/images/log.gif',)
                  ),
                ),
              ],
              //   actions: [
              //     IconButton(
              //       icon: Icon(Icons.notifications),
              //       onPressed: () {
              //         // Navigate to the notification history screen
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => NotificationHistoryScreen(user: widget.user, projectUrl: widget.projectUrl, selectedProjectCode: widget.selectedProjectCode, context: context,),
              //           ),
              //         );
              //       },
              //     ),
              //   ],
                leading:Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset('assets/images/profile.png',
                  height: 10,
                  width: 10,),
                ),
              title:  Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,  // Reduced font size to fit better
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              )
            ),
            body: user == null
                ? const Center(child: CircularProgressIndicator.adaptive())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Card(
                                        elevation: 8,
                                        shape: CircleBorder(),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.blue[900],
                                          child: Text(
                                            widget.user!.username.substring(0, 2),
                                            style: TextStyle(
                                              fontFamily: 'Poppins', // Reference the family name here
                                              fontWeight: FontWeight.bold,
                                              fontSize: 50,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          Center(
                            child: Text(
                              "Welcome ${user!.username}",
                              style: const TextStyle(
                                fontFamily: 'Poppins', // Reference the family name here

                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),),
                                  ],
                                ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.person_outline,
                                      size: 28,
                                      color: Colors.black,),
                                    title: Text(
                                      widget.user!.username,
                              style: const TextStyle(
                                fontFamily: 'Poppins', // Reference the family name here

                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                              const SizedBox(height: 15),
                              const SizedBox(height: 15),
                              Container(
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
                                  leading: const Icon(
                                    Icons.email_outlined,
                                    size: 28,
                                    color: Colors.black,
                                  ),
                                  title: Text(
                                    widget.user!.email,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins', // Reference the family name here
                                      fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                              const SizedBox(height: 30),
                              Container(
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
                                  leading: const Icon(
                                    Icons.phone,
                                    size: 28,
                                    color: Colors.black,
                                  ),
                                  title: Text(
                                    widget.user!.phone,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins', // Reference the family name here
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                                SizedBox(height: 20,),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _launchURL();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[900],
                                    ),
                                    child: Text('Check for Update',style: TextStyle(
                                      fontSize: 12,color: Colors.white,
                                      fontFamily: 'Poppins',

                                    ),),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )]);
        }
      }

void _launchURL() async {
  const url = 'https://play.google.com/store/apps/details?id=com.dotphi.dotphi_seo_app&pcampaignid=web_share';
  if (await canLaunch(url)) {
    await launch(url);
  }
  else {
    throw 'Could not launch $url';
  }
}