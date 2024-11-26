import 'dart:convert';
import 'package:dotphi_seo_app/pages/seo_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  final String accessToken;

  const DashboardScreen({
    Key? key,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  int? userId;
  String? pageName;
  String? pageId;
  String? pageAccessToken;
  List<Map<String, dynamic>> pages = []; // List to store pages
  String? selectedPageName;
  String? selectedPageId;
  Map<String, dynamic> pageMetrics = {
    'postsCount': 0,
    'pageViews': 0,
    'reactions': 0,
    'comments': 0,
    'shares': 0,
  };


  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://graph.facebook.com/v12.0/me?fields=id,name&access_token=${widget.accessToken}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          userName = data['name'];
          userId = int.tryParse(data['id'].toString()) ?? 0;
        });
        _fetchPageDetails();
      } else {
        throw Exception("Failed to fetch user details");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user details: $e")),
      );
    }
  }

  Future<void> _fetchPageDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://graph.facebook.com/v12.0/me/accounts?access_token=${widget.accessToken}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            pages = List<Map<String, dynamic>>.from(data['data']);
            print(pages);
          });

          // Optionally fetch page details for each page using their access token
          for (var page in pages) {
            await _fetchPageDetailsByToken(page['access_token'], page['id']);
          }
        } else {
          throw Exception("No pages found for this user");
        }
      } else {
        throw Exception("Failed to fetch pages");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching page details: $e")),
      );
    }
  }

  Future<void> _fetchPageDetailsByToken(String accessToken, String pageId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://graph.facebook.com/v12.0/$pageId?fields=id,name,about,category&access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        final pageData = jsonDecode(response.body);

        setState(() {
          // Update page details (optional)
          var pageIndex = pages.indexWhere((page) => page['id'] == pageId);
          if (pageIndex != -1) {
            pages[pageIndex].addAll(pageData);
          }
        });
      } else {
        throw Exception("Failed to fetch page details by access token");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching page details by token: $e")),
      );
    }
  }
  Future<void> _fetchPageMetrics(String pageId, String pageAccessToken) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://graph.facebook.com/v12.0/$pageId/posts?fields=message,created_time,likes.summary(true),comments.summary(true)&since=1730023665&until=1732615665&access_token=$pageAccessToken',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);

        // Extract required data from the response
        setState(() {
          pageMetrics['postsCount'] = data['data']?.length ?? 0;
          pageMetrics['reactions'] = data['data']?.fold<int>(
            0,
                (sum, post) =>
            sum + (post['likes']?['summary']?['total_count'] ?? 0),
          ) ??
              0;
          pageMetrics['comments'] = data['data']?.fold<int>(
            0,
                (sum, post) =>
            sum + (post['comments']?['summary']?['total_count'] ?? 0),
          ) ??
              0;
          // Add more metrics as needed
        });
      } else {
        throw Exception("Failed to fetch page metrics");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching page metrics: $e")),
      );
    }
  }


  void _logoutFacebook(BuildContext context) async {
    try {
      // Log out from Facebook
      await FacebookAuth.instance.logOut();

      // Optionally, you can show a snackbar or navigate to another screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out from Facebook")),
      );

      // Navigate to a different screen, if needed (e.g., login screen)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SignInScreen()));
    } catch (e) {
      print("Error during Facebook logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error logging out from Facebook")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Material(
          elevation: 8.0, // Set the desired elevation value
          shadowColor: Colors.black.withOpacity(0.3), // Optional: customize shadow color
          borderRadius: BorderRadius.circular(10.0), //
          child: Container(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/facebook.png',
                  height: 25,
                  width: 25,
                ),
                const SizedBox(width: 5),
                // If the page is selected, show the selectedPageName
                if (selectedPageName != null)
                  Text(
                    selectedPageName ?? "Select page", // Show default if no pages
                    style: const TextStyle(
                        fontSize: 16, color: Colors.black, fontFamily: 'Poppins'),
                  ),
                // If the pages list is not empty, show the DropdownButton
                if (pages.isNotEmpty)
                  DropdownButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(
                        color: Colors.black, fontFamily: 'Poppins'),
                    underline: const SizedBox(), // Remove the line
                    onChanged: (String? newPageName) {
                      setState(() {
                        selectedPageName = newPageName;
                        final selectedPage = pages.firstWhere(
                              (page) => page['name'] == newPageName,
                        );
                        selectedPageId = selectedPage['id'];
                        pageAccessToken = selectedPage['access_token'];
                      });

                      // Call the method to fetch metrics for the selected page
                      _fetchPageMetrics(selectedPageId!,pageAccessToken!);
                    },
                    items: pages.map<DropdownMenuItem<String>>((page) {
                      return DropdownMenuItem<String>(
                        value: page['name'],
                        child: Text(page['name'] ?? 'No name available'),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context), // Drawer as usual
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            Text("Posts by Count: $pageMetrics['postsCount']", style: const TextStyle(fontSize: 15,
            fontFamily: 'Poppins')),

          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header with margin from the top
          Container(
            color: Colors.blue.shade900,
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard, // Icon before the title
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        userName != null ? userName![0].toUpperCase() : "?",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userId != null ? "ID: $userId" : "",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
              height: 5), // Margin added between header and list items
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.summarize,
                  title: "Summary",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.content_paste_sharp,
                  title: "Content Feed",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt,
                  title: "Growth & Audience",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.video_collection,
                  title: "Video Views",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.thumb_up,
                  title: "Engagement",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.ads_click,
                  title: "Link Clicks",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(
              "Logout",
              style: TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
            onTap: () {
              _logoutFacebook(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully!")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
        ),
      ),
      onTap: onTap,
    );
  }
}
