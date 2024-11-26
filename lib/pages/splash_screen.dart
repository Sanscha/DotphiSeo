import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher package
import '../model/login_model.dart';
import 'login_screen.dart';
import 'navbar.dart';

class SplashScreen extends StatefulWidget {
  final selectedProjectCode;
  final User user;
  final String projectUrl;

  SplashScreen({
    required this.user,
    required this.selectedProjectCode,
    required this.projectUrl,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    Future.delayed(Duration(seconds: 4), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // Check if the update prompt has been shown
      bool updateShown = prefs.getBool('updateShown') ?? false;

      if (!updateShown) {
        // Show the upgrade prompt only if it hasn't been shown before
        Upgrader upgrader = Upgrader();

        // Check if the update is required
        bool shouldUpdate = await upgrader.shouldDisplayUpgrade();

        if (shouldUpdate) {
          _showUpdateDialog();
          prefs.setBool('updateShown', true); // Set flag to prevent future prompts
        }
      }

      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => NavBarScreen(
              user: widget.user,
              selectedProjectCode: widget.selectedProjectCode,
              projectUrl: widget.projectUrl,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => LoginScreenn(),
          ),
        );
      }
    });
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Available"),
        content: Text("A new version of the app is available. Please update to the latest version."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Later"),
          ),
          TextButton(
            onPressed: () async {
              // Open the app store for updating the app
              String url = "https://play.google.com/store/apps/details?id=com.yourapp"; // For Android
              // String url = "https://apps.apple.com/us/app/your-app/id123456789"; // For iOS

              if (await canLaunch(url)) {
                await launch(url); // Open app store
              } else {
                throw 'Could not open the store.';
              }
              Navigator.of(context).pop();
            },
            child: Text("Update Now"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Change the background color
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[900]!, Colors.blue[400]!],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: _animation.value,
                child: Opacity(
                  opacity: _animation.value,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/dotphi.png',
                          height: 150,
                          width: 150,
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
