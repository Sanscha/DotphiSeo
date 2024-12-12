import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class KeywordScreen extends StatefulWidget {
  final User? user; // Made nullable
  final String? selectedProjectCode; // Made nullable
  final String? projectUrl; // Made nullable

  KeywordScreen({
    Key? key,
    this.user, // No longer required
    this.selectedProjectCode, // No longer required
    this.projectUrl, // No longer required
  }) : super(key: key);

  @override
  _KeywordScreenState createState() => _KeywordScreenState();
}

class _KeywordScreenState extends State<KeywordScreen> {
  GlobalKey<RefreshIndicatorState> refreshKey = GlobalKey<RefreshIndicatorState>();

  List<Map<String, dynamic>> apiData = [];
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> sortedData = [];
  TextEditingController searchController = TextEditingController();
  bool showNoResults = false;
  String? _selectedProjectCode;
  bool isLoading = true;
  String? projectUrl;
  String? _projectUrl;
  List<String> _projectUniqueCodes = [];
  String? selectedProjectCode;
  Map<String, String> _projectData = {};

  @override
  void initState() {
    super.initState();


    fetchApiData();

    _fetchProjectData().then((data) {
      setState(() {
        _projectData = data;
        _loadSelectedProjectCode();
        if (_projectData.length == 1) {
          _fetchProjectUrl(_projectData.keys.first);
        }
      });
    });


    _fetchProjectUniqueCodes().then((codes) {
      setState(() {
        _projectUniqueCodes = codes;
        _loadSelectedProjectCode();
        _loadProjectUrl();// Load the selected value from shared preferences
      });
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
          projectData[uniqueCode] = projectName;
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
        print(jsonData);
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
                    });
                    await _saveSelectedProjectCode(newValue ?? '');
                    await _fetchProjectUrl(newValue ?? '');
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
    final project = data.firstWhere((item) => item['project_unique_code'] == projectCode, orElse: () => null);
    if (project != null) {
      final url = project['project_url'];
      await prefs.setString('projectUrl', url); // Save the project URL in shared preferences
      setState(() {
        projectUrl = url;
      });
      // Call fetchApiData with the new project code
      fetchApiData();
    } else {
      setState(() {
        projectUrl = null;
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
      final response = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/Login/keyword'),
          body: {'unique_id': _selectedProjectCode},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          final apiDataFromResponse = responseData['data'] as List<dynamic>;
          setState(() {
            apiData = List<Map<String, dynamic>>.from(apiDataFromResponse);
            sortedData = List<Map<String, dynamic>>.from(apiDataFromResponse);
          });
        } else {
          print('API response status is not success');
        }
      } else {
        print('API request failed with status code: ${response.statusCode}');
      }
    } else {
      setState(() {
        apiData = [];
        sortedData = [];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void navigateToKeywordDetailScreen(int index) {
    final data = sortedData[index];
    searchController.clear();
    Navigator.push(
      context,
        MaterialPageRoute(
          builder: (context) => KeywordDetailScreen(
            data: data,
            user: widget.user!, // Use the non-null assertion operator if you're sure it's not null
            projectUrl: widget.projectUrl!,
            selectedProjectCode: widget.selectedProjectCode,
          ),
        )

    );
  }

  void search(String keyword) {
    setState(() {
      filteredData = sortedData
          .where((data) =>
      data['keywords']
          .toLowerCase()
          .contains(keyword.toLowerCase()) ||
          data['project_name']
              .toLowerCase()
              .contains(keyword.toLowerCase()))
          .toList();
      showNoResults = filteredData.isEmpty;
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      filteredData.clear();
      showNoResults = false;
    });
  }

  void sortByDate() {
    sortedData.sort((a, b) {
      final dateA = DateTime.parse(a['created']);
      final dateB = DateTime.parse(b['created']);
      return dateB.compareTo(dateA); // Descending order
    });

    setState(() {
      filteredData = [];
      showNoResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: refreshKey, // Add this line
      onRefresh: () {
        return fetchApiData()
        ;
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
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Image.asset('assets/images/keyword.png',
            height: 15,width: 15,),
          ),
          title:  FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Keywords',
              style: TextStyle(
                fontSize: 20,  // Reduced font size to fit better
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
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
                                hintText: 'Search keywords',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                  fontFamily:
                                  'Poppins',
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
                        ],
                      ),
                    ),
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
                      ?
                  Container(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/nodata.png',
                      height: 150,
                      width: 150,
                    ),
                  )
                      : filteredData.isEmpty && !showNoResults
                      ? ListView.builder(
                    itemCount: apiData.length,
                    itemBuilder: (context, index) {
                      final data = apiData[index];
                      final email = data['keywords'] ?? '';
                      final name = data['project_name'] ?? '';
                      final rank = data['rank'] ?? '';
                      // final date = data['created'] ?? '';
                      //
                      // final parsedDate =
                      // DateTime.parse(date);
                      // final formattedDate =
                      // DateFormat('dd/MM/yyyy')
                      //     .format(parsedDate);

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
                              // Text(
                              //   name,
                              //   style: TextStyle(
                              //     fontWeight: FontWeight.bold,
                              //     fontSize: 16,
                              //     fontFamily:
                              //     'Poppins',
                              //   ),
                              // ),
                              // SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily:
                                  'Poppins',
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                           rank,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily:
                              'Poppins',
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
                        fontFamily:
                        'Poppins',
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final data = filteredData[index];
                      final email = data['keywords'] ?? '';
                      final name =
                          data['project_name'] ?? '';
                      final rank = data['rank'] ?? '';

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
                          // title: Text(
                          //   name,
                          //   style: TextStyle(
                          //     fontWeight: FontWeight.bold,
                          //     fontSize: 16,
                          //     fontFamily:
                          //     'Poppins',
                          //   ),
                          // ),
                          subtitle: Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily:
                              'Poppins',
                              fontWeight: FontWeight.bold
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









class KeywordDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final User user;
  final String projectUrl;
  final selectedProjectCode;

  KeywordDetailScreen({required this.data, required this.user,
    required this.projectUrl,required this.selectedProjectCode,
  });


  @override
  _KeywordDetailScreenState createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {


  String? _selectedProjectCode;
  bool isLoading = true;
  String? projectUrl;
  String? _projectUrl;


  Future<void> fetchApiData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProjectCode = prefs.getString('project_unique_code');
      _projectUrl = prefs.getString('projectUrl');
    });
  }

  @override
  Widget build(BuildContext context) {
    String? keywordId = widget.data['keyword_id']?.toString();
    String? projectId = widget.data['project_id']?.toString();
    String? rank = widget.data['rank']?.toString();
    String? keyword = widget.data['keywords']?.toString();
    String? url = widget.data['project_url']?.toString();
    String? status = widget.data['status']?.toString();
    String? created = widget.data['created']?.toString();
    String? modified = widget.data['modified']?.toString();
    String? projectUniqueCode = widget.data['project_unique_code']?.toString();
    String? projectName = widget.data['project_name']?.toString();


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
          fit: BoxFit.cover,
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
            'Keywords',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30, // You can adjust this font size as needed
              color: Colors.blue.shade900, // Adjust the color as needed
            ),
          ),
        )

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            _buildDetailItem('Keyword', keyword!),
            SizedBox(height: 8),
            _buildDetailItem('Url', url!),
            SizedBox(height: 8),
            _buildDetailItem('Rank', rank!),
            SizedBox(height: 8),
            _buildDetailItem('Status', status!),
            SizedBox(height: 8),
            _buildDetailItem('Created', created!),
            SizedBox(height: 8),
            _buildDetailItem('Project Name', projectName!),
          ],
        ),
      ),
    )]);
  }

  Widget _buildDetailItem(String label, String value) {
    if (label == 'Created' || label == 'Modified') {
      DateTime dateTime = DateTime.parse(value);
      String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
      value = formattedDate;
    }
    return Container(
      height: 50,
      width: 360,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontFamily:
              'Poppins',
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily:
                  'Poppins',
                ),
              ),
              TextSpan(text: value,style: TextStyle(fontSize: 14, fontFamily:
              'Poppins',),),
            ],
          ),
        ),
      ),
    );
  }
}


