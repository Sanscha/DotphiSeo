import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias the Firebase User
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_model.dart'; // Your custom User model
import '../notification_services/notification_provider.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final User? user; // This is your custom User class
  final String? projectUrl;
  final String? selectedProjectCode;
  final String? username;

  ProfileScreen({
    Key? key,
    this.user,
    this.projectUrl,
    this.selectedProjectCode,
    this.username,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  firebase_auth.User? firebaseUser; // Firebase User aliased here
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    firebaseUser = widget.user as firebase_auth.User?; // Casting custom User to Firebase User
  }

  void checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  Future<void> logout() async {
    try {
      // Check if the user is logged in through Facebook
      final facebookUser = await FacebookAuth.instance.getUserData();

      if (facebookUser.isNotEmpty) {
        // User is logged in through Facebook, so log out from Facebook
        await FacebookAuth.instance.logOut();
        print('Logged out from Facebook');
      }

      // Always log out from Firebase Authentication
      await firebase_auth.FirebaseAuth.instance.signOut();
      print('Logged out from Firebase');

      // Optional: You can also clear any other stored session data if needed
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('isLoggedIn');

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreenn()),
      );
    } catch (e) {
      print('Error while logging out: $e');
    }
  }

  void _launchURL() async {
    const url = 'https://example.com/update'; // Replace with your actual update URL
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user?.username ?? widget.username;
    final email = widget.user?.email ?? '';
    final phone = widget.user?.phone ?? '';
    final unreadCount = Provider.of<UnreadCountProvider>(context).unreadCount;

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
                  onTap: logout,
                  child: Image.asset('assets/images/log.gif'),
                ),
              ),
            ],
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/images/profile.png',
                height: 10,
                width: 10,
              ),
            ),
            title: Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
          body: displayName == null
              ? Center(
            child: SpinKitCircle(
              color: Colors.blue.shade900,
            ),
          )
              : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[900],
                      child: Text(
                        displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Welcome $displayName",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileDetailTile(
                    icon: Icons.person_outline,
                    title: displayName,
                  ),
                  const SizedBox(height: 15),
                  if (email.isNotEmpty)
                    ProfileDetailTile(
                      icon: Icons.email_outlined,
                      title: email,
                    ),
                  const SizedBox(height: 15),
                  if (phone.isNotEmpty)
                    ProfileDetailTile(
                      icon: Icons.phone,
                      title: phone,
                    ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: _launchURL,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                      ),
                      child: const Text(
                        'Check for Update',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileDetailTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const ProfileDetailTile({
    Key? key,
    required this.icon,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        leading: Icon(
          icon,
          size: 28,
          color: Colors.black,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            color: Colors.black,
          ),
        ),
      ),
    );
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
