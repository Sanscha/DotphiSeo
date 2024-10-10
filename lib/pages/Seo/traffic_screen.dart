import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TrafficScreen extends StatefulWidget {
  final String siteUrl;
  final Map<String, dynamic>? siteDetails;

  TrafficScreen({
    required this.siteUrl,
    required this.siteDetails,
  });
  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen> {
  @override
  Widget build(BuildContext context) {
    final performanceComparison = widget.siteDetails?['performanceComparison'];
    // Your NotificationsPage implementation here
    return  Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
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
                  'Traffic from Google',
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
            padding: const EdgeInsets.all(10.0),
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
                  'Comparing previous 2 months',
                  style: TextStyle(
                    fontFamily: 'Poppins', // Reference the family name here
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                )),
          ),
          SizedBox(height: 5,),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the performance comparison data
                if (performanceComparison != null) ...[
                  // Clicks Change
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clicks Change:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      performanceComparison['clicksChange'] != null &&
                                          performanceComparison['clicksChange']!.startsWith('+')
                                          ? EvaIcons.trendingUp
                                          : EvaIcons.trendingDown,
                                      color: performanceComparison['clicksChange'] != null &&
                                          performanceComparison['clicksChange']!.startsWith('+')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    Text(
                                      'Increased through ${performanceComparison['clicksChange'] ?? "No data"}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Impressions Change
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Impressions Change:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),

                                Row(
                                  children: [
                                    Icon(
                                      performanceComparison['impressionsChange'] != null &&
                                          performanceComparison['impressionsChange']!.startsWith('+')
                                          ? EvaIcons.trendingUp
                                          : EvaIcons.trendingDown,
                                      color: performanceComparison['impressionsChange'] != null &&
                                          performanceComparison['impressionsChange']!.startsWith('+')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    Text(
                                      'Increased through ${performanceComparison['impressionsChange'] ?? "No data"}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // CTR Change
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CTR Change:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),

                                Row(
                                  children: [
                                    Icon(
                                      performanceComparison['ctrChange'] != null &&
                                          performanceComparison['ctrChange']!.startsWith('+')
                                          ? EvaIcons.trendingUp
                                          : EvaIcons.trendingDown,
                                      color: performanceComparison['ctrChange'] != null &&
                                          performanceComparison['ctrChange']!.startsWith('+')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    Text(
                                      'Increased through ${performanceComparison['ctrChange'] ?? "No data"}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Position Change
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Position Change:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      performanceComparison['positionChange'] != null &&
                                          performanceComparison['positionChange']!.startsWith('+')
                                          ? EvaIcons.trendingUp
                                          : EvaIcons.trendingDown,
                                      color: performanceComparison['positionChange'] != null &&
                                          performanceComparison['positionChange']!.startsWith('+')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    Text(
                                      'Increased through ${performanceComparison['positionChange'] ?? "No data"}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ] else ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No performance comparison data available.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
                // Add the rest of your UI here (charts, other pages, etc.)
              ],
            ),
          ),


        ],
      ),
    );
  }
}