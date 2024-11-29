import 'dart:convert';
import 'dart:io';
import 'package:contacts_service/contacts_service.dart';
import 'package:dotphi_seo_app/pages/groups_screen.dart';
import 'package:dotphi_seo_app/pages/todaysfollowup_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:whatsapp_share/whatsapp_share.dart';
import '../model/login_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../notification_services/notification_handler.dart';
import 'followup_screen.dart';
import 'leads_screen.dart';
import 'notification_screen.dart';

class PaidLeadsScreen extends StatefulWidget {
  final User user;
  final selectedProjectCode;
  final String projectUrl;

  PaidLeadsScreen({
    required this.user,
    required this.selectedProjectCode,
    required this.projectUrl,
  });

  @override
  _PaidLeadsScreenState createState() => _PaidLeadsScreenState();
}

class _PaidLeadsScreenState extends State<PaidLeadsScreen> {
  List<Map<String, dynamic>> apiData = [];
  // List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> sortedData = [];
  TextEditingController searchController = TextEditingController();
  bool showNoResults = false;
  String? _selectedProjectCode;
  bool isLoading = true;
  late bool isContacted;
  String? projectUrl;
  String? _projectUrl;
  String? selectedProjectCode;
  List<String> _projectUniqueCodes = [];
  bool isLoggedIn = false;
  bool isInternetConnected = true;
  int selectedStartMonth = 0;
  int selectedEndMonth = 0;
  int selectedStartDay = 0;
  int selectedEndDay = 0;
  int selectedYear = 0;
  bool isExpanded = false;
  DateTimeRange? selectedRange;
  int totalDataInRange = 0;
  Map<String, String> _projectData = {};
  int _tillDateLeadCount = 0;
  int totalLeadsCount = 0;
  int todaysLeadsCount = 0;
  int thisWeeksLeadsCount = 0;
  int thisMonthsLeadsCount = 0;
  int _todayLeadCount = 0;
  int _weeklyLeadCount = 0;
  int _monthlyLeadCount = 0;
  Map<String, String> _projectIds = {};
  String? selectedProjectId;
  bool showNotificationGif = false;
  String searchKeyword = '';
  List<dynamic> _leads = [];
  List<dynamic> filteredData = [];
  String? campaignId;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    _fetchDataAndUpdateScreen();
    _fetchProjectData().then((data) {
      setState(() {
        _projectData = data;
        _loadSelectedProjectCode();
        if (_projectData.length == 1) {
          _fetchProjectUrl(_projectData.keys.first);
        }
      });
    });
    fetchApiData().then((_) {
      filterDataByDateRange();
    });
    _fetchProjectUniqueCodes().then((codes) {
      setState(() {
        _projectUniqueCodes = codes;
        _loadSelectedProjectCode();
        _loadProjectUrl();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchProjectUniqueCodes();
    _fetchDataAndUpdateScreen();
  }

  Future<void> _fetchDataAndUpdateScreen() async {
    setState(() {
      isLoading = true;
    });
    _fetchProjectData().then((data) {
      setState(() {
        _projectData = data;
        print(_projectData);

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

   void didPopNext() {
    loadPaidLeads(campaignId!);
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

  String calculateTimeDifference(String entryDate) {
    try {
      // Parse the full DateTime from the entryDate
      DateTime entryDateTime = DateTime.parse(entryDate);

      // Get today's date without time (set time to midnight)
      DateTime now = DateTime.now();
      DateTime nowDateOnly = DateTime(now.year, now.month, now.day);

      // Get the lead's date without time (set time to midnight)
      DateTime entryDateOnly =
          DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);

      // Calculate the difference in days only (ignoring time)
      int differenceInDays = nowDateOnly.difference(entryDateOnly).inDays;

      // Ignore today's date in the output
      if (differenceInDays <= 0) {
        return 'Invalid date'; // Entry is today or in the future
      } else if (differenceInDays == 1) {
        return '1 day ago';
      } else if (differenceInDays < 7) {
        return '$differenceInDays days ago';
      } else if (differenceInDays < 30) {
        int weeks = (differenceInDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (differenceInDays < 365) {
        int months = (differenceInDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        int years = (differenceInDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } catch (e) {
      // Handle the case where entryDate is not in the correct format
      return 'Invalid date';
    }
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
      // print('Data');
      // print('BODY::::${response.body}');
      if (jsonData['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('loginResponse', response.body);
        prefs.setBool('isLoggedIn', true);
        final data = jsonData['data'] as List<dynamic>;
        final projectData = Map<String, String>();
        print('projectData');
        print(projectData);

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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('loginResponse', response.body);
        prefs.setBool('isLoggedIn', true);
        final data = jsonData['data'] as List<dynamic>;
        campaignId = data[0]['campaign_id'].toString();
        await loadPaidLeads(campaignId!);
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

  Future<void> loadPaidLeads(String campaignId) async {
    final url = Uri.parse('https://clients.dotphi.com/Api/login/paid_lead');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {'unique_id': campaignId},
    );

    if (response.statusCode == 200) {
      try {
        // Parse the response body as JSON
        final jsonData = json.decode(response.body);

        // Check if status is success
        if (jsonData['status'] == 'success') {
          // Ensure 'data' is actually a List before mapping over it
          if (jsonData['data'] is List) {
            final data = jsonData['data'] as List<dynamic>;

            // Sort leads by 'created_at' in descending order (latest first)
            data.sort((a, b) {
              try {
                // Extract only the 'date' portion from the 'created_at' string (first 10 characters, YYYY-MM-DD)
                String dateStringA = a['created_at'].substring(0, 10);
                String dateStringB = b['created_at'].substring(0, 10);

                // Parse the date strings into DateTime objects
                DateTime dateA = DateTime.parse(dateStringA);
                DateTime dateB = DateTime.parse(dateStringB);

                // Compare the dates in descending order (latest first)
                return dateB.compareTo(dateA);
              } catch (e) {
                print("Error parsing date: $e");
                return 0; // If parsing fails, don't change the order
              }
            });

            // Set the state to store the leads
            setState(() {
              _leads = data;
              totalLeadsCount = _leads.length;
              print(totalLeadsCount);
              todaysLeadsCount = countLeadsForToday(_leads);
              thisWeeksLeadsCount = countLeadsForCurrentWeek(_leads);
              thisMonthsLeadsCount = countLeadsByCurrentMonth(_leads);
            });

            print("Paid Leads Loaded:");
            print(_leads);

            // Check if there are any leads that require follow-up today
            checkFollowUpNotifications(_leads);

          } else {
            // If 'data' is not a list, print or handle this error case
            print("Data is not a list: ${jsonData['data']}");
          }
        } else {
          print("Failed to load paid leads: ${jsonData['message']}");
        }
      } catch (e) {
        print("Error parsing response: $e");
      }
    } else {
      print("Failed to load paid leads with status code: ${response.statusCode}");
    }
  }

  void checkFollowUpNotifications(List<dynamic> leads) {
    final today = DateTime.now();

    for (var lead in leads) {
      if (lead['followup'] != null) {
        DateTime? followUpDate;

        try {
          // Try parsing the date using 'dd-MM-yyyy' format
          followUpDate = DateFormat('dd-MM-yyyy').parse(lead['followup']);
        } catch (e) {
          try {
            // Fallback to 'yyyy-MM-dd' format if the first attempt fails
            followUpDate = DateFormat('yyyy-MM-dd').parse(lead['followup']);
          } catch (e) {
            print("Error parsing follow-up date for ${lead['full_name']}: $e");
            continue; // Skip this lead if both formats fail
          }
        }

        if (followUpDate != null && isSameDate(today, followUpDate)) {
          // Show in-app notification for leads with follow-up today
          showInAppNotification(
            title: 'Follow-up Reminder',
            message: 'Follow-up scheduled for today',
              projectUniqueCode:widget.selectedProjectCode,
              campaignId:campaignId!,
          );
        }
      }
    }
  }


  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int countLeadsForToday(List<dynamic> leads) {
    // Get today's date
    DateTime today = DateTime.now();

    return leads.where((lead) {
      // Parse the lead 'created_at' field into a DateTime object
      DateTime leadDate =
          DateTime.parse(lead['created_at']); // Use the existing date string

      // Compare the year, month, and day of the lead date with today's date
      return leadDate.year == today.year &&
          leadDate.month == today.month &&
          leadDate.day == today.day;
    }).length;
  }

  int countLeadsForCurrentWeek(List<dynamic> leads) {
    // Get today's date
    DateTime now = DateTime.now();

    // Calculate the start of the week (Monday)
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Calculate the end of the week (Sunday)
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    return leads.where((lead) {
      // Parse the lead 'created_at' field into a DateTime object
      DateTime leadDate =
          DateTime.parse(lead['created_at']); // Use the existing date string

      // Check if the lead date is within the current week
      return leadDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          leadDate.isBefore(endOfWeek.add(Duration(days: 1)));
    }).length;
  }

  int countLeadsByCurrentMonth(List<dynamic> leads) {
    // Get the current date, month, and year
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    return leads.where((lead) {
      // Parse the lead 'created_at' field into a DateTime object
      DateTime leadDate = DateTime.parse(lead['created_at']);

      // Compare the lead's year and month with the current year and month
      return leadDate.year == currentYear && leadDate.month == currentMonth;
    }).length;
  }

  Future<void> _loadProjectUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      projectUrl = prefs.getString('projectUrl');
    });
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

  void refreshApiScreen() {
    fetchApiData().then((_) {
      filterDataByDateRange();
    });
  }

  Future<void> fetchApiDataForSelectedProject() async {
    if (selectedProjectCode != null && selectedProjectCode!.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      // First API call
      final leadResponse = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/login/lead'),
        body: {'unique_id': selectedProjectCode},
      );

      if (leadResponse.statusCode == 200) {
        final leadResponseData = jsonDecode(leadResponse.body);
        final leadData =
            List<Map<String, dynamic>>.from(leadResponseData['data']);

        setState(() {
          apiData.addAll(leadData);
        });
      } else {
        print(
            'Lead API request failed with status code: ${leadResponse.statusCode}');
      }

      // Second API call
      final liveChatResponse = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/Login/livechat'),
        body: {'unique_id': selectedProjectCode},
      );

      if (liveChatResponse.statusCode == 200) {
        final liveChatResponseData = jsonDecode(liveChatResponse.body);
        final liveChatData =
            List<Map<String, dynamic>>.from(liveChatResponseData['data']);

        setState(() {
          apiData.addAll(liveChatData);
        });
      } else {
        print(
            'Live Chat API request failed with status code: ${liveChatResponse.statusCode}');
      }

      // Sort combined data by date (descending)
      setState(() {
        sortedData = List<Map<String, dynamic>>.from(apiData);
        sortedData.sort((a, b) {
          final dateA = DateTime.parse(a['added_date'] ?? a['created_date']);
          final dateB = DateTime.parse(b['added_date'] ?? b['created_date']);
          return dateB.compareTo(dateA); // Descending order
        });
        filterDataByDateRange(); // Call filter function after sorting
        isLoading = false;
      });
    }
  }

  Future<void> fetchApiData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProjectCode = prefs.getString('project_unique_code');
      _projectUrl = prefs.getString('projectUrl');
    });

    if (_selectedProjectCode != null && _selectedProjectCode!.isNotEmpty) {
      List<Map<String, dynamic>> combinedData = [];

      // First API call for 'lead'
      final leadResponse = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/login/lead'),
        body: {'unique_id': _selectedProjectCode},
      );

      if (leadResponse.statusCode == 200) {
        final leadResponseData = jsonDecode(leadResponse.body);
        print(
            'Lead Response Data: $leadResponseData'); // Print the lead response data
        List<Map<String, dynamic>> leadData =
            List<Map<String, dynamic>>.from(leadResponseData['data']);

        // Add a source and gif_path field to each item in the lead data
        for (var item in leadData) {
          item['source'] = 'lead'; // Mark as lead
          item['gif_path'] =
              'assets/images/email.gif'; // Set the GIF path for lead data
        }

        combinedData.addAll(leadData);
      } else {
        print(
            'Lead API request failed with status code: ${leadResponse.statusCode}');
      }

      // Second API call for 'livechat'
      final liveChatResponse = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/Login/livechat'),
        body: {'unique_id': _selectedProjectCode},
      );

      if (liveChatResponse.statusCode == 200) {
        final liveChatResponseData = jsonDecode(liveChatResponse.body);
        print(
            'Live Chat Response Data: $liveChatResponseData'); // Print the live chat response data
        List<Map<String, dynamic>> liveChatData =
            List<Map<String, dynamic>>.from(liveChatResponseData['data']);

        // Add a source and gif_path field to each item in the live chat data
        for (var item in liveChatData) {
          item['source'] = 'livechat'; // Mark as livechat
          item['gif_path'] =
              'assets/images/chatleads.gif'; // Set the GIF path for live chat data
        }

        combinedData.addAll(liveChatData);
        // Optionally print combined data before sorting
        print('Combined Data Before Sorting: $combinedData');
      } else {
        print(
            'Live Chat API request failed with status code: ${liveChatResponse.statusCode}');
      }

      // Sort combined data by date in descending order
      setState(() {
        apiData = combinedData;
        sortedData = List<Map<String, dynamic>>.from(apiData);
        sortedData.sort((a, b) {
          final dateA = DateTime.parse(a['added_date'] ?? a['created_date']);
          final dateB = DateTime.parse(b['added_date'] ?? b['created_date']);
          return dateB.compareTo(dateA); // Descending order
        });

        // Print sorted data
        print('Sorted Data: $sortedData');

        filterDataByDateRange(); // Apply filtering after sorting
        isLoading = false;
      });
    } else {
      setState(() {
        apiData = [];
        sortedData = [];
        selectedRange = DateTimeRange(
          start: DateTime.now().subtract(Duration(days: 7)),
          end: DateTime.now(),
        );
        isLoading = false;
      });
    }
  }

  void sortByDate() {
    sortedData.sort((a, b) {
      final dateA = DateTime.parse(a['added_date'] ?? a['created_date']);
      final dateB = DateTime.parse(b['added_date'] ?? b['created_date']);
      return dateB.compareTo(dateA); // Descending order
    });
    setState(() {
      filteredData = [];
      showNoResults = false;
    });
  }

  void navigateToKeywordDetailScreen(int index) async {
    // Fetch the relevant data based on the search state
    final data = searchController.text.isNotEmpty
        ? filteredData[index]
        : sortedData[index];

    // Clear the search controller
    searchController.clear();

    // Navigate to the DetailScreen with a custom transition
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return DetailScreen(
            data: data,
            user: widget.user,
            projectUrl: _projectUrl ?? '',
            selectedProjectCode: selectedProjectCode ?? '',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Define the scale transition
          const double beginScale = 0.0; // Start scale
          const double endScale = 1.0; // End scale
          const curve = Curves.easeInOut;

          // Create a Tween for scaling
          final scaleTween = Tween<double>(begin: beginScale, end: endScale)
              .chain(CurveTween(curve: curve));
          final scaleAnimation = animation.drive(scaleTween);

          // Define the fade transition
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: curve));
          final fadeAnimation = animation.drive(fadeTween);

          // Combine the animations
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
        transitionDuration:
            Duration(milliseconds: 600), // Duration of the transition
      ),
    );

    // Handle the result from the DetailScreen and update the data if necessary
    if (result != null) {
      setState(() {
        if (searchController.text.isNotEmpty) {
          filteredData[index] = result;
        } else {
          sortedData[index] = result;
        }
      });
    } else {
      setState(() {
        // Additional state updates if needed
      });
    }

    // Refresh the API screen after returning from the DetailScreen
    refreshApiScreen();
  }

  void search(String keyword) {
    setState(() {
      searchKeyword = keyword.toLowerCase();

      // Filter leads based on the search keyword
      filteredData = _leads.where((lead) {
        final name = (lead['full_name'] ?? '').toLowerCase();
        final email = (lead['email'] ?? '').toLowerCase();
        return name.contains(searchKeyword) || email.contains(searchKeyword);
      }).toList(); // This will keep it as List<dynamic>

      // Update no results state
      showNoResults = filteredData.isEmpty;
    });
  }

  Future<void> fetchApiDataForProject(String projectCode) async {
    setState(() {
      isLoading = true;
    });

    final Uri leadUrl = Uri.parse('https://clients.dotphi.com/Api/login/lead');
    final Uri livechatUrl =
        Uri.parse('https://clients.dotphi.com/Api/Login/livechat');

    // Fetch lead data
    final leadResponse = await http.post(
      leadUrl,
      body: {'unique_id': projectCode},
    );

    // Fetch live chat data
    final livechatResponse = await http.post(
      livechatUrl,
      body: {'unique_id': projectCode},
    );

    List<Map<String, dynamic>> combinedData = [];

    // Process the lead response
    if (leadResponse.statusCode == 200) {
      final leadData = jsonDecode(leadResponse.body);
      print('Lead Data: $leadData'); // Print the received lead data
      final leadList = List<Map<String, dynamic>>.from(leadData['data']);
      combinedData.addAll(leadList);
    } else {
      print(
          'Lead API request failed with status code: ${leadResponse.statusCode}');
    }

    // Process the livechat response
    if (livechatResponse.statusCode == 200) {
      final livechatData = jsonDecode(livechatResponse.body);
      print(
          'Live Chat Data: $livechatData'); // Print the received live chat data
      final livechatList =
          List<Map<String, dynamic>>.from(livechatData['data']);
      combinedData.addAll(livechatList);
    } else {
      print(
          'Livechat API request failed with status code: ${livechatResponse.statusCode}');
    }

    // Combine and sort the data
    setState(() {
      apiData = combinedData;
      sortedData = List<Map<String, dynamic>>.from(apiData);

      // Determine which date field to sort by
      if (combinedData.isNotEmpty) {
        final hasAddedDate =
            combinedData.every((item) => item.containsKey('added_date'));
        final hasCreatedDate =
            combinedData.every((item) => item.containsKey('created_date'));

        if (hasAddedDate) {
          sortedData.sort((a, b) {
            final dateA = DateTime.parse(a['added_date']);
            final dateB = DateTime.parse(b['added_date']);
            return dateB.compareTo(dateA); // Descending order
          });
        } else if (hasCreatedDate) {
          sortedData.sort((a, b) {
            final dateA = DateTime.parse(a['created_date']);
            final dateB = DateTime.parse(b['created_date']);
            return dateB.compareTo(dateA); // Descending order
          });
        }
      }

      filterDataByDateRange(); // Apply date range filter

      isLoading = false;
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      showNoResults = false;
      selectedStartMonth = 0;
      selectedEndMonth = 0;
      selectedStartDay = 0;
      selectedEndDay = 0;
      selectedYear = 0;
      selectedRange = null; // Clear the selected date range
    });
    filterDataByDateRange();
  }

  Future<void> _fetchProjectUrl(String projectCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginResponse = prefs.getString('loginResponse') ?? '';
    final jsonData = json.decode(loginResponse);
    // print('Project Data');
    // print(jsonData);
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
                    await fetchApiDataForSelectedProject();
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

  void filterDataByDateRange() {
    if (selectedRange == null) {
      setState(() {
        filteredData = sortedData;
        showNoResults = false;
        totalDataInRange = sortedData.length;
      });
    } else {
      final start = DateTime(
        selectedRange!.start.year,
        selectedRange!.start.month,
        selectedRange!.start.day,
      );
      final end = DateTime(
        selectedRange!.end.year,
        selectedRange!.end.month,
        selectedRange!.end.day,
      ).add(Duration(days: 1)); // Add 1 day to include the end date

      setState(() {
        filteredData = sortedData.where((data) {
          final dateField = data.containsKey('added_date')
              ? 'added_date'
              : 'created_date'; // Determine which date field to use

          final date = DateTime.parse(data[dateField]);

          return date.isAfter(start) && date.isBefore(end);
        }).toList();
        showNoResults = filteredData.isEmpty;
        totalDataInRange = filteredData
            .length; // Update totalDataInRange to match filtered data count
      });
    }
  }

  void showCalendarPicker() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors
                  .blue.shade900, // Set the primary color to blue.shade900
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        selectedRange = pickedRange;
      });
      filterDataByDateRange();
    }
  }

