import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/login_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class LivechatScreenn extends StatefulWidget {
  final User user;
  final selectedProjectCode;
  final String projectUrl;

  LivechatScreenn({required this.user, required this.selectedProjectCode,
    required this.projectUrl,
  });

  @override
  _LivechatScreennState createState() => _LivechatScreennState();
}

class _LivechatScreennState extends State<LivechatScreenn> {
  List<Map<String, dynamic>> apiData = [];
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> sortedData = [];
  TextEditingController searchController = TextEditingController();
  bool showNoResults = false;
  String? _selectedProjectCode;
  bool isLoading = true;
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
  int totalDataInRange = 0; // Declare the totalDataInRange variable
  Map<String, String> _projectData = {};
  int _tillDateLeadCount = 0;
  int _todayLeadCount = 0;
  int _weeklyLeadCount = 0;
  int _monthlyLeadCount = 0;
  Map<String, String> _projectIds = {};
  String? selectedProjectId;


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
        _loadProjectUrl();// Load the selected value from shared preferences
      });
    });
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

    setState(() {
      isLoading = true;
    });

    if (projectId == null && projectCode != null) {
      projectId = _projectIds[projectCode];
    }
    final tillDateResponse = await http.post(
      Uri.parse('https://clients.dotphi.com/Api/login/getCountofliveLeads'),
      body: {
        'project_id': projectId,
      },
    );

    if (tillDateResponse.statusCode == 200) {
      final data = json.decode(tillDateResponse.body);
      final tillDateLeadCount = data['Till_the_date_lead_count'] as int;
      setState(() {
        _tillDateLeadCount = tillDateLeadCount;
      });
      // saveLeadCountToSharedPreferences('tillDateLeadCount', _tillDateLeadCount);
    } else {
      throw Exception('Failed to fetch till date lead count');
    }

    final todayResponse = await http.post(
      Uri.parse('https://clients.dotphi.com/Api/login/getTodayliveLeads'),
      body: {
        'project_id': projectId,
      },
    );

    if (todayResponse.statusCode == 200) {
      final data = json.decode(todayResponse.body);
      final todayLeadCount = data['Today_lead_count'] as int;
      setState(() {
        _todayLeadCount = todayLeadCount;
      });
    } else {
      throw Exception('Failed to fetch today lead count');
    }

    final weeklyResponse = await http.post(
      Uri.parse('https://clients.dotphi.com/Api/login/getWeeklyliveLeads'),
      body: {
        'project_id': projectId,
      },
    );

    if (weeklyResponse.statusCode == 200) {
      final data = json.decode(weeklyResponse.body);
      final weeklyLeadCount = data['weekly_lead_count'] as int;
      setState(() {
        _weeklyLeadCount = weeklyLeadCount;
      });
    } else {
      throw Exception('Failed to fetch weekly lead count');
    }

    final monthlyResponse = await http.post(
      Uri.parse('https://clients.dotphi.com/Api/login/getMonthlyLiveLeads'),
      body: {
        'project_id': projectId,
      },
    );

    if (monthlyResponse.statusCode == 200) {
      final data = json.decode(monthlyResponse.body);
      final monthlyLeadCount = data['Monthly_lead_count'] as int;
      setState(() {
        _monthlyLeadCount = monthlyLeadCount;
      });
    } else {
      throw Exception('Failed to fetch monthly lead count');
    }
    setState(() {
      isLoading = false;
    });
  }




  Future<Map<String, String>> _fetchProjectData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString('clientId') ?? '';

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://clients.dotphi.com/Api/Login/multiple_project');
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

    final url = Uri.parse('https://clients.dotphi.com/Api/Login/multiple_project');
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
        final uniqueCodes = data.map((item) => item['project_unique_code'].toString()).toList();
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
  void refreshLivechatScreenn() {
    fetchApiData().then((_) {
      filterDataByDateRange();
    });
  }

  Future<void> fetchApiDataForSelectedProject() async {
    if (selectedProjectCode != null && selectedProjectCode!.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/Login/livechat'),
        body: {'unique_id': selectedProjectCode},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        setState(() {
          apiData = List<Map<String, dynamic>>.from(responseData['data']);
          sortedData = List<Map<String, dynamic>>.from(apiData);
          sortedData.sort((a, b) {
            final dateA = DateTime.parse(a['created_date']);
            final dateB = DateTime.parse(b['created_date']);
            return dateB.compareTo(dateA); // Descending order
          });
          filterDataByDateRange(); // Move here
        });
      } else {
        print('API request failed with status code: ${response.statusCode}');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add this function to calculate the time difference
  String calculateTimeDifference(String entryDate) {
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
  }


  Future<void> fetchApiData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProjectCode = prefs.getString('project_unique_code');
      _projectUrl = prefs.getString('projectUrl');
    });

    if (_selectedProjectCode != null && _selectedProjectCode!.isNotEmpty) {
      final response = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/Login/livechat'),
        body: {'unique_id': _selectedProjectCode},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        setState(() {
          apiData = List<Map<String, dynamic>>.from(responseData['data']);
          sortedData = List<Map<String, dynamic>>.from(apiData);
          sortedData.sort((a, b) {
            final dateA = DateTime.parse(a['created_date']);
            final dateB = DateTime.parse(b['created_date']);
            return dateB.compareTo(dateA); // Descending order
          });
          filterDataByDateRange(); // Move here
        });
      } else {
        print('API request failed with status code: ${response.statusCode}');
      }
    } else {
      setState(() {
        apiData = [];
        sortedData = [];
        selectedRange = DateTimeRange(
          start: DateTime.now().subtract(Duration(days: 7)),
          end: DateTime.now(),
        );
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  void sortByDate() {
    sortedData.sort((a, b) {
      final dateA = DateTime.parse(a['created_date']);
      final dateB = DateTime.parse(b['created_date']);
      return dateB.compareTo(dateA); // Descending order
      // For ascending order, use: return dateA.compareTo(dateB);
    });
    setState(() {
      filteredData = [];
      showNoResults = false;
    });
  }

  void navigateToKeywordDetailScreen(int index) async {
    final data = searchController.text.isNotEmpty ? filteredData[index] : sortedData[index];
    searchController.clear();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          data: data,
          user: widget.user,
          projectUrl: _projectUrl ?? '',
        ),
      ),
    );

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
        // clearSearch();
      });
    }
    refreshLivechatScreenn(); // Call the refreshLivechatScreenn method when coming back from the detail screen
  }

  String searchKeyword = '';

  void search(String keyword) {
    setState(() {
      searchKeyword = keyword.toLowerCase();

      if (selectedRange != null) {
        filteredData = sortedData.where((data) {
          final date = DateTime.parse(data['created_date']);
          final start = DateTime(selectedRange!.start.year, selectedRange!.start.month);
          final end = DateTime(selectedRange!.end.year, selectedRange!.end.month + 1).subtract(Duration(days: 1));

          return date.isAfter(start.subtract(Duration(days: 1))) &&
              date.isBefore(end.add(Duration(days: 1))) &&
              date.isAfter(selectedRange!.start.subtract(Duration(days: 1))) &&
              date.isBefore(selectedRange!.end.add(Duration(days: 1)));
        }).toList();
      } else {
        filteredData = sortedData.toList();
      }

      if (searchKeyword.isNotEmpty) {
        filteredData = filteredData.where((data) {
          final name = data['name'] ?? '';
          final email = data['email'] ?? '';
          return (name.toLowerCase().contains(searchKeyword) ||
              email.toLowerCase().contains(searchKeyword));
        }).toList();
      }

      showNoResults = filteredData.isEmpty;
    });
  }

  Future<void> fetchApiDataForProject(String projectCode) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://clients.dotphi.com/Api/Login/livechat'),
      body: {'unique_id': projectCode},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      setState(() {
        apiData = List<Map<String, dynamic>>.from(responseData['data']);
        sortedData = List<Map<String, dynamic>>.from(apiData);
        sortedData.sort((a, b) {
          final dateA = DateTime.parse(a['created_date']);
          final dateB = DateTime.parse(b['created_date']);
          return dateB.compareTo(dateA); // Descending order
        });
        filterDataByDateRange(); // Move here
      });
    } else {
      print('API request failed with status code: ${response.statusCode}');
    }

    setState(() {
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
    final data = jsonData['data'] as List<dynamic>;
    final project = data.firstWhere((item) => item['project_unique_code'] == projectCode, orElse: () => null);
    if (project != null) {
      final url = project['project_url'];
      await prefs.setString('projectUrl', url); // Save the project URL in shared preferences
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
                      selectedProjectId = _projectIds[newValue!]; // Update selectedProjectId
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
                      style: TextStyle(color: Colors.blue.shade900,),
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
          final date = DateTime.parse(data['created_date']);
          return date.isAfter(start) && date.isBefore(end);
        }).toList();
        showNoResults = filteredData.isEmpty;
        totalDataInRange = filteredData.length; // Update totalDataInRange to match filtered data count
      });
    }
  }

  void showCalendarPicker() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange ?? DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade900, // Set the primary color to blue.shade900
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


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return fetchApiData();},
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
              child: ElevatedButton(
                onPressed: showProjectPopup,
                child: Row(
                  children: [
                    Text(
                      projectUrl != null ? '$projectUrl' : 'Select Project',
                      style: TextStyle(
                        fontSize: 8,color: Colors.white
                      ),
                    ),
                    SizedBox(width: 5,),
                    Image.asset('assets/images/dl.png',
                      height: 20,
                      width: 20,),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ), backgroundColor: Colors.blue.shade900,
                  elevation: 3,
                  shadowColor: Colors.blue.shade900,
                ),
              ),
            ),
          ],
          title:  Row(
            children: 'LiveChat'.split('').map((letter) {
              int fontSize = 30 - 'LiveChat'.indexOf(letter) * 2;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.0),
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
          )


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
            Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
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
                      child: Row(
                          children: [
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
                                  hintText: 'Search live-chat',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins', // Reference the family name here
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
                              icon: Image.asset('assets/images/calendar.gif',
                                scale: 20,
                              ),
                              onPressed: showCalendarPicker,
                            ),
                          ]
                      ),
                    ),
                  ),
                ),
                selectedRange != null
                    ? Text(
                  'Live-chat from:  ${DateFormat('dd-MM-yyyy').format(selectedRange!.start)}  to  ${DateFormat('dd-MM-yyyy').format(selectedRange!.end)}',
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
                                :_todayLeadCount,
                            color: Colors.green,
                          ),
                          CircularDashboardCard(
                            title: 'Weekly',
                            count: isLoading
                                ? SpinKitCircle(
                              color: Colors.white,
                              size: 20.0,
                            )
                                :_weeklyLeadCount,
                            color: Colors.orange,
                          ),
                          CircularDashboardCard(
                            title: 'Monthly',
                            count: isLoading
                                ? SpinKitCircle(
                              color: Colors.white,
                              size: 20.0,
                            )
                                :_monthlyLeadCount,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
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
                      final date = data['created_date'] ?? '';

                      final parsedDate =
                      DateTime.parse(date);
                      final formattedDate =
                      DateFormat('dd/MM/yyyy')
                          .format(parsedDate);

                      return Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset:
                              const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            navigateToKeywordDetailScreen(
                                index);
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
                      final email = data['email'] ?? '';
                      final name = data['name'] ?? '';
                      final date = data['created_date'] ?? '';

                      // final parsedDate =
                      // DateTime.parse(date);
                      // final formattedDate =
                      // DateFormat('dd/MM/yyyy')
                      //     .format(parsedDate);

                      final formattedDate = calculateTimeDifference(date);

                      return Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
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
                              offset: const Offset(
                                  0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Image.asset('assets/images/notification1.gif', // Replace with the actual path for each row in your assets
                            width: 40,  // Adjust the width of the image
                            height: 40, // Adjust the height of the image
                            fit: BoxFit.cover, // Adjust the fit of the image
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Poppins', // Reference the family name here
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            email,
                            style: TextStyle(
                              fontFamily: 'Poppins', // Reference the family name here
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            navigateToKeywordDetailScreen(
                                index);
                          },
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











class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final User user;
  final String projectUrl;


  DetailScreen({required this.data, required this.user,
    required this.projectUrl,
  });

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
          // drawer: MainDrawer(
          //   username: '${user.username}',
          //   email: '${user.email}',
          //   user: user,
          //   selectedProjectCode: null,
          //     projectUrl: projectUrl
          // ),
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

            title:  Row(
              children: 'LiveChat'.split('').map((letter) {
                int fontSize = 40 - 'LiveChat'.indexOf(letter) * 3;
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
                    Text(
                      "Details of ${data['name'] ?? ''}",
                      style: const TextStyle(fontSize: 20,fontFamily: 'Poppins', // Reference the family name here
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
                          const Icon(Icons.person, size: 20.0,color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${data['name'] ?? ''}', style: const TextStyle(fontSize: 15.0,color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(Icons.email, size: 20.0,color: Colors.black),
                            const SizedBox(width: 8.0),
                            Text('${data['email'] ?? ''}', style: const TextStyle(fontSize: 15.0,color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2, blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 20.0,color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${data['phone'] ?? ''}', style: const TextStyle(fontSize: 15.0,color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50, width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2, blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child:  Row(
                        children: [
                          const Icon(Icons.date_range,
                              size: 20.0, color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text(
                            DateFormat('dd/MM/yyyy').format(DateTime.parse(data['created_date'])),
                            style: const TextStyle(fontSize: 15.0, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2, blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, size: 20.0,color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${data['project_name'] ?? ''}', style: const TextStyle(fontSize: 15.0,color: Colors.black)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10.0),
                    const Text(
                      'Lead Information',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold,),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      height: 50, width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2, blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.domain, size: 20.0,color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${data['domain'] ?? ''}', style: const TextStyle(fontSize: 15.0,
                              color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 50,
                      width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
                          const Icon(Icons.link, size: 20.0,color: Colors.black),
                          const SizedBox(width: 8.0),
                          Text('${data['url'] ?? ''}', style: const TextStyle(fontSize: 15.0,color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Container(
                    //   height: 50,
                    //   width: 360,
                    //   padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(30),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.grey.withOpacity(0.5),
                    //         spreadRadius: 2,
                    //         blurRadius: 5,
                    //         offset: const Offset(0, 3),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       const Icon(Icons.subject, size: 20.0,color: Colors.black),
                    //       const SizedBox(width: 8.0),
                    //       Text('${data['subject'] ?? ''}', style: const TextStyle(fontSize: 15.0,color: Colors.black)),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 10.0),
                    const Text(
                      'Message',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      width: 360,
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2, blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                            '${data['message'] ?? ''}',
                            style: const TextStyle(fontSize: 15.0,color: Colors.black),
                            textAlign: TextAlign.justify
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // const Text(
                    //   'Comment',
                    //   style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    // ),
                    // const SizedBox(height: 16.0),
                    // Container(
                    //   height: 50,
                    //   width: 360,
                    //   padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(30),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.grey.withOpacity(0.5),
                    //         spreadRadius: 2,
                    //         blurRadius: 5,
                    //         offset: const Offset(0, 3),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Text(
                    //     '${data['comments'] ?? ''}',
                    //     style: const TextStyle(fontSize: 15.0,color: Colors.blue),
                    //   ),
                    // ),
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
                  launch('tel:${data['phone'] ?? ''}');
                },
                icon: const Icon(Icons.call),
                color: Colors.green,
              ),
              IconButton(
                onPressed: () {
                  launch('sms:${data['phone'] ?? ''}');
                },
                icon: const Icon(Icons.message),
                color: Colors.green,
              ),
              if (data['email'] != null && data['email'].isNotEmpty)
                IconButton(
                  onPressed: () {
                    launch('mailto:${data['email'] ?? ''}');
                  },
                  icon: const Icon(Icons.email),
                  color: Colors.green,
                ),
              IconButton(
                onPressed: () async {
                  final phoneNumber = data['phone'] ?? '';
                  final whatsappUrl = 'https://wa.me/$phoneNumber';
                  final whatsappInstalled = await canLaunch(whatsappUrl);
                  if (whatsappInstalled) {
                    launch(whatsappUrl);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp is not installed on your device.'),
                      ),
                    );
                  }
                },
                icon: Image.asset(
                  'assets/icons/WhatsApp.png',
                  width: 40, height: 40,
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

  CircularDashboardCard({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,  // Set your desired width
      height: 70,  // Set your desired height
      decoration: BoxDecoration(
        shape: BoxShape.circle,  // Circular shape
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
