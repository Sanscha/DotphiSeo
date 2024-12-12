import 'dart:async';
import 'package:dotphi_seo_app/pages/paid_leads_screen.dart';
import 'package:dotphi_seo_app/pages/profile_screen.dart';
import 'package:dotphi_seo_app/pages/seo_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_model.dart';
import '../notification_services/notification_provider.dart';
import 'keywords_screen.dart';
import 'leads_screen.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'notification_screen.dart';

class HomeScreenn extends StatefulWidget {
  final User? user; // Made nullable
  final String? selectedProjectCode; // Made nullable
  final String? projectUrl; // Made nullable

  HomeScreenn({
    Key? key,
    this.user, // No longer required
    this.selectedProjectCode, // No longer required
    this.projectUrl, // No longer required
  }) : super(key: key);


  @override
  State<HomeScreenn> createState() => _HomeScreennState();
}

class _HomeScreennState extends State<HomeScreenn> {
  StreamController<List<Map<String, dynamic>>> _notificationStreamController =
      StreamController<List<Map<String, dynamic>>>();
  List<Map<String, dynamic>> _notifications = [];

  bool isLoggedIn = false;
  List<String> _projectUniqueCodes = [];
  String? selectedProjectCode;
  bool isLoading = false;
  bool isInternetConnected = true;
  String? projectUrl;
  Map<String, String> _projectData = {};
  int _tillDateLeadCount = 0;
  int _todayLeadCount = 0;
  int _weeklyLeadCount = 0;
  int _monthlyLeadCount = 0;
  String? selectedProjectId;
  Map<String, String> _projectIds = {};
  int currentYear = DateTime.now().year;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchLeadCounts(projectCode: selectedProjectCode);
    _fetchDataAndUpdateScreen();
    _checkInternetConnectivity();
    _fetchProjectUniqueCodes().then((codes) {
      setState(() {
        _projectUniqueCodes = codes;
        _loadSelectedProjectCode();
        _loadProjectUrl();
      });
    });
    fetchNotifications();
    startListeningForUpdates();
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }

  void startListeningForUpdates() {
    Timer.periodic(Duration(seconds: 30), (timer) {
      fetchNotifications();
    });
  }

  Future<void> fetchNotifications() async {
    final url = Uri.parse(
        'https://clients.dotphi.com/application/controllers/Api/notification_feeder.php?project_code=${widget.selectedProjectCode}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _notifications = responseData.map((notification) {
            return {
              'id': notification['id'],
              'title': notification['title'],
              'description': notification['description'],
              'time': (notification['date_time']),
              'read': notification['read'],
            };
          }).toList();
          unreadCount = _notifications.where((n) => !n['read']).length;
          final newUnreadCount = _notifications.where((n) => !n['read']).length;
          Provider.of<UnreadCountProvider>(context, listen: false)
              .updateUnreadCount(newUnreadCount);
          print('CODE::::$selectedProjectCode');
        });
      } else {
        print('Failed to fetch notifications');
      }
    } catch (error) {
      print('Error fetching notifications: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDataAndUpdateScreen();
  }

  Future<void> _fetchDataAndUpdateScreen() async {
    _fetchProjectData().then((data) {
      setState(() {
        _projectData = data;
        _loadSelectedProjectCode();
        if (_projectData.length == 1) {
          _fetchProjectUrl(_projectData.keys.first);
        }
        selectedProjectId = _projectIds[selectedProjectCode ?? ''];
        fetchLeadCounts(projectCode: selectedProjectCode);
      });
    });
    _loadProjectUrl();
  }

  Future<void> fetchLeadCounts({String? projectId, String? projectCode}) async {
    // If projectId is null and projectCode is provided, map it to a projectId
    if (projectId == null && projectCode != null) {
      projectId = _projectIds[projectCode];
    }

    // Start loading
    setState(() {
      isLoading = true; // Start loading spinner
    });

    try {
      // Fetch both regular and live chat lead counts
      final leadCounts = await Future.wait([
        _fetchLeadCountsFromApi(projectId,
            tillDateApi: 'https://clients.dotphi.com/Api/Login/getCountofLeads',
            todayApi: 'https://clients.dotphi.com/Api/Login/getTodayLeads',
            weeklyApi: 'https://clients.dotphi.com/Api/Login/getWeeklyLeads',
            monthlyApi: 'https://clients.dotphi.com/Api/Login/getMonthlyLeads'),
        _fetchLeadCountsFromApi(projectId,
            tillDateApi:
                'https://clients.dotphi.com/Api/login/getCountofliveLeads',
            todayApi: 'https://clients.dotphi.com/Api/login/getTodayliveLeads',
            weeklyApi:
                'https://clients.dotphi.com/Api/login/getWeeklyliveLeads',
            monthlyApi:
                'https://clients.dotphi.com/Api/login/getMonthlyLiveLeads'),
      ]);

      // Extract results from Future.wait
      final regularCounts = leadCounts[0];
      final liveCounts = leadCounts[1];

      // Update the state with fetched counts
      setState(() {
        _tillDateLeadCount =
            (regularCounts['tillDate']! + liveCounts['tillDate']!);
        _todayLeadCount = regularCounts['today']! + liveCounts['today']!;
        _weeklyLeadCount = regularCounts['weekly']! + liveCounts['weekly']!;
        _monthlyLeadCount = regularCounts['monthly']! + liveCounts['monthly']!;
        isLoading = false; // Stop loading spinner
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tillDateLeadCount_$projectId', _tillDateLeadCount);
      await prefs.setInt('todayLeadCount_$projectId', _todayLeadCount);
      await prefs.setInt('weeklyLeadCount_$projectId', _weeklyLeadCount);
      await prefs.setInt('monthlyLeadCount_$projectId', _monthlyLeadCount);
    } catch (e) {
      // Handle any errors here
      print('Failed to fetch lead counts: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  Future<Map<String, int>> _fetchLeadCountsFromApi(
    String? projectId, {
    required String tillDateApi,
    required String todayApi,
    required String weeklyApi,
    required String monthlyApi,
  }) async {
    // Define a map to hold the results
    final Map<String, int> leadCounts = {
      'tillDate': 0,
      'today': 0,
      'weekly': 0,
      'monthly': 0,
    };

    try {
      // Fetch Till Date Lead Count
      final tillDateResponse = await http.post(Uri.parse(tillDateApi), body: {
        'project_id': projectId,
      });
      if (tillDateResponse.statusCode == 200) {
        final data = json.decode(tillDateResponse.body);
        leadCounts['tillDate'] = data['Till_the_date_lead_count'] as int;
      }

      // Fetch Today Lead Count
      final todayResponse = await http.post(Uri.parse(todayApi), body: {
        'project_id': projectId,
      });
      if (todayResponse.statusCode == 200) {
        final data = json.decode(todayResponse.body);
        leadCounts['today'] = data['Today_lead_count'] as int;
      }

      // Fetch Weekly Lead Count
      final weeklyResponse = await http.post(Uri.parse(weeklyApi), body: {
        'project_id': projectId,
      });
      if (weeklyResponse.statusCode == 200) {
        final data = json.decode(weeklyResponse.body);
        leadCounts['weekly'] = data['weekly_lead_count'] as int;
      }

      // Fetch Monthly Lead Count
      final monthlyResponse = await http.post(Uri.parse(monthlyApi), body: {
        'project_id': projectId,
      });
      if (monthlyResponse.statusCode == 200) {
        final data = json.decode(monthlyResponse.body);
        leadCounts['monthly'] = data['Monthly_lead_count'] as int;
      }
    } catch (e) {
      print('Failed to fetch lead counts from API: $e');
    }

    return leadCounts;
  }

  Future<Map<String, String>> _fetchProjectData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString('clientId') ?? '';

    setState(() {
      isLoading = true;
    });

    final url =
        Uri.parse('https://clients.dotphi.com/Api/Login/multiple_project');
    final response = await http.post(
      url,
      body: {
        'client_id': clientId,
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('loginResponse', response.body);
        prefs.setBool('isLoggedIn', true);

        final data = jsonData['data'] as List<dynamic>;
        final projectData = Map<String, String>();
        for (var project in data) {
          final uniqueCode = project['project_unique_code'].toString();
          final projectName = project['project_name'].toString();
          final projectId = project['project_id'].toString(); // Add this line
          projectData[uniqueCode] = projectName;
          _projectIds[uniqueCode] = projectId; // Add this line
        }
        return projectData;
      }
    }

    setState(() {
      isLoading = false;
    });
    return {};
  }

  Future<List<String>> _fetchProjectUniqueCodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString('clientId') ?? '';
    setState(() {
      isLoading = true;
    });

    final url =
        Uri.parse('https://clients.dotphi.com/Api/Login/multiple_project');
    final response = await http.post(
      url,
      body: {
        'client_id': clientId,
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        print(jsonData);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('loginResponse', response.body);
        prefs.setBool('isLoggedIn', true);
        final data = jsonData['data'] as List<dynamic>;
        final uniqueCodes =
            data.map((item) => item['project_unique_code'].toString()).toList();
        return uniqueCodes;
      }
    }
    setState(() {
      isLoading = false;
    });
    return [];
  }

  Future<void> _loadSelectedProjectCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedProjectCode = prefs.getString('project_unique_code') ?? '';
    });
  }

  Future<void> _saveSelectedProjectCode(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('project_unique_code', value);
  }

  void checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  Future<void> _checkInternetConnectivity() async {
    bool isConnected;
    try {
      isConnected = await InternetConnectionChecker().hasConnection;
    } on Exception catch (_) {
      isConnected = false;
    }

    if (!isConnected) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('No Internet Connection'),
            content:
                Text('Please check your internet connection and try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> showProjectPopup() async {
    if (_projectUniqueCodes.length == 1) {
      selectedProjectCode = _projectUniqueCodes.first;
      await _saveSelectedProjectCode(selectedProjectCode!);
      await _fetchProjectUrl(selectedProjectCode!);
    } else {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Project',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Projects',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedProjectCode,
                  items: _projectData.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) async {
                    setState(() {
                      selectedProjectCode = newValue;
                      selectedProjectId =
                          _projectIds[newValue!]; // Update selectedProjectId
                    });
                    await _saveSelectedProjectCode(newValue ?? '');
                    await _fetchProjectUrl(newValue ?? '');
                    await fetchLeadCounts(projectCode: selectedProjectCode);
                  },
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _loadProjectUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      projectUrl = prefs.getString('projectUrl');
    });
  }

  Future<void> _fetchProjectUrl(String projectCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginResponse = prefs.getString('loginResponse') ?? '';
    final jsonData = json.decode(loginResponse);
    final data = jsonData['data'] as List<dynamic>;
    final project = data.firstWhere(
        (item) => item['project_unique_code'] == projectCode,
        orElse: () => null);
    if (project != null) {
      final url = project['project_url'];
      await prefs.setString(
          'projectUrl', url); // Save the project URL in shared preferences
      setState(() {
        projectUrl = url;
      });
    } else {
      setState(() {
        projectUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int unreadCount = Provider.of<UnreadCountProvider>(context).unreadCount;

    return isLoggedIn ? buildHomeScreen() : LoginScreenn();
  }

  Widget buildHomeScreen() {
    int unreadCount = Provider.of<UnreadCountProvider>(context).unreadCount;
    return Stack(children: [
      Opacity(
        opacity: 0.2,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white,
            toolbarHeight: 80,
            toolbarOpacity: 0.7,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(25),
                bottomLeft: Radius.circular(25),
              ),
            ),
            // leading: Builder(
            //   builder: (context) => IconButton(
            //     icon: Icon(Icons.menu,
            //         color: Colors.blue.shade900), // Drawer icon
            //     onPressed: () {
            //       Scaffold.of(context)
            //           .openDrawer(); // Open the drawer when tapped
            //     },
            //   ),
            // ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Image.asset(
                'assets/images/logo1.png',
                height: 40,
                width: 40,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: showProjectPopup,
                  child: Row(
                    children: [
                      Text(
                        projectUrl != null ? '$projectUrl' : 'Select Project',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 5),
                      Image.asset(
                        'assets/images/dl.png',
                        height: 20,
                        width: 20,
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.blue.shade900,
                    elevation: 3,
                    shadowColor: Colors.blue.shade900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationHistoryScreen(
                        user: widget.user,
                        projectUrl: widget.projectUrl,
                        selectedProjectCode: widget.selectedProjectCode,
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/notification1.gif',
                      width: 40,
                      height: 40,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // drawer: Drawer(
          //   child: ListView(
          //     padding: EdgeInsets.zero,
          //     children: <Widget>[
          //       Container(
          //         height: 60,
          //         child: DrawerHeader(
          //           decoration: BoxDecoration(
          //             color: Colors.white,
          //           ),
          //           child: Row(
          //             children: [
          //               Image.asset(
          //                 'assets/images/logo1.png',
          //                 height: 40,
          //                 width: 40,
          //               ),
          //               SizedBox(width: 5,),
          //               Text(
          //                 'Dotphi',
          //                 style: TextStyle(
          //                   fontSize: 15.0,
          //                   color: Colors.black,
          //                   fontFamily: 'Poppins',
          //                   fontWeight: FontWeight.bold
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //       ListTile(
          //         leading:SvgPicture.asset('assets/images/house.svg',
          //           width: 20,  // Optional: Set width
          //           height: 20,
          //         color: Colors.blue,),// Optional: Set height),
          //         title: Text(
          //           'Home',
          //           style: TextStyle(
          //             fontSize: 15.0,
          //             color: Colors.black,
          //             fontFamily: 'Poppins',
          //           ),
          //         ),
          //         onTap: () {
          //           Navigator.pop(context);
          //         },
          //       ),
          //       ListTile(
          //         leading:SvgPicture.asset('assets/images/barchart.svg',height: 25,width: 25,),
          //         title: Text(
          //           'Leads',
          //           style: TextStyle(
          //             fontSize: 15.0,
          //             color: Colors.black,
          //             fontFamily: 'Poppins',
          //           ),
          //         ),
          //         onTap: () {
          //           Navigator.push(context, MaterialPageRoute(builder: (context)=> ApiScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,
          //               projectUrl: widget.projectUrl)));
          //
          //         },
          //       ),
          //       ListTile(
          //         leading:SvgPicture.asset('assets/images/wallet.svg',width: 20,height: 20,),
          //         title: Text(
          //           'Paid-Leads',
          //           style: TextStyle(
          //             fontSize: 15.0,
          //             color: Colors.black,
          //             fontFamily: 'Poppins',
          //           ),
          //         ),
          //         onTap: () {
          //           Navigator.push(context, MaterialPageRoute(builder: (context)=>
          //        PaidLeadsScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,
          //        projectUrl: widget.projectUrl,)));
          //         },
          //       ),
          //       ListTile(
          //         leading:SvgPicture.asset('assets/images/report.svg',width: 20,height: 20,),
          //         title: Text(
          //           'Search-Console',
          //           style: TextStyle(
          //             fontSize: 15.0,
          //             color: Colors.black,
          //             fontFamily: 'Poppins',
          //           ),
          //         ),
          //         onTap: () {
          //           Navigator.push(context, MaterialPageRoute(builder: (context)=>SignInScreen()));
          //         },
          //       ),
          //       ListTile(
          //         leading:SvgPicture.asset('assets/images/keywords.svg',width: 25,height: 25,),
          //         title: Text(
          //           'Keywords',
          //           style: TextStyle(
          //             fontSize: 15.0,
          //             color: Colors.black,
          //             fontFamily: 'Poppins',
          //           ),
          //         ),
          //         onTap: () {
          //           Navigator.push(context, MaterialPageRoute(builder: (context)=>KeywordScreen(user: widget.user, selectedProjectCode: widget.selectedProjectCode,projectUrl: widget.projectUrl)));
          //
          //         },
          //       ),
          //       ListTile(
          //         leading: SvgPicture.asset('assets/images/profile.svg',width: 20,height: 20,),
          //         title: Text(
          //           'Profile',
          //           style: TextStyle(
          //             fontSize: 15.0,
          //             color: Colors.black,
          //             fontFamily: 'Poppins',
          //           ),
          //         ),
          //         onTap: () {
          //           Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfileScreen(user: widget.user, projectUrl: widget.projectUrl, selectedProjectCode: widget.selectedProjectCode,)));
          //           },
          //       ),
          //     ],
          //   ),
          // ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/house.png',
                          height: 40,
                          width: 40,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Welcome to SEO App',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Boost your website\'s visibility with Dotphi SEO techniques.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 2,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              10.0), // Adjust the radius as needed
                          child: Image.asset(
                            'assets/images/seobg.gif',
                            width: double.infinity,
                            height: 130,
                            fit: BoxFit.fitWidth,
                          ),
                        )),
                    SizedBox(height: 20),
                    Text(
                      'Lead Count',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DashboardCard(
                                title: 'Total Till Date',
                                count: isLoading
                                    ? SpinKitCircle(
                                        color: Colors.white,
                                        size: 30.0,
                                      )
                                    : _tillDateLeadCount,
                                color: Colors.blue,
                              ),
                              DashboardCard(
                                title: 'Today',
                                count: isLoading
                                    ? SpinKitCircle(
                                        color: Colors.white,
                                        size: 30.0,
                                      )
                                    : _todayLeadCount,
                                color: Colors.green,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DashboardCard(
                                title: 'This week',
                                count: isLoading
                                    ? SpinKitCircle(
                                        color: Colors.white,
                                        size: 30.0,
                                      )
                                    : _weeklyLeadCount,
                                color: Colors.orange,
                              ),
                              DashboardCard(
                                title: 'This month',
                                count: isLoading
                                    ? SpinKitCircle(
                                        color: Colors.white,
                                        size: 30.0,
                                      )
                                    : _monthlyLeadCount,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey.shade300,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          'SEO Tool \npowered by Dotphi',
                          style: TextStyle(
                            fontFamily:
                                'Poppins', // Reference the family name here

                            fontSize: 32,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          '© $currentYear Dotphi SEO Tool',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.grey,
                            // fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    ]);
  }
}

class ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const ServiceTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.teal.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade300,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final dynamic count;
  final Color color;

  DashboardCard(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: MediaQuery.of(context).size.width * 0.45,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Add your custom decoration or illustration here
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Divider(),
                count is int
                    ? Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : count,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
