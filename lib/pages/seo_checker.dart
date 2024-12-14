import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Seo/websitedetails_screen.dart';
import 'facebooklogin.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/webmasters.readonly',
    ],
  );

  User? _user;
  String? _accessToken;
  List<String> _websites = [];
  Map<String, Map<String, dynamic>> _siteDetails = {};
  Map<String, String> _sitePermissions = {};
  List<dynamic> _sitemaps = [];
  late bool isLoading;
  bool _isLoading = false; //

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  // Check if the user is already logged in by verifying SharedPreferences
  Future<void> _checkLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedAccessToken = prefs.getString('accessToken');
    String? userId = prefs.getString('userId');
    String? userEmail = prefs.getString('userEmail');
    String? userName = prefs.getString('userName');

    // If accessToken exists, the user is logged in, so fetch the data
    if (storedAccessToken != null) {
      setState(() {
        _accessToken = storedAccessToken;
        _user = FirebaseAuth.instance.currentUser; // User is already signed in
      });

      // Fetch Google Search Console data
      await _fetchSearchConsoleData(storedAccessToken);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // The user canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      setState(() {
        _user = user;
        _accessToken = googleAuth.accessToken;
      });

      if (_accessToken != null && _user != null) {
        // Save user details and access token to SharedPreferences
        await _saveUserData(_user!, _accessToken!);

        // Fetch Google Search Console data
        await _fetchSearchConsoleData(_accessToken!);
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

  // Save the user data and access token to SharedPreferences
  Future<void> _saveUserData(User user, String accessToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.uid);
    await prefs.setString('userEmail', user.email ?? '');
    await prefs.setString('userName', user.displayName ?? '');
    await prefs.setString('accessToken', accessToken);
  }

  Future<void> _fetchSearchConsoleData(String accessToken) async {
    setState(() {
      isLoading = true; // Start loading
    });

    final url = 'https://www.googleapis.com/webmasters/v3/sites';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sites = data['siteEntry'] as List<dynamic>? ?? [];

        // Store website URLs in state
        setState(() {
          _websites =
              sites.map<String>((site) => site['siteUrl'] as String).toList();
        });
      } else {
        print(
            'Failed to fetch data from Search Console: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Search Console data: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _fetchSiteData(String accessToken, String siteUrl) async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Fetch site details
      await _fetchSiteDetails(accessToken, siteUrl);

      // Fetch site performance
      await _fetchSitePerformance(accessToken, siteUrl);

      // Compare site performance
      await _compareSitePerformance(accessToken, siteUrl);

      // Fetch all data related to the site
      await _fetchAllData(accessToken, siteUrl);

      // Fetch and store sitemaps for the specific site
      final sitemaps =
          await fetchSitemapsFromSearchConsole(siteUrl, accessToken);
      print('Sitemaps for $siteUrl: $sitemaps');
    } catch (e) {
      print('Error fetching data for site $siteUrl: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _fetchSiteDetails(String accessToken, String siteUrl) async {
    final url =
        'https://www.googleapis.com/webmasters/v3/sites/${Uri.encodeComponent(siteUrl)}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final permissions = data['permissionLevel'] as String? ?? 'Unknown';
        setState(() {
          _siteDetails[siteUrl] = data;
          print(_siteDetails);
          _sitePermissions[siteUrl] = permissions;
        });
      } else {
        print('Failed to fetch site details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching site details: $e');
    }
  }

  Future<void> _fetchSitePerformance(String accessToken, String siteUrl) async {
    final endDate = DateTime.now();
    // Start date of the previous month
    final startDate = DateTime(endDate.year, endDate.month - 1, 1);
    // End date of the previous month
    final lastDayOfMonth = DateTime(endDate.year, endDate.month, 0);

    final startDateString = '${startDate.toIso8601String().split('T')[0]}';
    final endDateString = '${lastDayOfMonth.toIso8601String().split('T')[0]}';

    final url =
        'https://www.googleapis.com/webmasters/v3/sites/${Uri.encodeComponent(siteUrl)}/searchAnalytics/query';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['date'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance'] = data;
            print(_siteDetails[siteUrl]);
          }
        });

        // Call additional data fetching function
        await _fetchAdditionalData(
            accessToken, siteUrl, startDateString, endDateString);
      } else {
        print(
            'Failed to fetch site performance: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching site performance: $e');
    }
  }

  Future<void> _fetchAdditionalData(String accessToken, String siteUrl, String startDateString, String endDateString) async {
    final url =
        'https://www.googleapis.com/webmasters/v3/sites/${Uri.encodeComponent(siteUrl)}/searchAnalytics/query';

    try {
      // Fetch top 5 entries for 'query'
      final responseQueryTop5 = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['query'],
          'rowLimit': 5,
          'orderBy': [
            {'field': 'impressions', 'sortOrder': 'DESCENDING'}
          ], // Sorting by impressions to get top queries
        }),
      );

      if (responseQueryTop5.statusCode == 200) {
        final dataQueryTop5 = json.decode(responseQueryTop5.body);
        print('Top 5 Queries Data: $dataQueryTop5'); // Print the data
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_query_top5'] = dataQueryTop5;
          }
        });
      } else {
        print(
            'Failed to fetch top 5 queries data: ${responseQueryTop5.statusCode} - ${responseQueryTop5.body}');
      }

      // Fetch top 5 entries for 'country'
      final responseCountryTop5 = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['country'],
          'rowLimit': 5,
          'orderBy': [
            {'field': 'impressions', 'sortOrder': 'DESCENDING'}
          ],
        }),
      );

      if (responseCountryTop5.statusCode == 200) {
        final dataCountryTop5 = json.decode(responseCountryTop5.body);
        print('Top 5 Countries Data: $dataCountryTop5'); // Print the data
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_country_top5'] =
                dataCountryTop5;
          }
        });
      } else {
        print(
            'Failed to fetch top 5 countries data: ${responseCountryTop5.statusCode} - ${responseCountryTop5.body}');
      }

      // Fetch top 5 entries for 'searchAppearance'
      final responseSearchAppearanceTop5 = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['searchAppearance'],
          'rowLimit': 5,
        }),
      );

      if (responseSearchAppearanceTop5.statusCode == 200) {
        final dataSearchAppearanceTop5 =
            json.decode(responseSearchAppearanceTop5.body);
        print(
            'Top 5 Search Appearances Data: $dataSearchAppearanceTop5'); // Print the data
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_searchAppearance_top5'] =
                dataSearchAppearanceTop5;
          }
        });
      } else {
        print(
            'Failed to fetch top 5 search appearances data: ${responseSearchAppearanceTop5.statusCode} - ${responseSearchAppearanceTop5.body}');
      }

      // Fetch top 5 entries for 'device'
      final responseDeviceTop5 = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['device'],
          'rowLimit': 5,
          'orderBy': [
            {'field': 'impressions', 'sortOrder': 'DESCENDING'}
          ],
        }),
      );

      if (responseDeviceTop5.statusCode == 200) {
        final dataDeviceTop5 = json.decode(responseDeviceTop5.body);
        print('Top 5 Devices Data: $dataDeviceTop5'); // Print the data
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_device_top5'] = dataDeviceTop5;
          }
        });
      } else {
        print(
            'Failed to fetch top 5 devices data: ${responseDeviceTop5.statusCode} - ${responseDeviceTop5.body}');
      }
    } catch (e) {
      print('Error fetching additional data: $e');
    }
  }

  Future<List<dynamic>> fetchSitemapsFromSearchConsole(String siteUrl, String accessToken,) async {
    // URL encode the siteUrl to handle special characters
    final encodedSiteUrl = Uri.encodeComponent(siteUrl);
    final String apiUrl =
        'https://www.googleapis.com/webmasters/v3/sites/$encodedSiteUrl/sitemaps';

    try {
      // Define the headers, including the access token for authorization
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // Make the GET request to the Google Search Console API
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON data
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract the sitemap list from the response
        final List<dynamic> sitemaps = data['sitemap'] ?? [];

        // Save sitemaps into _siteDetails
        if (_siteDetails[siteUrl] != null) {
          _siteDetails[siteUrl]!['sitemaps'] = sitemaps;
        } else {
          // Initialize the site details if not present
          _siteDetails[siteUrl] = {'sitemaps': sitemaps};
        }

        // Print the sitemaps data to console
        print('Sitemaps: ${_siteDetails[siteUrl]!['sitemaps']}');

        // Return the list of sitemaps
        return sitemaps;
      } else {
        // Handle non-successful response codes
        throw Exception(
            'Failed to load sitemaps. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any exceptions that occur during the request
      throw Exception('Error fetching sitemaps: $e');
    }
  }

  Future<void> _compareSitePerformance(String accessToken, String siteUrl) async {
    final now = DateTime.now();

    // Calculate the first day of the current month and the previous month
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    final firstDayOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfPreviousMonth =
        DateTime(now.year, now.month, 0); // Last day of previous month

    // Format the dates
    final currentMonthString =
        '${firstDayOfCurrentMonth.toIso8601String().split('T')[0]}';
    final previousMonthStartString =
        '${firstDayOfPreviousMonth.toIso8601String().split('T')[0]}';
    final previousMonthEndString =
        '${lastDayOfPreviousMonth.toIso8601String().split('T')[0]}';

    final url =
        'https://www.googleapis.com/webmasters/v3/sites/${Uri.encodeComponent(siteUrl)}/searchAnalytics/query';

    try {
      // Function to fetch data for a specific month
      Future<Map<String, dynamic>> _fetchPerformanceForMonth(
          String startDate, String endDate) async {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'startDate': startDate,
            'endDate': endDate,
            'dimensions': ['date'],
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['rows'] != null && data['rows'].isNotEmpty) {
            double clicks = 0.0, impressions = 0.0, ctr = 0.0, position = 0.0;

            for (var row in data['rows']) {
              clicks += row['clicks'] ?? 0.0;
              impressions += row['impressions'] ?? 0.0;
              ctr += row['ctr'] ?? 0.0;
              position += row['position'] ??
                  0.0; // Average position can be calculated differently
            }

            int rowCount = data['rows'].length;
            return {
              'clicks': clicks,
              'impressions': impressions,
              'ctr': ctr / rowCount,
              'position': position / rowCount,
            };
          }
        }
        return {'clicks': 0.0, 'impressions': 0.0, 'ctr': 0.0, 'position': 0.0};
      }

      // Fetch performance data for the current month and the previous month
      final currentMonthData = await _fetchPerformanceForMonth(
          currentMonthString,
          DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0]);
      final previousMonthData = await _fetchPerformanceForMonth(
          previousMonthStartString, previousMonthEndString);

      // Calculate the percentage change between the two months
      double? _calculatePercentageChange(double oldValue, double newValue) {
        if (oldValue == 0 && newValue > 0) {
          return 100.0; // 100% increase
        } else if (oldValue == 0 && newValue == 0) {
          return 0.0; // No change when both values are zero
        } else {
          return ((newValue - oldValue) / oldValue) * 100;
        }
      }

      // Calculate the percentage changes
      final clicksChange = _calculatePercentageChange(
          previousMonthData['clicks'], currentMonthData['clicks']);
      final impressionsChange = _calculatePercentageChange(
          previousMonthData['impressions'], currentMonthData['impressions']);
      final ctrChange = _calculatePercentageChange(
          previousMonthData['ctr'], currentMonthData['ctr']);
      final positionChange = _calculatePercentageChange(
          previousMonthData['position'], currentMonthData['position']);

      // Update the UI with the results
      setState(() {
        _siteDetails[siteUrl]!['performanceComparison'] = {
          'clicksChange': clicksChange != null
              ? (clicksChange > 0
                  ? '+${clicksChange.toStringAsFixed(2)}%'
                  : '${clicksChange.toStringAsFixed(2)}%')
              : "No data",
          'impressionsChange': impressionsChange != null
              ? (impressionsChange > 0
                  ? '+${impressionsChange.toStringAsFixed(2)}%'
                  : '${impressionsChange.toStringAsFixed(2)}%')
              : "No data",
          'ctrChange': ctrChange != null
              ? (ctrChange > 0
                  ? '+${ctrChange.toStringAsFixed(2)}%'
                  : '${ctrChange.toStringAsFixed(2)}%')
              : "No data",
          'positionChange': positionChange != null
              ? (positionChange < 0
                  ? '${positionChange.toStringAsFixed(2)}%'
                  : '+${positionChange.toStringAsFixed(2)}%')
              : "No data", // A lower position value is better, so a negative change is an improvement
        };

        print(
            "Clicks change: ${clicksChange != null ? (clicksChange > 0 ? '+$clicksChange%' : '$clicksChange%') : "No data"}");
        print(
            "Impressions change: ${impressionsChange != null ? (impressionsChange > 0 ? '+$impressionsChange%' : '$impressionsChange%') : "No data"}");
        print(
            "CTR change: ${ctrChange != null ? (ctrChange > 0 ? '+$ctrChange%' : '$ctrChange%') : "No data"}");
        print(
            "Position change: ${positionChange != null ? (positionChange < 0 ? '$positionChange%' : '+$positionChange%') : "No data"}");
      });
    } catch (e) {
      print('Error comparing site performance: $e');
    }
  }

  Future<void> _fetchAllData(String accessToken, String siteUrl) async {
    final url =
        'https://www.googleapis.com/webmasters/v3/sites/${Uri.encodeComponent(siteUrl)}/searchAnalytics/query';

    try {
      // Get today's date
      final now = DateTime.now();

      // Calculate the first day of the current month
      final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
      // Calculate the last day of the previous month
      final lastDayOfPreviousMonth =
          firstDayOfCurrentMonth.subtract(Duration(days: 1));
      // Calculate the first day of the previous month
      final firstDayOfPreviousMonth = DateTime(
          lastDayOfPreviousMonth.year, lastDayOfPreviousMonth.month, 1);

      // Format dates to YYYY-MM-DD
      final String startDateString =
          firstDayOfPreviousMonth.toIso8601String().substring(0, 10);
      final String endDateString =
          lastDayOfPreviousMonth.toIso8601String().substring(0, 10);

      // Fetch all entries for 'query'
      final responseQuery = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['query'],
          'orderBy': [
            {'field': 'impressions', 'sortOrder': 'DESCENDING'}
          ],
        }),
      );

      if (responseQuery.statusCode == 200) {
        final dataQuery = json.decode(responseQuery.body);
        print('All Queries Data: $dataQuery');
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_query'] = dataQuery;
          }
        });
      } else {
        print(
            'Failed to fetch query data: ${responseQuery.statusCode} - ${responseQuery.body}');
      }

      // Fetch all entries for 'page'
      final responsePage = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['page'],
          'orderBy': [
            {'field': 'impressions', 'sortOrder': 'DESCENDING'}
          ],
        }),
      );

      if (responsePage.statusCode == 200) {
        final dataPage = json.decode(responsePage.body);
        print('All Pages Data: $dataPage');
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_page'] = dataPage;
          }
        });
      } else {
        print(
            'Failed to fetch page data: ${responsePage.statusCode} - ${responsePage.body}');
      }

      // Fetch all entries for 'country'
      final responseCountry = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['country'],
          'orderBy': [
            {'field': 'impressions', 'sortOrder': 'DESCENDING'}
          ],
        }),
      );

      if (responseCountry.statusCode == 200) {
        final dataCountry = json.decode(responseCountry.body);
        print('All Countries Data: $dataCountry');
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_country'] = dataCountry;
          }
        });
      } else {
        print(
            'Failed to fetch country data: ${responseCountry.statusCode} - ${responseCountry.body}');
      }

      // Fetch all entries for 'searchAppearance'
      final responseSearchAppearance = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['searchAppearance'],
        }),
      );

      if (responseSearchAppearance.statusCode == 200) {
        final dataSearchAppearance = json.decode(responseSearchAppearance.body);
        print('All Search Appearances Data: $dataSearchAppearance');
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_searchAppearance'] =
                dataSearchAppearance;
          }
        });
      } else {
        print(
            'Failed to fetch search appearance data: ${responseSearchAppearance.statusCode} - ${responseSearchAppearance.body}');
      }

      // Fetch all entries for 'device'
      final responseDevice = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startDate': startDateString,
          'endDate': endDateString,
          'dimensions': ['device'],
          'orderBy': [
            {'field': 'impressions', 'sortOrder': 'DESCENDING'}
          ],
        }),
      );

      if (responseDevice.statusCode == 200) {
        final dataDevice = json.decode(responseDevice.body);
        print('All Devices Data: $dataDevice');
        setState(() {
          if (_siteDetails.containsKey(siteUrl)) {
            _siteDetails[siteUrl]!['performance_device'] = dataDevice;
          }
        });
      } else {
        print(
            'Failed to fetch device data: ${responseDevice.statusCode} - ${responseDevice.body}');
      }
    } catch (e) {
      print('Error fetching all data: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      // Sign out from Firebase and Google Sign-In
      await _auth.signOut();
      await _googleSignIn.signOut();

      // Clear the stored user data and access token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      await prefs.remove('accessToken');

      // Clear the local state
      setState(() {
        _user = null;
        _accessToken = null;
        _websites = [];
        _siteDetails = {};
        _sitePermissions = {};
        _sitemaps = [];
      });
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  void _navigateToWebsiteDetailsPage(String siteUrl) {
    // final List<dynamic> sitemaps = ;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebsiteDetailsPage(
          siteUrl: siteUrl,
          siteDetails: _siteDetails[siteUrl],
          permissionLevel: _sitePermissions[siteUrl] ?? 'Unknown',
          sitemaps: _siteDetails[siteUrl]?['sitemaps'] ?? [],
          accesstoken: _accessToken!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset('assets/images/report.png',
            height: 10,
            width: 10,),
        ),
        title:  FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Search Console',
            style: TextStyle(
            fontSize: 20,  // Reduced font size to fit better
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
          ),
        ),
        actions: [
          if (_user != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _signOut,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white38.withOpacity(
                  0.8), // Very subtle overlay color with 10% opacity
              BlendMode.overlay, // Use overlay to lighten the image slightly
            ),
          ),
        ),
        child: Center(
          child: _user == null
              ? Column(
                children: [
                  Container(
                    width: 300,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900),
                        onPressed: _signInWithGoogle,
                        child: Text(
                          'Sign in to Google Search Console',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                  ),
                  FacebookLoginButton(onLoginSuccess: (String accessToken) {  },)
                ],
              )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    CircleAvatar(
                      backgroundImage: NetworkImage(_user!.photoURL ?? ''),
                      radius: 30,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Name: ${_user!.displayName}',
                      style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Email: ${_user!.email}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins'),
                    ),
                    SizedBox(height: 20),

                    Expanded(
                      child: _isLoading
                          ? Center(
                              child:
                                  SpinKitCircle(
                                    color: Colors.blue.shade900,
                                  )) // Show loader when loading
                          : ListView.builder(
                              itemCount: _websites.length,
                              itemBuilder: (context, index) {
                                final siteUrl = _websites[index];
                                return GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _isLoading = true; // Start loading
                                    });

                                    // Fetch the site data and await its completion
                                    await _fetchSiteData(
                                        _accessToken!, siteUrl);

                                    setState(() {
                                      _isLoading = false; // Stop loading
                                    });

                                    // Navigate only after the data has been fetched
                                    _navigateToWebsiteDetailsPage(siteUrl);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 16),
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
                                      title: Text(
                                        siteUrl,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // ElevatedButton(
                    //   onPressed: _signOut,
                    //   child: Text('Sign out'),
                    // ),
                  ],
                ),
        ),
      ),
    );
  }
}

class ChartData {
  final DateTime date;
  final double clicks;
  final double impressions;

  ChartData(this.date, this.clicks, this.impressions);
}

class PerformanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Your PerformanceScreen implementation here
    return Container();
  }
}
