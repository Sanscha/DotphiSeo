import 'package:dotphi_seo_app/pages/home_screen.dart';
import 'package:dotphi_seo_app/pages/livechat.dart';
import 'package:dotphi_seo_app/pages/profile_screen.dart';
import 'package:dotphi_seo_app/pages/seo_checker.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import '../model/login_model.dart';
import 'keywords_screen.dart';
import 'leads_screen.dart';
import 'login_screen.dart';

class NavBarScreen extends StatefulWidget {
  final User user;
  final selectedProjectCode;
  final String projectUrl;

  NavBarScreen({
    Key? key,
    required this.user,


    required this.projectUrl,
    required this.selectedProjectCode,
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
            fit: BoxFit.cover, // You can adjust this to your needs
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: GNav(
                backgroundColor: Colors.white,
                color: Colors.blue.shade900,
                gap: 15,
                activeColor: Colors.white,
                tabBackgroundColor:Colors.blue.shade900,
                padding: const EdgeInsets.all(10),
                tabs: const [
                  GButton(
                    icon: Icons.home,
                    text: 'Home',
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                        color: Colors.white// Change to your desired font family
                      // Change font weight if needed
                    ),
                  ),
                  GButton(
                    icon: Icons.leaderboard,
                    text: 'Leads',
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                        color: Colors.white// Change to your desired font family
                      // Change font weight if needed
                    ),
                  ),
                  GButton(
                    icon: Icons.screen_search_desktop_outlined,
                    text: 'Search-Console',
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                        color: Colors.white// Change to your desired font family
                      // Change font weight if needed
                    ),
                  ),
                  GButton(
                    icon: Icons.key,
                    text: 'Keywords',
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white// Change to your desired font family
                      // Change font weight if needed
                    ),
                  ),
                  GButton(
                    icon: Icons.person,
                    text: 'Profile',
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                        color: Colors.white// Change to your desired font family
                      // Change font weight if needed
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
                    );});},),
            ),
          ),
        ),
      ),
    );
  }
}
