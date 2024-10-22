import 'dart:convert';
import 'dart:io';
import 'package:contacts_service/contacts_service.dart';
import 'package:dotphi_seo_app/pages/groups_screen.dart';
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
  List<Map<String, dynamic>> filteredData = [];
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
  int _todayLeadCount = 0;
  int _weeklyLeadCount = 0;
  int _monthlyLeadCount = 0;
  Map<String, String> _projectIds = {};
  String? selectedProjectId;
  bool showNotificationGif = false;
  String searchKeyword = '';

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
      DateTime entryDateTime = DateTime.parse(entryDate);
      DateTime now = DateTime.now();
      Duration difference = now.difference(entryDateTime);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes == 1) {
        return '1 minute ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours == 1) {
        return '1 hour ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays <= 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('dd/MM/yyyy').format(entryDateTime);
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

      // Handle filtering by date range
      if (selectedRange != null) {
        filteredData = sortedData.where((data) {
          final dateStr = data.containsKey('created_date')
              ? data['created_date']
              : data['added_date'];
          final date = DateTime.parse(dateStr);
          final start =
          DateTime(selectedRange!.start.year, selectedRange!.start.month);
          final end =
          DateTime(selectedRange!.end.year, selectedRange!.end.month + 1)
              .subtract(Duration(days: 1));

          return date.isAfter(start.subtract(Duration(days: 1))) &&
              date.isBefore(end.add(Duration(days: 1))) &&
              date.isAfter(selectedRange!.start.subtract(Duration(days: 1))) &&
              date.isBefore(selectedRange!.end.add(Duration(days: 1)));
        }).toList();
      } else {
        filteredData = sortedData.toList();
      }

      // Handle filtering by keyword
      if (searchKeyword.isNotEmpty) {
        filteredData = filteredData.where((data) {
          final name = data['name'] ?? '';
          final email = data['email'] ?? '';
          return (name.toLowerCase().contains(searchKeyword) ||
              email.toLowerCase().contains(searchKeyword));
        }).toList();
      }

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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return fetchApiData();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: showProjectPopup,
                      child: Row(
                        children: [
                          Text(
                            projectUrl != null
                                ? '$projectUrl'
                                : 'Select Project',
                            style: TextStyle(fontSize: 8, color: Colors.white),
                          ),
                          SizedBox(
                            width: 5,
                          ),
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
                    GestureDetector(
                      onTap: () {
                        // Navigate to the notification history screen
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
                  ],
                ),
              ),
            ],
          title: Row(
            children: List.generate('Paid-leads'.length, (index) {
              // Calculate font size based on the index
              double fontSize =
                  30 - index * 1.0; // Adjust base size and decrement as needed

              // Ensure the font size does not become too small
              fontSize = fontSize < 12.0 ? 12.0 : fontSize; // Minimum font size

              // Get the letter at the current index
              String letter = 'Paid-leads'[index];

              // Skip the font size calculation for spaces
              if (letter.trim().isEmpty) {
                return SizedBox(width: 4.0); // Adjust space width as needed
              }

              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 0.0), // Adjust padding if needed
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.blue.shade900,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),





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
                              search(value);
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
                                : _tillDateLeadCount,
                            color: Colors.blue,
                          ),
                          CircularDashboardCard(
                            title: 'Today',
                            count: isLoading
                                ? SpinKitCircle(
                              color: Colors.white,
                              size: 20.0,
                            )
                                : _todayLeadCount,
                            color: Colors.green,
                          ),
                          CircularDashboardCard(
                            title: 'This week',
                            count: isLoading
                                ? SpinKitCircle(
                              color: Colors.white,
                              size: 20.0,
                            )
                                : _weeklyLeadCount,
                            color: Colors.orange,
                          ),
                          CircularDashboardCard(
                            title: 'This month',
                            count: isLoading
                                ? SpinKitCircle(
                              color: Colors.white,
                              size: 20.0,
                            )
                                : _monthlyLeadCount,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      CustomTabBar(
                        tabs: ['All Leads', 'Groups'],
                        onTabSelected: (index) {
                          if (index == 0) {
                            // Stay on the same page or do something specific for "All Leads"
                          } else if (index == 1) {
                            // Navigate to Groups page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupsScreen(
                                    onGroupUpdated: () {},
                                    group: {},
                                    projectCode: widget.selectedProjectCode,
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
                      : apiData.isEmpty
                      ? Container(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/nodata.png',
                      height: 150,
                      width: 150,
                    ),
                  )
                      : filteredData.isEmpty && !showNoResults
                      ? ListView.builder(
                    itemCount: sortedData.length,
                    itemBuilder: (context, index) {
                      final data = sortedData[index];
                      final email = data['email'] ?? '';
                      final name = data['name'] ?? '';
                      final phone = data['phone'] ?? '';
                      String status = data['contact'] ?? '';

                      // Determine which date field is present
                      final date = data.containsKey('added_date')
                          ? data['added_date']
                          : data.containsKey('created_date')
                          ? data['created_date']
                          : '';

                      // Parse and format the date if it's present
                      DateTime? parsedDate;
                      if (date.isNotEmpty) {
                        try {
                          parsedDate = DateTime.parse(date);
                        } catch (e) {
                          parsedDate =
                          null; // Handle parsing errors
                        }
                      }

                      final formattedDate = parsedDate != null
                          ? DateFormat('dd/MM/yy')
                          .format(parsedDate)
                          : '';

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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    // Container(
                                    //   width: 110,
                                    //   height: 25,
                                    //   decoration: BoxDecoration(
                                    //       color: status=='uncontacted'?Colors.red:Colors.blue.shade900,
                                    //       borderRadius: BorderRadius.circular(10)),
                                    //   child: Center(
                                    //     child: Text(
                                    //       status,
                                    //       style: TextStyle(color: Colors.white),
                                    //     ),
                                    //   ),
                                    // ),
                                    // SizedBox(height: 2,),
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: status ==
                                                'uncontacted'
                                                ? FontWeight.bold
                                                : FontWeight
                                                .normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle:
                                            FontStyle.italic,
                                            fontFamily: 'Poppins',
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          phone,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: status ==
                                                'uncontacted'
                                                ? FontWeight.bold
                                                : FontWeight
                                                .normal,
                                          ),
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              launchDialer(phone);
                                            },
                                            icon: Icon(
                                              Icons.phone,
                                              color: Colors.green,
                                            )),
                                        ElevatedButton(
                                            style: ElevatedButton
                                                .styleFrom(
                                                backgroundColor:
                                                Colors
                                                    .blue
                                                    .shade900),
                                            onPressed: () {
                                              navigateToKeywordDetailScreen(
                                                  index);
                                            },
                                            child: Text(
                                              'Details',
                                              style: TextStyle(
                                                  color: Colors
                                                      .white),
                                            ))
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          onTap: () {
                            navigateToKeywordDetailScreen(index);
                          },
                        ),
                      );
                    },
                  )
                      : filteredData.isEmpty && showNoResults
                      ? Container(
                    alignment: Alignment.center,
                    child: Text(
                      'No search data found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final data = filteredData[index];
                      // Combine both date fields, prioritizing 'added_date' if both are present
                      final date = data['added_date'] ??
                          data['created_date'] ??
                          '';
                      final email = data['email'] ?? '';
                      final name = data['name'] ?? '';
                      final phone = data['phone'] ?? '';
                      String status = data['contact'] ?? '';
                      final formattedDate =
                      calculateTimeDifference(date);

                      return GestureDetector(
                        onLongPress: () {
                          navigateToKeywordDetailScreen(
                              index);
                        },
                        onLongPressEnd: (details) {
                          // On long press end, close the detail screen
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(10),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey
                                    .withOpacity(0.5),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Builder(
                              builder: (context) {
                                // Determine the GIF path based on the source
                                String source =
                                    data['source'] ?? '';
                                String gifPath;

                                if (source == 'lead') {
                                  gifPath =
                                  'assets/images/email.gif'; // Path for lead GIF
                                } else {
                                  gifPath =
                                  'assets/images/chatleads.gif'; // Path for chat leads GIF
                                }
                                // else {
                                // //   gifPath = 'assets/images/default.gif'; // Default GIF if source is unknown
                                // // }

                                return Image.asset(
                                  gifPath,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                            title: Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontFamily:
                                          'Poppins',
                                          fontWeight: status ==
                                              'uncontacted'
                                              ? FontWeight
                                              .w600
                                              : FontWeight
                                              .normal,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            phone,
                                            style: TextStyle(
                                              fontFamily:
                                              'Poppins',
                                              fontSize: 14,
                                              fontWeight: status ==
                                                  'uncontacted'
                                                  ? FontWeight
                                                  .w600
                                                  : FontWeight
                                                  .normal,
                                            ),
                                          ),
                                          // Icon(Icons.info,color: Colors.blue.shade900,),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        // fontStyle: FontStyle.italic,
                                        fontFamily: 'Poppins',
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        SizedBox(width: 4,),
                                        GestureDetector(
                                          child: Icon(
                                            Icons.info,
                                            color: Colors.blue
                                                .shade900,
                                          ),
                                          onTap: () {
                                            navigateToKeywordDetailScreen(
                                                index);
                                          },
                                        ),
                                        SizedBox(width:12),
                                        IconButton(
                                            onPressed: () {
                                              launchDialer(
                                                  phone);
                                            },
                                            icon: Icon(
                                              Icons.phone,
                                              color: Colors
                                                  .green,
                                            )),

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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  final User user;
  final String projectUrl;
  final selectedProjectCode;

  DetailScreen({
    this.data,
    required this.user,
    required this.projectUrl,
    this.selectedProjectCode,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with WidgetsBindingObserver {
  String contactedStatus = '';
  String changedStatus = '';
  List<Map<String, dynamic>> _groups = [];
  List<dynamic> _userGroupNames = [];
  DateTime? _selectedFollowUpDate;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _fileName;
  String? _filePath;
  int _contactedCount = 0;
  int _uncontactedCount = 0;
  bool isVisible = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getContactStatus(widget.selectedProjectCode, widget.data?['name']);
    _loadGroups();
    _loadUserGroups();
    _loadFollowUpDateForUser(widget.data?['name']);
    _loadCounts();
    _loadFollowUpDate(widget.data?['name']);
  }

  void didPopNext() {
    _loadGroups();
    _loadUserGroups();
    _loadFollowUpDateForUser(widget.data?['name']);
    _loadFollowUpDate(widget.data?['name']);
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

  Future<void> _updateContactStatus(String unique_id, String name) async {
    // Retrieve the current status from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use a unique key to store the status
    String contactKey = 'contact_status_${unique_id}_$name';
    String currentStatus = prefs.getString(contactKey) ?? 'uncontacted';

    // Determine the new status
    String newStatus =
    (currentStatus == 'uncontacted') ? 'contacted' : 'uncontacted';

    // Prepare the body data
    Map<String, String> body = {
      'unique_id': unique_id,
      'name': name,
      'contact': newStatus,
    };

    // First API call (lead endpoint)
    final leadResponse = await http.post(
      Uri.parse(
          'https://clients.dotphi.com/Api/login/lead'), // First API endpoint
      body: body,
    );

    // Second API call (livechat endpoint)
    final liveChatResponse = await http.post(
      Uri.parse(
          'https://clients.dotphi.com/Api/Login/livechat'), // Second API endpoint
      body: body,
    );

    // Handle responses
    if (leadResponse.statusCode == 200 && liveChatResponse.statusCode == 200) {
      final leadResponseData = json.decode(leadResponse.body);
      final liveChatResponseData = json.decode(liveChatResponse.body);

      // If both API responses indicate success, update SharedPreferences
      if (leadResponseData['status'] == 'success' &&
          liveChatResponseData['status'] == 'success') {
        await prefs.setString(contactKey, newStatus);
        print(
            'Contact status updated to $newStatus for $name in project $unique_id');
      } else {
        print(
            'Failed to update contact status on server (Lead: ${leadResponseData['message']}, LiveChat: ${liveChatResponseData['message']})');
      }
    } else {
      print(
          'Failed to update contact status. Lead Response: ${leadResponse.statusCode}, LiveChat Response: ${liveChatResponse.statusCode}');
    }
  }

  Future<void> _getContactStatus(String unique_id, String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use the same unique key to retrieve the status
    String contactKey = 'contact_status_${unique_id}_$name';
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
              ListTile(
                leading: Icon(Icons.perm_contact_cal_sharp,
                    color: Colors.blue.shade900),
                title: Text(
                  'Add to Phonebook',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  // Handle "Add to Phonebook" action
                  _addToContacts();
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.check, color: Colors.blue.shade900),
                title: Text(
                  widget.data?['contact'] == 'uncontacted'
                      ? 'Mark as Contacted'
                      : 'Mark as Uncontacted',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  // Handle "Mark as Contacted" action
                  _toggleContainer();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Status will be updated to ${widget.data?['contact'] == 'uncontacted' ? 'contacted' : 'uncontacted'}"),
                    backgroundColor: Colors.blue.shade900,
                  ));
                  _updateContactStatus(
                      widget.selectedProjectCode, widget.data?['name']);

                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
            ],
          ),
        );
      },
    );
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
                color: Colors.blue.shade900,
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // GestureDetector(
                      //   onTap: () {
                      //     Navigator.pop(context);
                      //     Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (context) => GroupsScreen(
                      //                   onGroupUpdated: _onGroupUpdated, group: {},
                      //                 )));
                      //     _onGroupUpdated();
                      //   },
                      //   child: Text(
                      //     "Manage groups",
                      //     style: TextStyle(color: Colors.white),
                      //   ),
                      // ),
                      GestureDetector(
                          onTap: () async {
                            Navigator.pop(
                                context); // Close the OptionsModalSheet
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateGroupPage(
                                  onGroupCreated: () async {
                                    _groups = await loadGroups();
                                    Future.delayed(Duration(milliseconds: 150),
                                            () {
                                          _groupsBottomSheet(context);
                                        });

                                    // Callback function, not directly used here but can be used if needed},
                                  },
                                ),
                              ),
                            );

                            // Automatically show GroupsModalSheet after CreateGroupPage is closed
                          },
                          child: Text(
                            "Create New",
                            style: TextStyle(color: Colors.white),
                          ))
                    ],
                  ),
                ),
              ),
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
                        leading: Icon(
                          Icons.group,
                          color: Color(group['color']),
                        ),
                        title: Text(
                          group['name'],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 15.0),
                  child: Text(
                    "Options",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
              ),
              ListTile(
                leading: Icon(Icons.groups, color: Colors.blue.shade900),
                title: Text(
                  'Add to groups',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  _loadGroups();
                  Navigator.pop(context);
                  Future.delayed(Duration(milliseconds: 100), () {
                    _groupsBottomSheet(context); // Show the groups modal sheet
                  });
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.close, color: Colors.blue.shade900),
                title: Text(
                  widget.data?['contact'] == 'uncontacted'
                      ? 'Mark as Contacted'
                      : 'Mark as Uncontacted',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  _toggleContainer();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Status will be updated to ${widget.data?['contact'] == 'uncontacted' ? 'contacted' : 'uncontacted'}"),
                    backgroundColor: Colors.blue.shade900,
                  ));
                  _updateContactStatus(
                      widget.selectedProjectCode, widget.data?['name']);
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.perm_contact_cal_sharp,
                    color: Colors.blue.shade900),
                title: Text(
                  'Add to phonebook',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  // Handle "Mark as Contacted" action
                  _addToContacts();
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToContacts() async {
    // Request permission to access contacts
    if (await Permission.contacts.request().isGranted) {
      final contact = Contact(
        givenName: widget.data?['name'],
        phones: [Item(label: 'mobile', value: widget.data?['phone'])],
        emails: [Item(label: 'work', value: widget.data?['email'])],
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

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('groups');
    if (groupsString != null) {
      setState(() {
        _groups = List<Map<String, dynamic>>.from(json.decode(groupsString));
      });
    }
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
    final userName = widget
        .data?['name']; // Ensure 'name' is the correct identifier for the user

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
    await _loadGroups();
  }

  void _onGroupUpdated() {
    _loadUserGroups();
    // Reload the user groups when a group is updated
    _loadFollowUpDate(widget.data?['name']);
    _loadGroups();
    _loadUserGroups();
  }

  Future<void> _addUserToGroup(Map<String, dynamic> group) async {
    final prefs = await SharedPreferences.getInstance();
    final groupIndex = _groups.indexWhere((g) => g['id'] == group['id']);

    if (groupIndex != -1) {
      final updatedGroup = _groups[groupIndex];
      final userName = widget.data?['name'];
      final email = widget.data?['email'];
      final added_date = widget.data?['added_date'];
      final phone = widget.data?['phone'];
      final project_name = widget.data?['project_name'];
      final domain = widget.data?['domain'];
      final url = widget.data?['url'];
      final message = widget.data?['message'];
      final comments = widget.data?['comments'];

      if (updatedGroup['users'] == null) {
        updatedGroup['users'] = [];
      }

      // Check if the user is already in the group's users list
      bool userExists =
      updatedGroup['users'].any((user) => user['name'] == userName);
      if (!userExists) {
        updatedGroup['users'].add({
          'name': userName,
          'email': email,
          'added_date': added_date,
          'phone': phone,
          'project_name': project_name,
          'domain': domain,
          'url': url,
          'message': message,
          'comments': comments
        });

        // Update in-memory list
        _groups[groupIndex] = updatedGroup;

        // Save updated groups list back to SharedPreferences
        await prefs.setString('groups', json.encode(_groups));

        // Save the group name in SharedPreferences
        List<String> userGroupNames =
            prefs.getStringList('groups_${userName}') ?? [];
        userGroupNames.add(group['name']);
        await prefs.setStringList('groups_${userName}', userGroupNames);

        // Update the state to reflect the changes
        setState(() {
          _userGroupNames = userGroupNames;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.data?['name']} saved to ${group['name']}'),
          backgroundColor: Colors.blue.shade900,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
            Text('${widget.data?['name']} is already in ${group['name']}'),
            backgroundColor: Colors.blue.shade900));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Group does not exist'),
          backgroundColor: Colors.blue.shade900));
    }
  }

  Future<void> _postFollowUpDate(String uniqueId, String seoId, DateTime followupDate) async {
    final url = 'https://clients.dotphi.com/Api/login/lead'; // Replace with your actual endpoint

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

    print('Response status code: ${response.statusCode}'); // Log the response status code
    print('Response body: ${response.body}'); // Log the response body

    if (response.statusCode == 200) {
      // Handle success
      print('Follow-up date posted successfully: ${response.body}');
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
              return ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    color: _selectedDate == date
                        ? Colors.white
                        : Colors.blue.shade900,
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
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 15.0),
                      child: Text(
                        "Schedule follow-up for $username",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildListTile('Today', DateTime.now()),
                          _buildListTile('Tomorrow',
                              DateTime.now().add(Duration(days: 1))),
                          _buildListTile('3 days from now',
                              DateTime.now().add(Duration(days: 3))),
                          _buildListTile('1 week from now',
                              DateTime.now().add(Duration(days: 7))),
                          _buildListTile('1 month from now',
                              DateTime.now().add(Duration(days: 30))),
                          ListTile(
                            title: Text(
                              'Select custom date and time',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                            onTap:
                            _showCustomDateSelector, // Handle custom date selection
                          ),
                        ],
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

  Future<void> _loadFollowUpDateForUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('follow_up_date_$username');
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

  Future<void> _loadFollowUpDate(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('follow_up_date_$userName');

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
          title: Text('Send Message'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(
                  Icons.textsms_outlined,
                  color: Colors.lightBlueAccent,
                ),
                title: Text(
                  'Send via Text',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  String message = _messageController.text;
                  _sendSMS(context, message, widget.data?['phone']);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.green,
                ),
                title: Text(
                  'Send via Whatsapp',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  String message = _messageController.text;
                  _sendWhatsAppMessage(context, message, widget.data?['phone']);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.email_outlined,
                  color: Colors.red,
                ),
                title: Text(
                  'Send via Email',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  String title = _titleController.text;
                  String message = _messageController.text;
                  _sendEmail(context, title, message, widget.data?['email']);
                  Navigator.pop(context);
                },
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

  Future<void> _sendWhatsAppMessage(BuildContext context, String message, String recipient) async {bool fileSelected = _filePath != null && _filePath!.isNotEmpty;

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
      String recipient) async {if (_filePath != null && _filePath!.isNotEmpty) {
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
      path: widget.data?['email'],
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
              title: Row(
                children: 'Leads'.split('').map((letter) {
                  int fontSize = 40 - 'Leads'.indexOf(letter) * 4;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize.toDouble(),
                        color: Colors.blue.shade900,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )),
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
                        Text(
                          " ${widget.data?['name'] ?? ''}",
                          style: const TextStyle(
                              fontSize: 20,
                              fontFamily:
                              'Poppins', // Reference the family name here
                              fontWeight: FontWeight.bold),
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
                                      widget.data?['contact'].toUpperCase(),
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
                            _userGroupNames.isNotEmpty
                                ? Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                  _userGroupNames.map((groupName) {
                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      height: 30,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade900,
                                        borderRadius:
                                        BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$groupName',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
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
                        String username = widget.data?['name'] ?? '';
                        String uniqueId = widget.data?['project_unique_code'] ?? '';
                        String seoId = widget.data?['seo_id'] ?? '';

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
                            const Icon(Icons.event_available_rounded, size: 20.0, color: Colors.black),
                            const SizedBox(width: 8.0),

                            // Check if _selectedFollowUpDate is not null
                            _selectedFollowUpDate != null
                                ? Text(
                              'FOLLOW UP: ${DateFormat('dd/MM/yyyy').format(_selectedFollowUpDate!)}',
                              style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                            )
                                : widget.data?['followup'] != null && widget.data!['followup'].isNotEmpty
                                ? Text(
                              'FOLLOW UP: ${_formatFollowUpDate(widget.data!['followup'])}',
                              style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
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
                          Text('${widget.data?['name'] ?? ''}',
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
                            Text('${widget.data?['email'] ?? ''}',
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
                          Text('${widget.data?['phone'] ?? ''}',
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
                            DateFormat('dd/MM/yyyy').format(DateTime.parse(
                                widget.data?['added_date'] ??
                                    widget.data?['created_date'] ??
                                    '')),
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
                          Text('${widget.data?['project_name'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),
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
                          const Icon(Icons.domain,
                              size: 20.0, color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${widget.data?['domain'] ?? ''}',
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
                            const Icon(Icons.link,
                                size: 20.0, color: Colors.black),
                            const SizedBox(width: 8.0),
                            Text('${widget.data?['url'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18.0),
                    const Text(
                      'Message',
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
                        child: Text('${widget.data?['message'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 15.0,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.justify),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    const Text(
                      'Comments',
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
                        child: Text('${widget.data?['comments'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 15.0,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.justify),
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
                  launch('tel:${widget.data?['phone'] ?? ''}');
                },
                icon: const Icon(Icons.call),
                color: Colors.green,
              ),
              IconButton(
                onPressed: () {
                  launch('sms:${widget.data?['phone'] ?? ''}');
                },
                icon: const Icon(Icons.message),
                color: Colors.green,
              ),
              if (widget.data?['email'] != null &&
                  widget.data?['email'].isNotEmpty)
                IconButton(
                  onPressed: () {
                    launch('mailto:${widget.data?['email'] ?? ''}');
                  },
                  icon: const Icon(Icons.email),
                  color: Colors.green,
                ),
              IconButton(
                onPressed: () async {
                  final phoneNumber = widget.data?['phone'] ?? '';
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
