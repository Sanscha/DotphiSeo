import 'package:dotphi_seo_app/pages/home_screen.dart';
import 'package:dotphi_seo_app/pages/livechat.dart';
import 'package:dotphi_seo_app/pages/paid_leads_screen.dart';
import 'package:dotphi_seo_app/pages/profile_screen.dart';
import 'package:dotphi_seo_app/pages/seo_checker.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import '../model/login_model.dart';
import 'keywords_screen.dart';
import 'leads_screen.dart';
import 'login_screen.dart';

class NavBarScreen extends StatefulWidget {
  final User? user; // Made nullable
  final String? selectedProjectCode; // Made nullable
  final String? projectUrl; // Made nullable

  NavBarScreen({
    Key? key,
    this.user, // No longer required
    this.projectUrl, // No longer required
    this.selectedProjectCode, // No longer required
  }) : super(key: key);

  @override
  _NavBarScreenState createState() => _NavBarScreenState();
}

class _NavBarScreenState extends State<NavBarScreen> {

  int _selectedIndex = 0;
  bool isLoggedIn = false;
  late PageController _pageController;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    _pageController = PageController(initialPage: _selectedIndex);
    _widgetOptions = [
      UpgradeAlert(
        child: HomeScreenn(
          user: widget.user,  projectUrl: widget.projectUrl,
          selectedProjectCode: widget.selectedProjectCode,
        ),
      ),
      // TabularScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,
      //   projectUrl: widget.projectUrl,),
      ApiScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,
        projectUrl: widget.projectUrl,),
      PaidLeadsScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,
        projectUrl: widget.projectUrl,),
      // LivechatScreenn(user: widget.user, projectUrl: widget.projectUrl, selectedProjectCode: widget.selectedProjectCode,),
      SignInScreen(),
      KeywordScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,projectUrl: widget.projectUrl),
      ProfileScreen(user: widget.user, projectUrl: widget.projectUrl, selectedProjectCode: widget.selectedProjectCode,),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false); // Clear login status
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreenn()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          return PageView(
            controller: _pageController,
            children: _widgetOptions,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          );
        },
      ),
      bottomNavigationBar:
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/conbg.jpg'), // Replace with your image path
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: GNav(
                backgroundColor: Colors.white,
                color: Colors.blue.shade900,
                gap: 8, // Reduced gap between icons
                activeColor: Colors.white,
                curve: Curves.easeIn,
                tabBackgroundColor: Colors.blue.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced padding
                tabs: const [
                  GButton(
                    icon: Icons.home,
                    // text: 'Home',
                    iconSize: 22, // Smaller icon size
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12, // Smaller text size
                      color: Colors.white,
                    ),
                  ),
                  GButton(
                    icon: Icons.leaderboard,
                    // text: 'Leads',
                    iconSize: 22,
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  GButton(
                    icon: Icons.attach_money,
                    // text: 'Paid-Leads',
                    iconSize: 22,
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  GButton(
                    icon: Icons.screen_search_desktop_outlined,
                    // text: 'Search-Console',
                    iconSize: 22,
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  GButton(
                    icon: Icons.key,
                    // text: 'Keywords',
                    iconSize: 22,
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  GButton(
                    icon: Icons.person,
                    // text: 'Profile',
                    iconSize: 22,
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _pageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
              ),
            ),
          ),
        ),
      )


    );
  }
}
