import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'trending_screen.dart';
import '../seo_checker.dart';
import 'sitemapsPage.dart';
import 'traffic_screen.dart';

class WebsiteDetailsPage extends StatefulWidget {
  final String siteUrl;
  final Map<String, dynamic>? siteDetails;
  final String permissionLevel;
  final List<dynamic> sitemaps;
  final String accesstoken;

  WebsiteDetailsPage({
    required this.siteUrl,
    required this.siteDetails,
    required this.permissionLevel,
    required this.sitemaps,
    required this.accesstoken,
  });

  @override
  State<WebsiteDetailsPage> createState() => _WebsiteDetailsPageState();
}

class _WebsiteDetailsPageState extends State<WebsiteDetailsPage> {
  int _currentIndex = 0; // Track the selected index
  double totalClicks = 0;
  double totalImpressions = 0;
  double totalCTR = 0.0;
  double totalPosition = 0.0;
  double averageCTR = 0.0;
  double averagePosition = 0.0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.siteDetails != null) {
      String jsonData = jsonEncode(widget.siteDetails?['performance']);
      calculatePerformanceFromJson(jsonData);
    }

    _fetchSitePerformance(widget.accesstoken, widget.siteUrl);
    final List<Widget> _pages = [
      PerformanceScreen(), // Assuming you have these screens defined
      TrafficScreen(
        siteUrl: widget.siteUrl,
        siteDetails: widget.siteDetails,
      ),
      TrendingScreen(siteUrl: widget.siteUrl, siteDetails: widget.siteDetails),
      SitemapDetailsScreen(sitemaps: widget.sitemaps, siteUrl: widget.siteUrl),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchSitePerformance(String accessToken, String siteUrl) async {
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - 1, 1);
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
          // Check if widget.siteDetails and siteUrl key exist
          if (widget.siteDetails != null) {
            widget.siteDetails![siteUrl] ??= {}; // Initialize if null

            // Safely update the performance key
            widget.siteDetails?[siteUrl]!['performance'] = data;

            print(widget.siteDetails?[siteUrl]);
          }
        });

        await _fetchAdditionalData(
            accessToken, siteUrl, startDateString, endDateString);
      } else {
        print('Failed to fetch site performance: ${response.statusCode} - ${response.body}');
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
          ],
        }),
      );

      if (responseQueryTop5.statusCode == 200) {
        final dataQueryTop5 = json.decode(responseQueryTop5.body);
        print('Top 5 Queries Data: $dataQueryTop5');

        setState(() {
          if (widget.siteDetails != null) {
            widget.siteDetails![siteUrl] ??= {}; // Initialize if null
            widget.siteDetails?[siteUrl]!['performance_query_top5'] = dataQueryTop5;
          }
        });
      } else {
        print('Failed to fetch top 5 queries data: ${responseQueryTop5.statusCode} - ${responseQueryTop5.body}');
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
        print('Top 5 Countries Data: $dataCountryTop5');

        setState(() {
          if (widget.siteDetails != null) {
            widget.siteDetails![siteUrl] ??= {}; // Initialize if null
            widget.siteDetails?[siteUrl]!['performance_country_top5'] = dataCountryTop5;
          }
        });
      } else {
        print('Failed to fetch top 5 countries data: ${responseCountryTop5.statusCode} - ${responseCountryTop5.body}');
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
        final dataSearchAppearanceTop5 = json.decode(responseSearchAppearanceTop5.body);
        print('Top 5 Search Appearances Data: $dataSearchAppearanceTop5');

        setState(() {
          if (widget.siteDetails != null) {
            widget.siteDetails![siteUrl] ??= {}; // Initialize if null
            widget.siteDetails?[siteUrl]!['performance_searchAppearance_top5'] = dataSearchAppearanceTop5;
          }
        });
      } else {
        print('Failed to fetch top 5 search appearances data: ${responseSearchAppearanceTop5.statusCode} - ${responseSearchAppearanceTop5.body}');
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
        print('Top 5 Devices Data: $dataDeviceTop5');

        setState(() {
          if (widget.siteDetails != null) {
            widget.siteDetails![siteUrl] ??= {}; // Initialize if null
            widget.siteDetails?[siteUrl]!['performance_device_top5'] = dataDeviceTop5;
          }
        });
      } else {
        print('Failed to fetch top 5 devices data: ${responseDeviceTop5.statusCode} - ${responseDeviceTop5.body}');
      }
    } catch (e) {
      print('Error fetching additional data: $e');
    }
  }

  void calculatePerformanceFromJson(String jsonData) {
    // Parse the JSON string into a Map
    Map<String, dynamic> performanceData = jsonDecode(jsonData);

    List<dynamic> rows = performanceData['rows'] ?? [];

    // Initialize totals
    totalClicks = 0.0; // Initialize as double
    totalImpressions = 0.0; // Initialize as double
    totalCTR = 0.0;
    totalPosition = 0.0;

    // Calculate totals
    for (var row in rows) {
      // Accessing properties and accumulating totals
      var clicks = row['clicks'];
      var impressions = row['impressions'];
      var ctr = row['ctr'];
      var position = row['position'];

      // Convert all to double before adding
      totalClicks +=
          (clicks is int ? clicks.toDouble() : (clicks as num).toDouble());
      totalImpressions += (impressions is int
          ? impressions.toDouble()
          : (impressions as num).toDouble());
      totalCTR += (ctr is int ? ctr.toDouble() : (ctr as num).toDouble());
      totalPosition += (position is int
          ? position.toDouble()
          : (position as num).toDouble());
    }

    // Calculate averages
    int rowCount = rows.length;
    averageCTR = rowCount > 0
        ? totalCTR * 100 / rowCount
        : 0.0; // Avoid division by zero
    averagePosition =
        rowCount > 0 ? totalPosition / rowCount : 0.0; // Avoid division by zero
  }

  @override
  Widget build(BuildContext context) {
    final queryData = widget.siteDetails?['performance_query_top5'];
    final countryData = widget.siteDetails?['performance_country_top5'];
    final searchAppearanceData =
        widget.siteDetails?['performance_searchAppearance_top5'];
    final deviceData = widget.siteDetails?['performance_device_top5'];
    // Extract performance data if available
    final performanceData = widget.siteDetails?['performance'];

    List<ChartData>? chartData;
    if (performanceData != null && performanceData['rows'] != null) {
      final rows = performanceData['rows'] as List<dynamic>;
      chartData = rows.map<ChartData>((row) {
        final clicks = row['clicks'] as num?;
        final impressions = row['impressions'] as num?;
        final dateString = row['keys'][0] as String?;

        // Handle potential null values
        final date = dateString != null ? DateTime.tryParse(dateString) : null;
        final clickCount = clicks != null ? clicks.toDouble() : 0.0;
        final impressionCount =
            impressions != null ? impressions.toDouble() : 0.0;

        return ChartData(
          date ?? DateTime.now(), // Default to current date if null
          clickCount,
          impressionCount,
        );
      }).toList();
    }

    // Compute metrics

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Website Statistics',
          style: TextStyle(
            fontFamily: 'Poppins', // Reference the family name here
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blue.shade900,
                      ),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 8.0, top: 8.0, bottom: 8.0),
                        child: Text(
                          'Performance',
                          style: TextStyle(
                            fontFamily:
                                'Poppins', // Reference the family name here
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'URL: ${widget.siteUrl}',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF4A261)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                        child: Text(
                      'Last one month highlights',
                      style: TextStyle(
                        fontFamily: 'Poppins', // Reference the family name here
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    )),
                  ),
                  Container(
                    height: 100,
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 10, right: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15)),
                                color: Colors.blue,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Total \n Clicks:\n $totalClicks',
                                  style: TextStyle(
                                    fontFamily:
                                        'Poppins', // Reference the family name here
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: Colors.deepPurpleAccent,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Total \nImpressions:  \n $totalImpressions',
                                  style: TextStyle(
                                    fontFamily:
                                        'Poppins', // Reference the family name here
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: Colors.lightGreenAccent,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Average \nCTR: \n ${averageCTR.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontFamily:
                                        'Poppins', // Reference the family name here
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(15),
                                    bottomRight: Radius.circular(15)),
                                color: Colors.orange,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Average \nPosition: \n ${averagePosition.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontFamily:
                                        'Poppins', // Reference the family name here
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Icon(Icons.circle,
                                    color: Colors.blue, size: 15),
                                Text('Clicks',
                                    style: TextStyle(fontFamily: 'Poppins')),
                                SizedBox(width: 5),
                                Icon(Icons.circle,
                                    color: Colors.deepPurpleAccent, size: 15),
                                Text('Impressions',
                                    style: TextStyle(fontFamily: 'Poppins')),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          SfCartesianChart(
                            primaryXAxis: DateTimeAxis(
                                dateFormat: DateFormat('yyyy-MM-dd'),
                                labelStyle: TextStyle(fontSize: 10),
                                axisLine:
                                    AxisLine(color: Colors.black, width: 1)),
                            primaryYAxis: NumericAxis(
                                labelStyle: TextStyle(fontSize: 10),
                                axisLine:
                                    AxisLine(color: Colors.black, width: 1)),
                            series: <CartesianSeries>[
                              SplineAreaSeries<ChartData, DateTime>(
                                dataSource: chartData,
                                xValueMapper: (ChartData data, _) => data.date,
                                yValueMapper: (ChartData data, _) =>
                                    data.clicks,
                                name: 'Clicks',
                                color: Colors.blue.withOpacity(
                                    0.5), // Add some transparency for area effect
                                borderColor: Colors
                                    .blue, // Color for the border of the area
                                borderWidth: 2, // Border width of the area
                              ),
                              SplineAreaSeries<ChartData, DateTime>(
                                dataSource: chartData,
                                xValueMapper: (ChartData data, _) => data.date,
                                yValueMapper: (ChartData data, _) =>
                                    data.impressions,
                                name: 'Impressions',
                                color: Colors.deepPurpleAccent.withOpacity(
                                    0.5), // Add some transparency for area effect
                                borderColor: Colors
                                    .deepPurpleAccent, // Color for the border of the area
                                borderWidth: 2, // Border width of the area
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Queries Data Container
                        if (queryData != null && queryData['rows'] != null)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.blue[100],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Top 5 Queries",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Poppins'),
                                ),
                                SizedBox(height: 10),
                                ...queryData['rows'].map<Widget>((data) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Query:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['keys'][0] ?? 'N/A'}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Clicks:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['clicks']}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Impressions:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['impressions']}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'CTR:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['ctr'].toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Position:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['position'].toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                        // Country Data Container
                        if (countryData != null && countryData['rows'] != null)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 15),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.blue[100],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Top 5 Countries",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Poppins'),
                                ),
                                SizedBox(height: 10),
                                ...countryData['rows'].map<Widget>((data) {
                                  return Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.only(
                                        bottom:
                                            10), // Add bottom margin for spacing
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            children: [
                                              Text(
                                                'Query:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                " ${data['keys'][0] ?? 'N/A'}",
                                                style: TextStyle(
                                                    fontFamily: 'Poppins'),
                                              ),
                                            ],
                                          ),
                                          Wrap(
                                            children: [
                                              Text(
                                                'Clicks:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                " ${data['clicks']}",
                                                style: TextStyle(
                                                    fontFamily: 'Poppins'),
                                              ),
                                            ],
                                          ),
                                          Wrap(
                                            children: [
                                              Text(
                                                'Impressions:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                " ${data['impressions']}",
                                                style: TextStyle(
                                                    fontFamily: 'Poppins'),
                                              ),
                                            ],
                                          ),
                                          Wrap(
                                            children: [
                                              Text(
                                                'CTR:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                " ${data['ctr'].toStringAsFixed(2)}",
                                                style: TextStyle(
                                                    fontFamily: 'Poppins'),
                                              ),
                                            ],
                                          ),
                                          Wrap(
                                            children: [
                                              Text(
                                                'Position:',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                " ${data['position'].toStringAsFixed(2)}",
                                                style: TextStyle(
                                                    fontFamily: 'Poppins'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                        // Search Appearance Data Container
                        if (searchAppearanceData != null &&
                            searchAppearanceData['rows'] != null)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 15),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.blue[100],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Top 5 Search Appearances",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Poppins'),
                                ),
                                SizedBox(height: 10),
                                ...searchAppearanceData['rows']
                                    .map<Widget>((data) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Query:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['keys'][0] ?? 'N/A'}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Clicks:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['clicks']}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Impressions:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['impressions']}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'CTR:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['ctr'].toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Position:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['position'].toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                        // Device Data Container
                        if (deviceData != null && deviceData['rows'] != null)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 15),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.blue[100],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Top 5 Devices",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Poppins'),
                                ),
                                SizedBox(height: 10),
                                ...deviceData['rows'].map<Widget>((data) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Query:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['keys'][0] ?? 'N/A'}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Clicks:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['clicks']}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Impressions:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['impressions']}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'CTR:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['ctr'].toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              children: [
                                                Text(
                                                  'Position:',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  " ${data['position'].toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          TrafficScreen(
            siteUrl: widget.siteUrl,
            siteDetails: widget.siteDetails,
          ),
          TrendingScreen(
            siteUrl: widget.siteUrl,
            siteDetails: widget.siteDetails,
          ),
          SitemapDetailsScreen(
            sitemaps: widget.sitemaps,
            siteUrl: widget.siteUrl,
          ),
          // Add other pages here
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/conbg.jpg'), // Path to your image
            fit: BoxFit.cover, // Adjust the fit as necessary
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.jumpToPage(index);
          },
          selectedItemColor: Colors.blue[900],
          selectedLabelStyle: TextStyle(
            fontFamily: 'Poppins', // Change to your desired font family
            fontSize: 14, // Adjust font size as needed
            fontWeight: FontWeight.w500, // Change font weight if needed
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Poppins', // Change to your desired font family
            fontSize: 12, // Adjust font size as needed
            fontWeight: FontWeight.w500, // Change font weight if needed
          ),// Color when the item is selected
          unselectedItemColor: Colors.grey,    // Color when the item is not selected
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Performance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.traffic),
              label: 'Traffic',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Trending',

            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Sitemaps',

            ),
          ],
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
