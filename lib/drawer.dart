// // // // // import 'package:dotphi_seo_app/model/login_model.dart';
// // // // // import 'package:dotphi_seo_app/pages/home_screen.dart';
// // // // // import 'package:dotphi_seo_app/pages/leads_screen.dart';
// // // // // import 'package:flutter/material.dart';
// // // // //
// // // // // class MainDrawer extends StatefulWidget {
// // // // //   final String username;
// // // // //   final String email;
// // // // //   final User user;
// // // // //
// // // // //   const MainDrawer({
// // // // //     Key? key,
// // // // //     required this.username,
// // // // //     required this.email,
// // // // //     required this.user,
// // // // //   }) : super(key: key);
// // // // //
// // // // //   @override
// // // // //   State<MainDrawer> createState() => _MainDrawerState();
// // // // // }
// // // // //
// // // // // class _MainDrawerState extends State<MainDrawer> {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return ClipRRect(
// // // // //       borderRadius: const BorderRadius.only(
// // // // //         topRight: Radius.circular(30),
// // // // //         bottomRight: Radius.circular(30),
// // // // //       ),
// // // // //       child: Drawer(
// // // // //         width: 300,
// // // // //         backgroundColor: Colors.white,
// // // // //         child: ListView(
// // // // //           children: [
// // // // //             Container(
// // // // //
// // // // //               child: UserAccountsDrawerHeader(
// // // // //                 decoration: const BoxDecoration(
// // // // //                   color: Color.fromARGB(255, 236, 81, 70),
// // // // //                 ),
// // // // //                 accountName: Text(
// // // // //                   "Welcome ${widget.username}",
// // // // //                   style: const TextStyle(),
// // // // //                 ),
// // // // //                 accountEmail: Text(
// // // // //                   widget.email,
// // // // //                   style: const TextStyle(),
// // // // //                 ),
// // // // //                 currentAccountPicture: Image.asset(
// // // // //                   'assets/images/dotphi.png',
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //             Padding(
// // // // //               padding: const EdgeInsets.all(20),
// // // // //               child: Column(
// // // // //                 children: [
// // // // //
// // // // //                   ListTile(
// // // // //                     leading: const Icon(Icons.leaderboard),
// // // // //                     title: const Text("Leads"),
// // // // //                     onTap: () {
// // // // //                       Navigator.of(context).pop();
// // // // //                       Navigator.push(
// // // // //                         context,
// // // // //                         MaterialPageRoute(
// // // // //                             builder: (context) =>  ApiScreen(user: widget.user,
// // // // //                                 )),
// // // // //                       );
// // // // //                     },
// // // // //                   ),
// // // // //                   ListTile(
// // // // //                     leading: const Icon(Icons.home),
// // // // //                     title: const Text("Home Page"),
// // // // //                     onTap: () {
// // // // //                       Navigator.of(context).pop();
// // // // //                       Navigator.pushReplacement(
// // // // //                         context,
// // // // //                         MaterialPageRoute(
// // // // //                             builder: (context) => HomeScreenn(user: widget.user,
// // // // //
// // // // //                                 )),
// // // // //                       );
// // // // //                     },
// // // // //                   ),
// // // // //
// // // // //                 ],
// // // // //               ),
// // // // //             )
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // //
// // // //
// // // //
// // // // import 'dart:convert';
// // // // import 'package:http/http.dart' as http;
// // // // import 'package:dotphi_seo_app/model/login_model.dart';
// // // // import 'package:dotphi_seo_app/pages/home_screen.dart';
// // // // import 'package:dotphi_seo_app/pages/leads_screen.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:flutter_svg/flutter_svg.dart';
// // // //
// // // //
// // // // class MainDrawer extends StatefulWidget {
// // // //   final String username;
// // // //   final String email;
// // // //   final User user;
// // // //
// // // //   const MainDrawer({
// // // //     Key? key,
// // // //     required this.username,
// // // //     required this.email,
// // // //     required this.user,
// // // //   }) : super(key: key);
// // // //
// // // //   @override
// // // //   State<MainDrawer> createState() => _MainDrawerState();
// // // // }
// // // //
// // // // class _MainDrawerState extends State<MainDrawer> {
// // // //   List<String> _projectUniqueCodes = [];
// // // //   String? _selectedProjectCode;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _fetchProjectUniqueCodes().then((codes) {
// // // //       setState(() {
// // // //         _projectUniqueCodes = codes;
// // // //         if (_projectUniqueCodes.isNotEmpty) {
// // // //           _selectedProjectCode = _projectUniqueCodes[0];
// // // //         }
// // // //       });
// // // //     });
// // // //   }
// // // //
// // // //   Future<List<String>> _fetchProjectUniqueCodes() async {
// // // //
// // // //     SharedPreferences prefs = await SharedPreferences.getInstance();
// // // //     String? clientId = prefs.getString('clientId') ?? '';
// // // //
// // // //     final url = Uri.parse('https://clients.dotphi.com/Api/login/multiple_project');
// // // //     final response = await http.post(
// // // //       url,
// // // //       body: {
// // // //         'client_id': clientId,
// // // //       },
// // // //     );
// // // //
// // // //     if (response.statusCode == 200) {
// // // //       final jsonData = json.decode(response.body);
// // // //       if (jsonData['status'] == 'success') {
// // // //         final data = jsonData['data'] as List<dynamic>;
// // // //         final uniqueCodes = data.map((item) => item['project_unique_code'].toString()).toList();
// // // //         return uniqueCodes;
// // // //       }
// // // //     }
// // // //
// // // //     return [];
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return ClipRRect(
// // // //       borderRadius: const BorderRadius.only(
// // // //         topRight: Radius.circular(30),
// // // //         bottomRight: Radius.circular(30),
// // // //       ),
// // // //       child: Drawer(
// // // //         width: 300,
// // // //         backgroundColor: Colors.white,
// // // //         child: ListView(
// // // //           children: [
// // // //             Container(
// // // //               child: UserAccountsDrawerHeader(
// // // //                 decoration: const BoxDecoration(
// // // //                   color: Color.fromARGB(255, 236, 81, 70),
// // // //                 ),
// // // //                 accountName: Text(
// // // //                   "Welcome ${widget.username}",
// // // //                   style: const TextStyle(),
// // // //                 ),
// // // //                 accountEmail: Text(
// // // //                   widget.email,
// // // //                   style: const TextStyle(),
// // // //                 ),
// // // //                 currentAccountPicture: Image.asset(
// // // //                   'assets/images/dotphi.png',
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             Padding(
// // // //               padding: const EdgeInsets.all(20),
// // // //               child: Column(
// // // //                 children: [
// // // //                   ListTile(
// // // //                     leading: const Icon(Icons.leaderboard),
// // // //                     title: const Text("Leads"),
// // // //                     onTap: () {
// // // //                       Navigator.of(context).pop();
// // // //                       Navigator.push(
// // // //                         context,
// // // //                         MaterialPageRoute(
// // // //                           builder: (context) => ApiScreen(user: widget.user),
// // // //                         ),
// // // //                       );
// // // //                     },
// // // //                   ),
// // // //                   ListTile(
// // // //                     leading: const Icon(Icons.home),
// // // //                     title: const Text("Home Page"),
// // // //                     onTap: () {
// // // //                       Navigator.of(context).pop();
// // // //                       Navigator.pushReplacement(
// // // //                         context,
// // // //                         MaterialPageRoute(
// // // //                           builder: (context) => HomeScreenn(user: widget.user),
// // // //                         ),
// // // //                       );
// // // //                     },
// // // //                   ),
// // // //                   if (_projectUniqueCodes.isEmpty)
// // // //                     const Text(
// // // //                       'No code to select',
// // // //                       style: TextStyle(color: Colors.grey),
// // // //                     )
// // // //                   else
// // // //                     DropdownButtonFormField<String>(
// // // //                       value: _selectedProjectCode,
// // // //                       onChanged: (String? newValue) async {
// // // //                         SharedPreferences prefs = await SharedPreferences.getInstance();
// // // //                         prefs.setString('project_unique_code', newValue ?? '');
// // // //                         setState(() {
// // // //                           _selectedProjectCode = newValue;
// // // //                         });
// // // //
// // // //                         // Fetch API data in the ApiScreen widget
// // // //                         _ApiScreenState apiScreenState = context.findAncestorStateOfType<_ApiScreenState>()!;
// // // //                         apiScreenState.fetchApiData();
// // // //                       },
// // // //                       items: _projectUniqueCodes.map((code) {
// // // //                         return DropdownMenuItem<String>(
// // // //                           value: code,
// // // //                           child: Text(code),
// // // //                         );
// // // //                       }).toList(),
// // // //                     ),
// // // //
// // // //
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // //
// // //
// // // // import 'dart:convert';
// // // // import 'package:dotphi_seo_app/pages/home_screen.dart';
// // // // import 'package:dotphi_seo_app/pages/leads_screen.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:url_launcher/url_launcher.dart';
// // // //
// // // // import 'model/login_model.dart';
// // // //
// // // //
// // // // class MainDrawer extends StatefulWidget {
// // // //   final String username;
// // // //   final String email;
// // // //   final User user;
// // // //
// // // //   const MainDrawer({
// // // //     Key? key,
// // // //     required this.username,
// // // //     required this.email,
// // // //     required this.user,
// // // //   }) : super(key: key);
// // // //
// // // //   @override
// // // //   _MainDrawerState createState() => _MainDrawerState();
// // // // }
// // // //
// // // // class _MainDrawerState extends State<MainDrawer> {
// // // //   List<String> _projectUniqueCodes = [];
// // // //   String? _selectedProjectCode;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _fetchProjectUniqueCodes().then((codes) {
// // // //       setState(() {
// // // //         _projectUniqueCodes = codes;
// // // //         if (_projectUniqueCodes.isNotEmpty) {
// // // //           _selectedProjectCode = _projectUniqueCodes[0];
// // // //         }
// // // //       });
// // // //     });
// // // //   }
// // // //
// // // //   Future<List<String>> _fetchProjectUniqueCodes() async {
// // // //     SharedPreferences prefs = await SharedPreferences.getInstance();
// // // //     String? clientId = prefs.getString('clientId') ?? '';
// // // //
// // // //     final url = Uri.parse('https://clients.dotphi.com/Api/login/multiple_project');
// // // //     final response = await http.post(
// // // //       url,
// // // //       body: {
// // // //         'client_id': clientId,
// // // //       },
// // // //     );
// // // //
// // // //     if (response.statusCode == 200) {
// // // //       final jsonData = json.decode(response.body);
// // // //       if (jsonData['status'] == 'success') {
// // // //         final data = jsonData['data'] as List<dynamic>;
// // // //         final uniqueCodes = data.map((item) => item['project_unique_code'].toString()).toList();
// // // //         return uniqueCodes;
// // // //       }
// // // //     }
// // // //
// // // //     return [];
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return ClipRRect(
// // // //       borderRadius: const BorderRadius.only(
// // // //         topRight: Radius.circular(30),
// // // //         bottomRight: Radius.circular(30),
// // // //       ),
// // // //       child: Drawer(
// // // //         width: 300,
// // // //         backgroundColor: Colors.white,
// // // //         child: ListView(
// // // //           children: [
// // // //             Container(
// // // //               child: UserAccountsDrawerHeader(
// // // //                 decoration: const BoxDecoration(
// // // //                   color: Color.fromARGB(255, 236, 81, 70),
// // // //                 ),
// // // //                 accountName: Text(
// // // //                   "Welcome ${widget.username}",
// // // //                   style: const TextStyle(),
// // // //                 ),
// // // //                 accountEmail: Text(
// // // //                   widget.email,
// // // //                   style: const TextStyle(),
// // // //                 ),
// // // //                 currentAccountPicture: Image.asset(
// // // //                   'assets/images/dotphi.png',
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             Padding(
// // // //               padding: const EdgeInsets.all(20),
// // // //               child: Column(
// // // //                 children: [
// // // //                   ListTile(
// // // //                     leading: const Icon(Icons.leaderboard),
// // // //                     title: const Text("Leads"),
// // // //                     onTap: () {
// // // //                       Navigator.of(context).pop();
// // // //                       Navigator.push(
// // // //                         context,
// // // //                         MaterialPageRoute(
// // // //                           builder: (context) => ApiScreen(user: widget.user, selectedProjectCode: _selectedProjectCode),
// // // //                         ),
// // // //                       );
// // // //                     },
// // // //                   ),
// // // //                   ListTile(
// // // //                     leading: const Icon(Icons.home),
// // // //                     title: const Text("Home Page"),
// // // //                     onTap: () {
// // // //                       Navigator.of(context).pop();
// // // //                       Navigator.pushReplacement(
// // // //                         context,
// // // //                         MaterialPageRoute(
// // // //                           builder: (context) => HomeScreenn(user: widget.user),
// // // //                         ),
// // // //                       );
// // // //                     },
// // // //                   ),
// // // //
// // // // if (_projectUniqueCodes.isEmpty)
// // // // const Text(
// // // // 'No projects found',
// // // // style: TextStyle(color: Colors.grey),
// // // // ),
// // // // if (_projectUniqueCodes.isNotEmpty)
// // // // DropdownButton<String>(
// // // // value: _selectedProjectCode,
// // // // items: _projectUniqueCodes.map((String code) {
// // // // return DropdownMenuItem<String>(
// // // // value: code,
// // // // child: Text(code),
// // // // );
// // // // }).toList(),
// // // // onChanged: (String? newValue) {
// // // // setState(() {
// // // // _selectedProjectCode = newValue;
// // // // });
// // // // },
// // // // ),
// // // // const SizedBox(height: 20),
// // // // ListTile(
// // // // leading: const Icon(Icons.logout),
// // // // title: const Text("Logout"),
// // // // onTap: () async {
// // // // SharedPreferences prefs = await SharedPreferences.getInstance();
// // // // await prefs.clear();
// // // // Navigator.pushReplacementNamed(context, '/login');
// // // // },
// // // // ),
// // // // const Divider(),
// // // // ListTile(
// // // // leading: const Icon(Icons.info),
// // // // title: const Text("About Us"),
// // // // onTap: () {
// // // // _launchURL('https://www.example.com/about');
// // // // },
// // // // ),
// // // // ListTile(
// // // // leading: const Icon(Icons.privacy_tip),
// // // // title: const Text("Privacy Policy"),
// // // // onTap: () {
// // // // _launchURL('https://www.example.com/privacy');
// // // // },
// // // // ),
// // // // ],
// // // // ),
// // // // ),
// // // // ],
// // // // ),
// // // // ),
// // // // );
// // // // }
// // // //
// // // // Future<void> _launchURL(String url) async {
// // // // if (await canLaunch(url)) {
// // // // await launch(url);
// // // // } else {
// // // // throw 'Could not launch $url';
// // // // }
// // // // }
// // // // }
// // //
// // //
// // //
// // //
// // // import 'dart:convert';
// // // import 'package:dotphi_seo_app/pages/analytics_screen.dart';
// // // import 'package:dotphi_seo_app/pages/keywords_screen.dart';
// // // import 'package:dotphi_seo_app/pages/login_screen.dart';
// // // import 'package:dotphi_seo_app/pages/profile_screen.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:dotphi_seo_app/model/login_model.dart';
// // // import 'package:dotphi_seo_app/pages/home_screen.dart';
// // // import 'package:dotphi_seo_app/pages/leads_screen.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:flutter_svg/flutter_svg.dart';
// // //
// // // class MainDrawer extends StatefulWidget {
// // //   final String username;
// // //   final String email;
// // //   final User user;
// // //   final selectedProjectCode;
// // //
// // //   const MainDrawer({
// // //     Key? key,
// // //     required this.username,
// // //     required this.email,
// // //     required this.user,
// // //     required this.selectedProjectCode
// // //   }) : super(key: key);
// // //
// // //   @override
// // //   State<MainDrawer> createState() => _MainDrawerState();
// // // }
// // //
// // // class _MainDrawerState extends State<MainDrawer> {
// // //   List<String> _projectUniqueCodes = [];
// // //   String? _selectedProjectCode;
// // //   bool isLoggedIn = false;
// // //
// // //
// // //
// // //
// // //
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     checkLoginStatus();
// // //     _fetchProjectUniqueCodes().then((codes) {
// // //       setState(() {
// // //         _projectUniqueCodes = codes;
// // //         _loadSelectedProjectCode(); // Load the selected value from shared preferences
// // //       });
// // //     });
// // //   }
// // //
// // //   Future<List<String>> _fetchProjectUniqueCodes() async {
// // //     SharedPreferences prefs = await SharedPreferences.getInstance();
// // //     String? clientId = prefs.getString('clientId') ?? '';
// // //
// // //     final url = Uri.parse('https://clients.dotphi.com/Api/login/multiple_project');
// // //     final response = await http.post(
// // //       url,
// // //       body: {
// // //         'client_id': clientId,
// // //       },
// // //     );
// // //
// // //     if (response.statusCode == 200) {
// // //       final jsonData = json.decode(response.body);
// // //       if (jsonData['status'] == 'success') {
// // //         final data = jsonData['data'] as List<dynamic>;
// // //         final uniqueCodes = data.map((item) => item['project_unique_code'].toString()).toList();
// // //         return uniqueCodes;
// // //       }
// // //     }
// // //
// // //     return [];
// // //   }
// // //
// // //   Future<void> _loadSelectedProjectCode() async {
// // //     SharedPreferences prefs = await SharedPreferences.getInstance();
// // //     setState(() {
// // //       _selectedProjectCode = prefs.getString('project_unique_code') ?? '';
// // //     });
// // //   }
// // //
// // //   Future<void> _saveSelectedProjectCode(String value) async {
// // //     SharedPreferences prefs = await SharedPreferences.getInstance();
// // //     await prefs.setString('project_unique_code', value);
// // //   }
// // //
// // //   void checkLoginStatus() async {
// // //     SharedPreferences prefs = await SharedPreferences.getInstance();
// // //     setState(() {
// // //       isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
// // //     });
// // //   }
// // //
// // //   void logout() async {
// // //     SharedPreferences prefs = await SharedPreferences.getInstance();
// // //     prefs.setBool('isLoggedIn', false); // Clear login status
// // //     // Perform any additional logout operations if necessary
// // //     Navigator.pushReplacement(
// // //       context,
// // //       MaterialPageRoute(builder: (context) => LoginScreenn(selectedProjectCode: widget.selectedProjectCode,)),
// // //     );
// // //   }
// // //
// // //
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return ClipRRect(
// // //       borderRadius: const BorderRadius.only(
// // //         topRight: Radius.circular(30),
// // //         bottomRight: Radius.circular(30),
// // //       ),
// // //       child: Drawer(
// // //         width: 300,
// // //         backgroundColor: Colors.white,
// // //         child: ListView(
// // //             children: [
// // //         Container(
// // //         child: UserAccountsDrawerHeader(
// // //         decoration: const BoxDecoration(
// // //             color: Color.fromARGB(255, 236, 81, 70),
// // //       ),
// // //       accountName: Text(
// // //         "Welcome ${widget.username}",
// // //         style: const TextStyle(),
// // //       ),
// // //       accountEmail: Text(
// // //         widget.email,
// // //         style: const TextStyle(),
// // //       ),
// // //       currentAccountPicture: Image.asset(
// // //         'assets/images/dotphi.png',
// // //       ),
// // //     ),
// // //     ),
// // //     Padding(
// // //     padding: const EdgeInsets.all(20),
// // //     child: Column(
// // //     children: [
// // //
// // //
// // //       ListTile(
// // //         leading: const Icon(Icons.person),
// // //         title: const Text('Profile'),
// // //         onTap: () {
// // //           Navigator.of(context).pop();
// // //           Navigator.push(
// // //             context,
// // //             MaterialPageRoute(
// // //               builder: (context) => ProfileScreen(
// // //                   user: widget.user
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //       ListTile(
// // //         leading: const Icon(Icons.home),
// // //         title: const Text("Home Page"),
// // //         onTap: () {
// // //           Navigator.of(context).pop();
// // //           Navigator.pushReplacement(
// // //             context,
// // //             MaterialPageRoute(
// // //               builder: (context) => HomeScreenn(user: widget.user, selectedProjectCode: null,),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //
// // //       ListTile(
// // //         leading: const Icon(Icons.key),
// // //         title: const Text("Keyword"),
// // //         onTap: () {
// // //           Navigator.of(context).pop();
// // //           Navigator.pushReplacement(
// // //             context,
// // //             MaterialPageRoute(
// // //               builder: (context) => KeywordScreen(user: widget.user,),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //       ListTile(
// // //         leading: const Icon(Icons.analytics),
// // //         title: const Text('Master Analytics'),
// // //         onTap: () {
// // //           Navigator.of(context).pop();
// // //           Navigator.push(
// // //             context,
// // //             MaterialPageRoute(
// // //               builder: (context) => AnalyticsScreen(
// // //                   user: widget.user
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //
// // //
// // //
// // //     ListTile(
// // //     leading: const Icon(Icons.leaderboard),
// // //     title: const Text("Leads"),
// // //     onTap: () {
// // //     Navigator.of(context).pop();
// // //     Navigator.push(
// // //     context,
// // //     MaterialPageRoute(
// // //     builder: (context) => ApiScreen
// // //       (
// // //
// // //       user: widget.user, selectedProjectCode: _selectedProjectCode
// // //     ),
// // //     ));
// // //     },
// // //     ),
// // //       const SizedBox(height: 10),
// // //       DropdownButtonFormField<String>(
// // //         decoration: InputDecoration(
// // //           labelText: 'Projects',
// // //           border: OutlineInputBorder(),
// // //         ),
// // //         value: _selectedProjectCode,
// // //         items: _projectUniqueCodes.map((String value) {
// // //           return DropdownMenuItem<String>(
// // //             value: value,
// // //             child: Text(value),
// // //           );
// // //         }).toList(),
// // //         onChanged: (String? newValue) async {
// // //           setState(() {
// // //             _selectedProjectCode = newValue;
// // //           });
// // //           await _saveSelectedProjectCode(newValue ?? '');
// // //         },
// // //       ),
// // //       ListTile(
// // //         leading: const Icon(Icons.logout),
// // //         title: const Text("LogOut"),
// // //         onTap:
// // //
// // //           logout
// // //
// // //         ,
// // //       ),
// // //     ],
// // //     ),
// // //     ),
// // //             ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// import 'dart:convert';
// import 'package:dotphi_seo_app/pages/analytics_screen.dart';
// import 'package:dotphi_seo_app/pages/keywords_screen.dart';
// import 'package:dotphi_seo_app/pages/login_screen.dart';
// import 'package:dotphi_seo_app/pages/navbar.dart';
// import 'package:dotphi_seo_app/pages/profile_screen.dart';
// import 'package:http/http.dart' as http;
// import 'package:dotphi_seo_app/model/login_model.dart';
// import 'package:dotphi_seo_app/pages/home_screen.dart';
// import 'package:dotphi_seo_app/pages/leads_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//
// class MainDrawer extends StatefulWidget {
//   final String username;
//   final String email;
//   final User user;
//   final String? selectedProjectCode;
//   final String projectUrl; // Add this line
//   String? _projectUrl; // Add this line
//
//   MainDrawer({
//     required this.username,
//     required this.email,
//     required this.user,
//     required this.selectedProjectCode,
//     required this.projectUrl, // Add this line
//   }) {
//     _projectUrl = projectUrl; // Add this line
//   }
//
//
//   @override
//   State<MainDrawer> createState() => _MainDrawerState();
// }
//
// class _MainDrawerState extends State<MainDrawer> {
//   List<String> _projectUniqueCodes = [];
//   String? _selectedProjectCode;
//   bool isLoggedIn = false;
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     checkLoginStatus();
//     _fetchProjectUniqueCodes().then((codes) {
//       setState(() {
//         _projectUniqueCodes = codes;
//         _loadSelectedProjectCode(); // Load the selected value from shared preferences
//       });
//     });
//   }
//
//   Future<List<String>> _fetchProjectUniqueCodes() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? clientId = prefs.getString('clientId') ?? '';
//     setState(() {
//       isLoading = true;
//     });
//
//
//
//
//     final url = Uri.parse('https://clients.dotphi.com/Api/login/multiple_project');
//     final response = await http.post(
//       url,
//       body: {
//         'client_id': clientId,
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       if (jsonData['status'] == 'success') {
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         prefs.setString('loginResponse', response.body);
//         prefs.setBool('isLoggedIn', true);
//         final data = jsonData['data'] as List<dynamic>;
//         final uniqueCodes = data.map((item) => item['project_unique_code'].toString()).toList();
//         return uniqueCodes;
//       }
//     }
//     setState(() {
//       isLoading = false;
//     });
//     return [];
//   }
//
//   Future<void> _loadSelectedProjectCode() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _selectedProjectCode = prefs.getString('project_unique_code') ?? '';
//     });
//   }
//
//   Future<void> _saveSelectedProjectCode(String value) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('project_unique_code', value);
//   }
//
//   void checkLoginStatus() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//     });
//   }
//
//   void logout() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setBool('isLoggedIn', false); // Clear login status
//     // Perform any additional logout operations if necessary
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => LoginScreenn(selectedProjectCode: widget.selectedProjectCode,  projectUrl: widget.projectUrl )),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: const BorderRadius.only(
//         topRight: Radius.circular(30),
//         bottomRight: Radius.circular(30),
//       ),
//       child: Drawer(
//         width: 300,
//         backgroundColor: Colors.white,
//         child: Container(
//           decoration: BoxDecoration(
//             image: DecorationImage(
//                 image: AssetImage("assets/images/bgseo.jpg"),
//                 fit: BoxFit.cover,
//                 scale: 1
//             ),
//           ),
//           child: ListView(
//             children: [
//               Container(
//                 child: UserAccountsDrawerHeader(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [Colors.blue[900]!, Colors.blue[400]!],
//                     ),
//                   ),
//                   accountName: Text(
//                     "Welcome ${widget.username}",
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   accountEmail: Text(
//                     widget.email,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.white,
//                     ),
//                             ),
//
//                   currentAccountPicture: Container(
//                     width: 30, // Adjust the width as needed
//                     height: 30, // Adjust the height as needed
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.white.withOpacity(1),
//                          /* spreadRadius: 1,
//                           blurRadius: 1,*/
//                           offset: Offset(0, 2), // Adjust the offset to control the shadow position
//                         ),
//                       ],
//                     ),
//                     child: ClipOval(
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Image.asset(
//                         'assets/images/logo1.png',
//                         fit: BoxFit.scaleDown, // Adjust the fit property
//                               ),
//                       ),
//                           ),
//                         ),),
//                         padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
//                       ),
//               Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     DropdownButtonFormField<String>(
//                       decoration: InputDecoration(
//                         labelText: 'Projects',
//                         border: OutlineInputBorder(),
//                       ),
//                       value: _selectedProjectCode,
//                       items: _projectUniqueCodes.map((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(value),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) async {
//                         setState(() {
//                           _selectedProjectCode = newValue;
//                         });
//                         await _saveSelectedProjectCode(newValue ?? '');
//                       },
//                     ),
//                     // ListTile(
//                     //   leading: Icon(
//                     //     Icons.person,
//                     //     color: Colors.grey[800],
//                     //   ),
//                     //   title: Text(
//                     //     'Profile',
//                     //     style: TextStyle(
//                     //       fontSize: 16,
//                     //       color: Colors.grey[800],
//                     //     ),
//                     //   ),
//                     //   onTap: () {
//                     //     Navigator.of(context).pop();
//                     //     Navigator.push(
//                     //       context,
//                     //       MaterialPageRoute(
//                     //         builder: (context) => ProfileScreen(user: widget.user),
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//                     ListTile(
//                       leading: Icon(
//                         Icons.home,
//                         color: Colors.grey[800],
//                       ),
//                       title: Text(
//                         "Home Page",
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[800],
//                         ),
//                       ),
//                       onTap: () {
//                         Navigator.of(context).pop();
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 NavBarScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,  projectUrl: widget.projectUrl),
//                           ),
//                         );
//                       },
//                     ),
//                     // ListTile(
//                     //   leading: Icon(
//                     //     Icons.key,
//                     //     color: Colors.grey[800],
//                     //   ),
//                     //   title: Text(
//                     //     "Keyword",
//                     //     style: TextStyle(
//                     //       fontSize: 16,
//                     //       color: Colors.grey[800],
//                     //     ),
//                     //   ),
//                     //   onTap: () {
//                     //     Navigator.of(context).pop();
//                     //     Navigator.pushReplacement(
//                     //       context,
//                     //       MaterialPageRoute(
//                     //         builder: (context) => KeywordScreen(user: widget.user),
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//                     // ListTile(
//                     //   leading: Icon(
//                     //     Icons.analytics,
//                     //     color: Colors.grey[800],
//                     //   ),
//                     //   title: Text(
//                     //     'Master Analytics',
//                     //     style: TextStyle(
//                     //       fontSize: 16,
//                     //       color: Colors.grey[800],
//                     //     ),
//                     //   ),
//                     //   onTap: () {
//                     //     Navigator.of(context).pop();
//                     //     Navigator.push(
//                     //       context,
//                     //       MaterialPageRoute(
//                     //         builder: (context) => AnalyticsScreen(user: widget.user),
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//                     // ListTile(
//                     //   leading: Icon(
//                     //     Icons.leaderboard,
//                     //     color: Colors.grey[800],
//                     //   ),
//                     //   title: Text(
//                     //     "Leads",
//                     //     style: TextStyle(
//                     //       fontSize: 16,
//                     //       color: Colors.grey[800],
//                     //     ),
//                     //   ),
//                     //   onTap: () {
//                     //     Navigator.of(context).pop();
//                     //     Navigator.push(
//                     //       context,
//                     //       MaterialPageRoute(
//                     //         builder: (context) =>
//                     //             ApiScreen(
//                     //           user: widget.user,
//                     //           selectedProjectCode: _selectedProjectCode,
//                     //         ),
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//                     const SizedBox(height: 10),
//
//                     ListTile(
//                       leading: Icon(
//                         Icons.logout,
//                         color: Colors.grey[800],
//                       ),
//                       title: Text(
//                         "LogOut",
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[800],
//                         ),
//                       ),
//                       onTap: logout,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