  Future<void> launchDialer(String phoneNumber) async {
    final Uri dialUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    // Check if the device can launch the dialer
    if (await canLaunchUrl(dialUri)) {
      await launchUrl(dialUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  String formatDate(String dateTimeString) {
    DateTime parsedDate = DateTime.parse(dateTimeString);
    // Format the date as 'yyyy/MM/dd'
    String formattedDate = DateFormat('yyyy/MM/dd').format(parsedDate);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return fetchApiData();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar:AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 50,
          toolbarOpacity: 0.7,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(25),
              bottomLeft: Radius.circular(25),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Image.asset(
              'assets/images/advertisement.png',
              width: 30,  // Adjust width and height as needed
              height: 30,
            ),
          ),
          title: Text(
            'Paid-Leads',
            style: TextStyle(
              fontSize: 20,  // Reduced font size to fit better
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
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
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/notification1.gif',
                      width: 30,  // Adjusted width and height for better fit
                      height: 30,
                    ),
                    // Uncomment and adjust the badge if needed
                    // Positioned(
                    //   right: 0,
                    //   top: 0,
                    //   child: Container(
                    //     padding: EdgeInsets.all(2),
                    //     decoration: BoxDecoration(
                    //       color: Colors.red,
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     constraints: BoxConstraints(
                    //       minWidth: 16,
                    //       minHeight: 16,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),


        body: Stack(
          children: [
            Container(
              color: Colors.white,
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/images/bg.jpg',
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                ),
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     // Navigate to the notification history screen
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => NotificationHistoryScreen(
            //           user: widget.user,
            //           projectUrl: widget.projectUrl,
            //           selectedProjectCode: widget.selectedProjectCode,
            //         ),),);
            //   },
            //   child: Stack(
            //     children: [
            //       Image.asset(
            //         'assets/images/notification1.gif',
            //         width: 40, height: 40,
            //       ),
            //       Positioned(
            //         right: 0,
            //         top: 0,
            //         child: Container(
            //           padding: EdgeInsets.all(2),
            //           decoration: BoxDecoration(
            //             color: Colors.red,
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           constraints: BoxConstraints(
            //             minWidth: 16,
            //             minHeight: 16,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),),
            Column(
              children: [

                SizedBox(height: 10),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              search(
                                  value); // Call the search function on text change
                            },
                            style: TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Search paid-leads',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            clearSearch();
                          },
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/images/calendar.gif',
                            scale: 20,
                          ),
                          onPressed: showCalendarPicker,
                        ),
                      ]),
                    ),
                  ),
                ),
                selectedRange != null
                    ? Text(
                        'Leads from:  ${DateFormat('dd-MM-yyyy').format(selectedRange!.start)}  to  ${DateFormat('dd-MM-yyyy').format(selectedRange!.end)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    : Container(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CircularDashboardCard(
                            title: 'Total Till Date',
                            count: isLoading
                                ? SpinKitCircle(
                                    color: Colors.white,
                                    size: 20.0,
                                  )
                                : totalLeadsCount,
                            color: Colors.blue,
                          ),
                          CircularDashboardCard(
                            title: 'Today',
                            count: isLoading
                                ? SpinKitCircle(
                                    color: Colors.white,
                                    size: 20.0,
                                  )
                                : todaysLeadsCount,
                            color: Colors.green,
                          ),
                          CircularDashboardCard(
                            title: 'This week',
                            count: isLoading
                                ? SpinKitCircle(
                                    color: Colors.white,
                                    size: 20.0,
                                  )
                                : thisWeeksLeadsCount,
                            color: Colors.orange,
                          ),
                          CircularDashboardCard(
                            title: 'This month',
                            count: isLoading
                                ? SpinKitCircle(
                                    color: Colors.white,
                                    size: 20.0,
                                  )
                                : thisMonthsLeadsCount,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      CustomTabBar(
                        tabs: ['All Leads','Follow-ups','Groups'],
                        onTabSelected: (index) {
                          if (index == 0) {
                            // Stay on the same page or do something specific for "All Leads"
                          }else if(index == 1){
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context)=>FollowupScreen(
                                    projectUniqueCode:selectedProjectCode,
                                    campaignId:campaignId
                                )));
                          }
                          else {
                            // Navigate to Groups page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupsScreen(
                                        onGroupUpdated: () {},
                                        group: {},
                                        projectCode: widget.selectedProjectCode, uniqueId: campaignId!,

                                      )),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: isLoading
                        ? Container(
                            alignment: Alignment.center,
                            child: Column(
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
                            ),
                          )
                        : _leads.isEmpty
                            ? Container(
                                alignment: Alignment.center,
                                child: Image.asset(
                                  'assets/images/nodata.png',
                                  height: 150,
                                  width: 150,
                                ),
                              )
                            : ListView.builder(
                                itemCount: _leads.length,
                                itemBuilder: (context, index) {
                                  final lead = _leads[index];
                                  String phoneNumber =
                                      lead['phone_number'] ?? 'No phone';
                                  String formattedNumber =
                                      phoneNumber.replaceAll('p:', '');
                                  return Container(
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
                                          if (lead['platform'] == 'Google Ads')
                                            Image.asset(
                                              'assets/images/adwords.png', // Path to your PNG image for Google Ads
                                              height: 30.0,
                                              width: 30.0,
                                            )
                                          else if (lead['platform'] == 'ig')
                                            Image.asset(
                                              'assets/images/instagram.png', // Path to your PNG image for Instagram
                                              height: 30.0,
                                              width: 30.0,
                                            )
                                          else if (lead['platform'] == 'Website')
                                              Image.asset(
                                                'assets/images/web-search.png', // Path to your PNG image for Instagram
                                                height: 35.0,
                                                width: 35.0,
                                              )
                                          else
                                            Icon(
                                              lead['platform'] == 'fb'
                                                  ? FontAwesomeIcons.facebook
                                                  : Icons.help_outline, // Default icon if not recognized
                                              size: 35.0,
                                              color: lead['platform'] == 'fb'
                                                  ? Colors.blue.shade900
                                                  : Colors.grey, // Default color
                                            ),
                                      SizedBox(
                                            width: 5,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        lead['full_name'] ??
                                                            'Unknown Name',
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontWeight:
                                                              lead['contact'] ==
                                                                      'uncontacted'
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                      lead['phone_number']
                                                              .replaceAll(
                                                                  RegExp(
                                                                      r'[^0-9]'),
                                                                  '') ??
                                                          'No phone',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 14,
                                                        fontWeight: lead[
                                                                    'contact'] ==
                                                                'uncontacted'
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                calculateTimeDifference(lead[
                                                    'created_at'
                                                        .split(' ')[0]]),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  // fontStyle: FontStyle.italic,
                                                  fontFamily: 'Poppins',
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              SizedBox(height: 10,),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  SizedBox(
                                                    width: 4,
                                                  ),
                                                  GestureDetector(
                                                    child: Image.asset(
                                                      'assets/images/user_info.png',
                                                      width: 30.0, // Set the width
                                                      height: 30.0, // Set the height
                                                      fit: BoxFit.cover,
                                                    ),
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => LeadDetailsScreen(
                                                            lead: lead,
                                                            user: widget.user,
                                                            projectUrl: _projectUrl ?? '',
                                                            selectedProjectCode: selectedProjectCode ?? '',
                                                          ),
                                                        ),
                                                      ).then((_) {
                                                        // Refresh data or update UI after returning from LeadDetailsScreen
                                                      loadPaidLeads(campaignId!);// Call your method to refresh the data or UI
                                                      });
                                                    },
                                                  ),

                                                  SizedBox(width: 30),
                                                  GestureDetector(
                                                    onTap: () {
                                                      launchDialer(lead[
                                                      'phone_number']);
                                                    },
                                                    child: Image.asset(
                                                      'assets/images/telephone.png',
                                                      width: 30,
                                                      height: 30,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // onTap: () {
                                      //   navigateToKeywordDetailScreen(
                                      //       index);
                                      // },
                                    ),
                                  );
                                }))
              ],
            )
          ],
        ),
      ),
    );
  }
}

class LeadDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> lead;
  final User user;
  final String projectUrl;
  final selectedProjectCode;

  LeadDetailsScreen({
    required this.user,
    required this.projectUrl,
    this.selectedProjectCode,
    required this.lead,
  });

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen>
    with WidgetsBindingObserver {
  String contactedStatus = '';
  String changedStatus = '';
  List<Map<String, dynamic>> _groups = [];
  List<String> groups = [];
  List<dynamic> _userGroupNames = [];
  DateTime? _selectedFollowUpDate;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _fileName;
  String? _filePath;
  int _contactedCount = 0;
  int _uncontactedCount = 0;
  bool isVisible = true;
  bool _isLoading = true;
  String? _selectedOption;
  final List<String> _dropdownOptions = [
    'Interested',
    'Incomplete',
    'In Progress',
    'Not Answered',
    'Converted',
    'Visited',
    'Rejected',
    'Demo Done'
  ];
  Map<String, IconData> optionIcons = {
    'Interested': FontAwesomeIcons.star,
    'Incomplete': FontAwesomeIcons.hourglassHalf,
    'In Progress': FontAwesomeIcons.cogs,
    'Not Answered': FontAwesomeIcons.questionCircle,
    'Converted': FontAwesomeIcons.checkCircle,
    'Visited': FontAwesomeIcons.mapMarkerAlt,
    'Rejected': FontAwesomeIcons.timesCircle,
    'Demo Done': FontAwesomeIcons.clipboardCheck,
  };

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getContactStatus(widget.lead['campaign_id'], widget.lead['paid_id']);
    _loadGroups(widget.user.project_unique_code);
    print(widget.user.project_unique_code);
    print(widget.lead['paid_id']);
    _loadFollowUpDateForUser(widget.lead['paid_id']);
    fetchUserGroups(widget.user.project_unique_code, widget.lead['paid_id'],'paid');
    // _loadUserGroups();
    // loadFollowUpDate(widget.lead['paid_id']);
    // _loadCounts();
    _loadFollowUpDate(widget.lead['paid_id']);
  }

  void didPopNext() {
    _loadGroups(widget.user.project_unique_code);
    _loadFollowUpDateForUser(widget.lead['paid_id']);
    _loadFollowUpDate(widget.lead['paid_id']);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Future<void> _loadContactedStatus() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final isContacted = prefs.getBool('contacted_${widget.data['name']}') ?? false;
  //   setState(() {
  //     _isContacted = isContacted;
  //   });
  // }
  void _toggleContainer() {
    setState(() {
      isVisible =
          !isVisible; // Toggle the visibility: true -> false, false -> true
    });
  }

  Future<void> _updateContactStatus(String unique_id, String id) async {
    // Retrieve the current status from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use a unique key to store the status
    String contactKey = 'contact_status_${unique_id}_$id';
    String currentStatus = prefs.getString(contactKey) ?? 'uncontacted';

    // Determine the new status
    String newStatus =
        (currentStatus == 'uncontacted') ? 'contacted' : 'uncontacted';

    // Prepare the body data
    Map<String, String> body = {
      'unique_id': unique_id,
      'seo_id': id,
      'contact': newStatus,
    };

    // API call to the paid_lead endpoint
    final response = await http.post(
      Uri.parse(
          'https://clients.dotphi.com/Api/login/paid_lead'), // Updated API endpoint
      body: body,
    );

    // Handle response
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // If the API response indicates success, update SharedPreferences
      if (responseData['status'] == 'success') {
        await prefs.setString(contactKey, newStatus);
        print(
            'Contact status updated to $newStatus for ${widget.lead['full_name']} in project $unique_id');
      } else {
        print(
            'Failed to update contact status on server: ${responseData['message']}');
      }
    } else {
      print(
          'Failed to update contact status. Response code: ${response.statusCode}');
    }
  }

  Future<void> _getContactStatus(String unique_id, String seoId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use the same unique key to retrieve the status
    String contactKey = 'contact_status_${unique_id}_$seoId';
    String storedStatus = prefs.getString(contactKey) ?? 'uncontacted';

    setState(() {
      contactedStatus =
          storedStatus; // Update the state to show the value in the UI
    });
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contactedCount = prefs.getInt('contacted_count') ?? 0;
      // Removed uncontactedCount as requested
    });
  }

  void _uncontactedBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(15)
                ),
                child: ListTile(
                  leading: Icon(Icons.perm_contact_cal_sharp,
                      color: Colors.white),
                  title: Text(
                    'Add to Phonebook',
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                  ),
                  onTap: () {
                    // Handle "Add to Phonebook" action
                    _addToContacts();
                    Navigator.pop(context); // Close the bottom sheet
                  },
                ),
              ),
              SizedBox(height: 10,),
              Container(
                decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: ListTile(
                  leading: Icon(Icons.check, color: Colors.white),
                  title: Text(
                    widget.lead['contact'] == 'uncontacted'
                        ? 'Mark as Contacted'
                        : 'Mark as Uncontacted',
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                  ),
                  onTap: () {
                    // Handle "Mark as Contacted" action
                    _toggleContainer();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Status will be updated to ${widget.lead['contact'] == 'uncontacted' ? 'contacted' : 'uncontacted'}",style: TextStyle(fontFamily: 'Poppinsg'),),
                      backgroundColor: Colors.blue.shade900,
                    ));
                    _updateContactStatus(
                        widget.lead['campaign_id'], widget.lead['paid_id']);
                    setState(() {});

                    Navigator.pop(context); // Close the bottom sheet
                  },
                ),
              ),
              SizedBox(height: 20,)
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadGroups(String projectUniqueCode) async {
    final url = Uri.parse('https://clients.dotphi.com/Api/login/get_groups');

    try {
      // Make a POST request with project_unique_code as a parameter
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'project_unique_code': projectUniqueCode,
        },
      );

      print('API Response: ${response.body}'); // Debug: print full response

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Check if the response has the 'groups' key
        if (jsonResponse.containsKey('groups')) {
          final groupsList = jsonResponse['groups'];
          if (groupsList is List<dynamic>) {
            setState(() {
              _groups = List<Map<String, dynamic>>.from(groupsList);
              _isLoading = false;
            });
          } else {
            print('Error: "groups" is not a list');
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          print('Error: Key "groups" not found in response');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('Failed to fetch groups. Status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching groups: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchUserGroups(String projectUniqueCode, String userId, String type) async {
    print(projectUniqueCode);
    print(userId);
    print(type);

    try {
      // Define the request body for x-www-form-urlencoded
      Map<String, String> body = {
        'project_unique_code': projectUniqueCode,
        'user_id': userId,
        'type': type,
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/login/get_groups_for_user'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        print('Response body: ${response.body}'); // Log the full response body
        final responseData = jsonDecode(response.body);

        // Check if the response indicates success and contains group_names
        if (responseData['status'] == 'success' && responseData['group_names'] is List) {
          // Parse and store the group names in the variable
          groups = List<String>.from(responseData['group_names']); // Change to List<String> for group names
          print('Fetched group names stored in groups: $groups');
        } else {
          print('Error fetching groups: ${responseData['message'] ?? 'No message provided'}');
          groups = []; // Clear the list if there's an error in the response
        }
      } else {
        print('Failed to fetch groups. Status code: ${response.statusCode}');
        groups = []; // Clear the list if the status code is not 200
      }
    } catch (e) {
      // Handle any errors during the request
      print('An error occurred while fetching groups: $e');
      groups = []; // Clear the list if there's an exception
    }
  }


  void _groupsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                // color: Colors.blue.shade900,
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupsScreen(
                                        onGroupUpdated: _onGroupUpdated,
                                        group: {},
                                        projectCode:
                                            widget.user.project_unique_code, uniqueId: widget.lead['campaign_id'],

                                      )));
                          _onGroupUpdated();
                        },
                        child: Text(
                          "Manage groups",
                          style: TextStyle(color: Colors.blue.shade900,fontFamily:'Poppins',fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                          onTap: () async {
                            Navigator.pop(
                                context); // Close the OptionsModalSheet
                            await Navigator.push(
                              context,
                                MaterialPageRoute(
                                  builder: (context) => CreateGroupPage(
                                    projectUniqueCode: widget.user.project_unique_code,
                                    onGroupCreated: () async {
                                      print("Starting to load groups...");  // Debug message
                                      await _loadGroups(widget.user.project_unique_code);

                                      setState(() {
                                        print("Groups loaded, updating UI...");  // Debug message
                                      });

                                      print("Attempting to open bottom sheet...");  // Debug message
                                      _groupsBottomSheet(context);  // Open the bottom sheet immediately
                                    },
                                  ),
                                )



                            );
                            // Automatically show GroupsModalSheet after CreateGroupPage is closed
                          },
                          child: Text(
                            "Create New",
                            style: TextStyle(color: Colors.blue.shade900,fontFamily:'Poppins',fontWeight: FontWeight.bold),
                          ))
                    ],
                  ),
                ),
              ),
              _groups.isEmpty
                  ? Center(child: CircularProgressIndicator()):
              Expanded(
                child: ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return GestureDetector(
                      onTap: () {
                        _addUserToGroup(group);
                        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Saved to ${ group['name']}")));
                        Navigator.pop(context);
                      },
                      child: ListTile(
                        leading: Image.asset('assets/images/group.png',
                          height:25 ,width: 25,),
                        title: Text(
                          group['group_name'],
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _optionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 15.0),
                    child: Center(
                      child: Text(
                        "Options",
                        style: TextStyle(
                            color: Colors.blue.shade900,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                      // color: Colors.blue.shade900,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10))),
                ),
                SizedBox(height: 10,),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: ListTile(
                    leading: Icon(Icons.groups, color: Colors.white),
                    title: Text(
                      'Add to groups',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      _loadGroups(widget.user.project_unique_code);
                      Navigator.pop(context);
                      Future.delayed(Duration(milliseconds: 100), () {
                        _groupsBottomSheet(context); // Show the groups modal sheet
                      });
                    },
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: ListTile(
                    leading: Icon(Icons.close, color: Colors.white),
                    title: Text(
                      widget.lead['contact'] == 'uncontacted'
                          ? 'Mark as Contacted'
                          : 'Mark as Uncontacted',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      _toggleContainer();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Status will be updated to ${widget.lead['contact'] == 'uncontacted' ? 'contacted' : 'uncontacted'}"),
                        backgroundColor: Colors.blue.shade900,
                      ));
                      _updateContactStatus(
                          widget.lead['campaign_id'], widget.lead['full_name']);
                      Navigator.pop(context); // Close the bottom sheet
                    },
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: ListTile(
                    leading: Icon(Icons.perm_contact_cal_sharp,
                        color: Colors.white),
                    title: Text(
                      'Add to phonebook',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      // Handle "Mark as Contacted" action
                      _addToContacts();
                      Navigator.pop(context); // Close the bottom sheet
                    },
                  ),
                ),
                SizedBox(height: 20,),

              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToContacts() async {
    // Request permission to access contacts
    if (await Permission.contacts.request().isGranted) {
      final contact = Contact(
        givenName: widget.lead['full_name'],
        phones: [Item(label: 'mobile', value: widget.lead['phone_number'])],
        emails: [Item(label: 'work', value: widget.lead['email'])],
      );

      await ContactsService.addContact(contact);
      Navigator.pop(context); // Close the bottom sheet after adding the contact
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.blue.shade900,
          content: Text(
            "Contact Saved",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )));
    } else {
      // Handle permission denial
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contacts permission denied')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('groups') ?? '[]';
    final List<dynamic> groupsJson = jsonDecode(groupsString);
    return groupsJson.cast<Map<String, dynamic>>();
  }

  Future<void> saveGroups(List<Map<String, dynamic>> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = jsonEncode(groups);
    await prefs.setString('groups', groupsString);
  }

  Future<void> _loadUserGroups() async {
    final prefs = await SharedPreferences.getInstance();
    // Load updated groups data from SharedPreferences
    final groupsString = prefs.getString('groups') ?? '[]';
    print("Printed group names: $groupsString");
    // Convert the JSON string into a list of maps
    final List<Map<String, dynamic>> allGroups =
        List<Map<String, dynamic>>.from(jsonDecode(groupsString));
    // Extract the user name
    final userName = widget.lead[
        'full_name']; // Ensure 'name' is the correct identifier for the user

    // Filter groups where the user is present
    final List<String> userGroupNames = allGroups
        .where((group) =>
            group['users'] != null &&
            (group['users'] as List<dynamic>)
                .any((user) => user['name'] == userName))
        .map((group) => group['name'] as String)
        .toList();

    // Print the filtered group names
    print("Filtered group names: $userGroupNames");
    // Update the state with the extracted group names
    setState(() {
      _userGroupNames = userGroupNames;
    });
    // Ensure _loadGroups is called to refresh the list of groups if needed
    // await _loadGroups();
  }

  void _onGroupUpdated() {
    _loadUserGroups();
    // Reload the user groups when a group is updated
    // _loadFollowUpDate(widget.lead['full_name']);
    // _loadGroups();
    _loadUserGroups();
  }

  Future<void> _addUserToGroup(Map<String, dynamic> group) async {
    final groupIndex = _groups.indexWhere((g) => g['id'] == group['id']);

    if (groupIndex != -1) {
      final groupId = group['group_id'].toString();
      final userId = widget.lead['paid_id'].toString();
      final projectUniqueCode = widget.user.project_unique_code;

      Map<String, String> body = {
        'group_id': groupId,
        'paid_id': userId,
        'project_unique_code': projectUniqueCode,
      };

      try {
        // Send request to the API
        final response = await http.post(
          Uri.parse('https://clients.dotphi.com/Api/login/add_user_to_group'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        );

        // Log the response for debugging
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${widget.lead['full_name']} added to ${group['group_name']} successfully'),
              backgroundColor: Colors.blue.shade900,
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Failed to add ${widget.lead['full_name']} to group: ${responseData['message']}'),
              backgroundColor: Colors.red.shade900,
            ));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Failed to add ${widget.lead['full_name']} to group. Status code: ${response.statusCode}'),
              backgroundColor: Colors.red.shade900));
        }
      } catch (e) {
        // Handle any error during the request
        print('Error adding user to group: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red.shade900));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Group does not exist'),
          backgroundColor: Colors.blue.shade900));
    }
  }

  Future<void> _postFollowUpDate(String uniqueId, String seoId, DateTime followupDate) async {
    final url = 'https://clients.dotphi.com/Api/login/paid_lead';

    // Format the date as 'dd-MM-yyyy'
    String formattedDate = DateFormat('dd-MM-yyyy').format(followupDate);

    // Construct the x-www-form-urlencoded request body
    String requestBody = 'unique_id=${Uri.encodeQueryComponent(uniqueId)}'
        '&seo_id=${Uri.encodeQueryComponent(seoId)}'
        '&followup=${Uri.encodeQueryComponent(formattedDate)}';

    print('Request body: $requestBody'); // Log the request body
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: requestBody, // Pass the encoded body
    );

    print(
        'Response status code: ${response.statusCode}'); // Log the response status code
    print('Response body: ${response.body}'); // Log the response body

    if (response.statusCode == 200) {
      // Handle success
      print('Follow-up date posted successfully: ${response.body}');

      // Save follow-up date in SharedPreferences based on seoId
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('followup_date_$seoId', formattedDate);
    } else {
      // Handle error
      print('Failed to post follow-up date: ${response.body}');
    }
  }

  String _formatFollowUpDate(String followupDate) {
    try {
      // Parse the follow-up date from 'dd-MM-yyyy' to a DateTime object
      DateTime parsedDate = DateFormat('dd-MM-yyyy').parse(followupDate);

      // Format the DateTime object to 'dd/MM/yyyy'
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      // In case of error (e.g., invalid format), return an appropriate message
      return 'Invalid date format';
    }
  }

  void _followUpBottomSheet(
      BuildContext context,
      String username,
      String uniqueId,
      String seoId,
      Function(DateTime?) onDateSelected,
      Future<void> Function(String, String, DateTime) postFollowUpDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            DateTime? _selectedDate;

            // Function to save follow-up date for a user
            Future<void> _saveFollowUpDateForUser(
                String username, DateTime date) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                  'follow_up_date_$username', date.toIso8601String());
            }

            Widget _buildListTile(String title, DateTime date) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text(
                    title,
                    style: TextStyle(
                        color:Colors.white,fontFamily: 'Poppins'
                    ),
                  ),
                  tileColor: _selectedDate == date ? Colors.blue.shade900 : null,
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    Navigator.pop(context);
                    _saveFollowUpDateForUser(
                        username, _selectedDate!); // Save selected date
                    onDateSelected(_selectedDate); // Callback to update the date
                    postFollowUpDate(uniqueId, seoId,
                        _selectedDate!); // Call the passed post function
                  },
                ),
              );
            }

            void _showCustomDateSelector() async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );

              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                });
                Navigator.pop(context);
                _saveFollowUpDateForUser(
                    username, _selectedDate!); // Save selected date
                onDateSelected(_selectedDate); // Callback to update the date
                postFollowUpDate(uniqueId, seoId,
                    _selectedDate!); // Call the passed post function
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    decoration: BoxDecoration(
                      // color: Colors.blue.shade900,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 15.0),
                      child: Center(
                        child: Text(
                          "Schedule follow-up",
                          style: TextStyle(color: Colors.blue.shade900,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            _buildListTile('Today', DateTime.now()),
                            SizedBox(height: 10,),
                            _buildListTile('Tomorrow',
                                DateTime.now().add(Duration(days: 1))),
                            SizedBox(height: 10,),

                            _buildListTile('3 days from now',
                                DateTime.now().add(Duration(days: 3))),
                            SizedBox(height: 10,),

                            _buildListTile('1 week from now',
                                DateTime.now().add(Duration(days: 7))),
                            SizedBox(height: 10,),

                            _buildListTile('1 month from now',
                                DateTime.now().add(Duration(days: 30))),
                            SizedBox(height: 10,),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius:BorderRadius.circular(15)
                              ),
                              child: ListTile(
                                title: Text(
                                  'Select custom date and time',
                                  style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                                ),
                                onTap:
                                    _showCustomDateSelector, // Handle custom date selection
                              ),
                            ),
                            SizedBox(height: 10,),

                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveFollowUpDateForUser(String username, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('follow_up_date_$username', date.toIso8601String());
  }

  Future<void> _loadFollowUpDateForUser(String seoId) async {
    final prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('follow_up_date_$seoId');
    if (dateString != null) {
      setState(() {
        _selectedFollowUpDate = DateTime.parse(dateString);
      });
    } else {
      setState(() {
        _selectedFollowUpDate = null; // No date selected
      });
    }
  }

  Future<void> _loadFollowUpDate(String seoId) async {
    final prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('follow_up_date_$seoId');

    // Wrap the state update in a microtask to ensure the UI rebuilds immediately.
    Future.microtask(() {
      setState(() {
        if (dateString != null) {
          _selectedFollowUpDate = DateTime.parse(dateString);
        } else {
          _selectedFollowUpDate = null; // No date found
        }
      });
    });
  }

  void _showSendOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Send Message',style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500,fontSize: 20,color: Colors.blue.shade900))),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Icon(
                    Icons.textsms_outlined,
                    color: Colors.lightBlueAccent,
                  ),
                  title: Text(
                    'Send via Text',
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                  ),
                  onTap: () {
                    String message = _messageController.text;
                    _sendSMS(
                        context,
                        message,
                        widget.lead['phone_number']
                            .replaceFirst('p:', '')
                            .replaceFirst('+91', ''));
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(height: 10,),
              Container(
                decoration: BoxDecoration(color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Icon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                  ),
                  title: Text(
                    'Send via Whatsapp',
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                  ),
                  onTap: () {
                    String message = _messageController.text;
                    _sendWhatsAppMessage(
                        context,
                        message,
                        widget.lead['phone_number']
                            .replaceFirst('p:', '')
                            .replaceFirst('+91', ''));
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(height: 10,),
              Container(
                decoration: BoxDecoration(color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Icon(
                    Icons.email_outlined,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Send via Email',
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                  ),
                  onTap: () {
                    String title = _titleController.text;
                    String message = _messageController.text;
                    _sendEmail(context, title, message, widget.lead['email']);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        // Extract the file name
        final fileName = result.files.single.name;
        final filePath = result.files.single.path;

        setState(() {
          _fileName = fileName;
          _filePath = filePath;
        });

        // Show a snack bar with the file name
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: $_fileName'),
          ),
        );
      } else {
        // Show a snack bar if no file is selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No file selected.'),
          ),
        );
      }
    } catch (e) {
      // Show a snack bar if there is an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
        ),
      );
    }
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

  Future<void> _sendEmail(BuildContext context, String subject, String message,
      String recipient) async {
    if (_filePath != null && _filePath!.isNotEmpty) {
      // Attach the file and send email
      try {
        await Share.shareXFiles(
          [XFile(_filePath!)], // File path as a list of XFile
          subject: subject,
          text: message,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File and message shared via Email!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to share file and message via Email: $e')),
        );
        print('Error: $e');
      }
    } else {
      // If no file is selected, send only the email with subject and message
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: widget.lead['email'] ?? 'No email',
        query: Uri.encodeFull('subject=$subject&body=$message'),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent through Email!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open email client.')),
        );
        throw 'Could not launch email client';
      }
    }
  }

  String formatDate(String dateTimeString) {
    DateTime parsedDate = DateTime.parse(dateTimeString);
    // Use DateFormat to format the date as 'yyyy-MM-dd' or any other format you prefer
    String formattedDate = DateFormat('MM/dd/yyyy').format(parsedDate);
    return formattedDate;
  }

  Widget dropdownWithArrow({
    required String? selectedOption,
    required List<String> options,
    required ValueChanged<String?> onOptionSelected,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedOption,
        isExpanded: true,
        hint: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedOption ?? 'Please select status',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
        style: TextStyle(color: Colors.black),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onOptionSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Container(
            color: Colors.white,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/bg.jpg',
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            elevation: 5,
            toolbarHeight: 50,
            toolbarOpacity: 0.7,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(25),
                bottomLeft: Radius.circular(25),
              ),
            ),
            title:  FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Paid-Leads',
                style: TextStyle(
                  fontSize: 24, fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold, color: Colors.blue[900],
                ),
              ),
            )
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            " ${widget.lead['full_name'] ?? 'Unknown'}",
                            style: const TextStyle(
                                fontSize: 20,
                                fontFamily:
                                    'Poppins', // Reference the family name here
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              _optionsBottomSheet(context);
                            },
                            child: Text(
                              "Options",
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ))
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    GestureDetector(
                        onTap: () {
                          _uncontactedBottomSheet(context);
                        },
                        child: isVisible
                            ? Container(
                                height: 40,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.blue.shade900,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          widget.lead['contact'].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_downward_sharp,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  ),
                                ))
                            : Container()),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        _groupsBottomSheet(context);
                      },
                      child: Container(
                        height: 50,
                        width: 360,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.groups),
                            const SizedBox(width: 8.0),
                            Text(
                              'GROUP:',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 10),
                            groups.isNotEmpty
                                ? Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: groups.map((groupName) { // Use groupName directly as it's a string
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade900,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          groupName, // Directly use the group name string
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            )
                                : Container(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        String username = widget.lead['name'] ?? '';
                        String uniqueId = widget.lead['campaign_id'] ?? '';
                        String seoId = widget.lead['paid_id'] ?? '';

                        // Call _followUpBottomSheet with the necessary parameters
                        _followUpBottomSheet(
                          context,
                          username,
                          uniqueId,
                          seoId,
                          (selectedDate) {
                            setState(() {
                              _selectedFollowUpDate =
                                  selectedDate; // Update the state with the selected date
                            });
                          },
                          _postFollowUpDate, // Pass the post function here
                        );
                      },
                      child: Container(
                        height: 50,
                        width: 360,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_rounded,
                                size: 20.0, color: Colors.black),
                            const SizedBox(width: 8.0),

                            // Check if _selectedFollowUpDate is not null
                            _selectedFollowUpDate != null
                                ? Text(
                                    'FOLLOW UP: ${DateFormat('dd/MM/yyyy').format(_selectedFollowUpDate!)}',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Poppins'),
                                  )
                                : widget.lead['followup'] != null &&
                                        widget.lead['followup'].isNotEmpty
                                    ? Text(
                                        'FOLLOW UP: ${_formatFollowUpDate(widget.lead['followup'])}',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'Poppins'),
                                      )
                                    : Text(
                                        'No follow up date selected',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.red,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 20.0, color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${widget.lead['full_name'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(Icons.email,
                                size: 20.0, color: Colors.black),
                            const SizedBox(width: 8.0),
                            Text('${widget.lead['email'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone,
                              size: 20.0, color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text(
                              widget.lead['phone_number']
                                      .replaceAll(RegExp(r'[^0-9]'), '') ??
                                  'No phone',
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range,
                              size: 20.0, color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text(
                            '${formatDate(widget.lead['created_at'])}',
                            style: const TextStyle(
                              fontSize: 15.0,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment,
                              size: 20.0, color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${widget.lead['project_name'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOption, // Current selected option
                          hint: Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.userCheck,
                                color: Colors.black,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Please select status',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.black),
                          iconSize: 24,
                          style: const TextStyle(
                            fontSize: 15.0,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                          items: _dropdownOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    optionIcons[
                                    value], // Get the icon for the value
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(value),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedOption =
                                  newValue; // Update the selected option
                            });
                          },
                          // Customize the dropdown menu's appearance with rounded borders
                          dropdownColor:
                          Colors.white, // Background color of the dropdown
                          elevation: 3,
                          padding: EdgeInsets.all(0),
                          itemHeight: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Lead Information',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(FontAwesomeIcons.ad,
                              size: 20.0, color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${widget.lead['ad_name'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.flag,
                                size: 20.0, color: Colors.black),
                            const SizedBox(width: 8.0),
                            Text('${widget.lead['campaign_name'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(
                                widget.lead['platform'] == 'fb'
                                    ? FontAwesomeIcons.facebook
                                    : widget.lead['platform'] == 'ig'
                                        ? FontAwesomeIcons.instagram
                                        : widget.lead['platform'] == 'Website'
                                            ? FontAwesomeIcons
                                                .earthAmericas // Icon for website
                                    : widget.lead['platform'] == 'Google Ads'
                                    ? FontAwesomeIcons
                                    .google
                                            : Icons
                                                .help_outline, // Default icon if platform is not recognized
                                size: 20.0,
                                color: Colors.black),
                            const SizedBox(width: 8.0),
                            Text(
                              widget.lead['platform'] == 'fb'
                                  ? 'Facebook'
                                  : widget.lead['platform'] == 'ig'
                                      ? 'Instagram'
                                      : widget.lead['platform'] == 'Website'
                                          ? 'Website'
                              : widget.lead['platform'] == 'Google Ads'
                            ? 'Google Ads'
                                          : 'Unknown', // Default text if platform is not recognized
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    const Text(
                      'Send Message',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      // height: 120,
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // TextField for writing a message
                            SizedBox(
                              height: 5,
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'TITLE:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            TextField(
                              controller:
                                  _titleController, // A TextEditingController to manage the input
                              maxLines:
                                  null, // Allows the message to be multi-line
                              decoration: InputDecoration(
                                hintText: "Enter title",
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            // Send button
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'MESSAGE:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            TextField(
                              controller:
                                  _messageController, // A TextEditingController to manage the input
                              maxLines:
                                  null, // Allows the message to be multi-line
                              decoration: InputDecoration(
                                hintText: "Write a message...",
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              children: [
                                IconButton(
                                    style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue.shade900),
                                    onPressed: () {
                                      _pickFile();
                                    },
                                    icon: Icon(
                                      Icons.attachment_outlined,
                                      color: Colors.white,
                                    )),
                                Expanded(
                                  child: Container(
                                    child: _fileName == null
                                        ? Container()
                                        : Text(_fileName!),
                                  ),
                                ),
                                TextButton(
                                    onPressed: () {
                                      _showSendOptionsDialog(context);
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.blue.shade900,
                                      minimumSize: Size(100, 40),
                                    ),
                                    child: Text('Send',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ))),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            // Send button
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  launch(
                      'tel:${widget.lead['phone_number']?.replaceAll('p:', '') ?? 'No phone'}');
                },
                icon: const Icon(Icons.call),
                color: Colors.green,
              ),
              IconButton(
                onPressed: () {
                  launch(
                      'sms:${widget.lead['phone_number']?.replaceAll('p:', '') ?? 'No phone'}');
                },
                icon: const Icon(Icons.message),
                color: Colors.green,
              ),
              if (widget.lead['email'].isNotEmpty)
                IconButton(
                  onPressed: () {
                    launch('mailto:${widget.lead['email'] ?? ''}');
                  },
                  icon: const Icon(Icons.email),
                  color: Colors.green,
                ),
              IconButton(
                onPressed: () async {
                  final phoneNumber =
                      widget.lead['phone_number']?.replaceAll('p:', '') ?? '';
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
                icon: Image.asset(
                  'assets/icons/WhatsApp.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CircularDashboardCard extends StatelessWidget {
  final String title;
  final dynamic count;
  final Color color;

  CircularDashboardCard(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70, // Set your desired width
      height: 70, // Set your desired height
      decoration: BoxDecoration(
        shape: BoxShape.circle, // Circular shape
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 8, color: Colors.white),
            ),
            SizedBox(height: 1),
            count is int
                ? Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : count,
          ],
        ),
      ),
    );
  }
}

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(widget.tabs.length, (index) {
            return GestureDetector(
              onTap: () => _onItemTapped(index),
              child: Column(
                children: [
                  Text(
                    widget.tabs[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: _selectedIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedIndex == index
                          ? Colors.blue.shade900
                          : Colors.grey,
                    ),
                  ),
                  if (_selectedIndex == index)
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      height: 3,
                      width: 40,
                      color: Colors.blue.shade900,
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
