import 'package:flutter/material.dart';

class TrendingScreen extends StatefulWidget {
  final String siteUrl;
  final Map<String, dynamic>? siteDetails;

  TrendingScreen({
    required this.siteUrl,
    required this.siteDetails,
  });

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  String _selectedCategory = 'query'; // Default selected category is 'query'
  int _entryLimit = 10; // Default entry limit
  final TextEditingController _limitController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Extracting the respective data
    final queryData = widget.siteDetails?['performance_query'] ?? [];
    final pageData = widget.siteDetails?['performance_page'] ?? [];
    final countryData = widget.siteDetails?['performance_country'] ?? [];
    final appearanceData = widget.siteDetails?['performance_searchAppearance'] ?? [];
    final deviceData = widget.siteDetails?['performance_device'] ?? [];

    // Function to render the data based on the selected category
    Widget _buildDataView(dynamic data) {
      // Check if the data is a list, otherwise, try to extract rows or wrap it in a list
      if (data is! List) {
        data = data is Map && data['rows'] != null ? data['rows'] : [data]; // Extract 'rows' if available
      }

      // If data is empty, show a fallback message
      if (data == null || data.isEmpty) {
        return  Container(
          height:15,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'No trending data available.',
              style: TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      }

      // Limit the number of entries displayed
      final limitedData = data.take(_entryLimit).toList();

      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.blue[100],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Data Overview",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 10),
                  ...limitedData.map<Widget>((item) {
                    // Ensure 'keys', 'clicks', 'impressions', 'ctr', and 'position' are handled safely
                    final query = (item['keys'] != null && item['keys'].isNotEmpty) ? item['keys'][0] : 'N/A';
                    final clicks = item['clicks']?.toString() ?? 'N/A';
                    final impressions = item['impressions']?.toString() ?? 'N/A';
                    final ctr = (item['ctr'] != null) ? item['ctr'].toStringAsFixed(2) : 'N/A';
                    final position = (item['position'] != null) ? item['position'].toStringAsFixed(2) : 'N/A';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: [
                                  Text(
                                    'Query: ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    query,
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    'Clicks: ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    clicks,
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    'Impressions: ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    impressions,
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    'CTR: ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    ctr,
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    'Position: ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    position,
                                    style: TextStyle(fontFamily: 'Poppins'),
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
      );
    }



    // Determine which data to show based on the selected category
    dynamic _getDataForSelectedCategory() {
      switch (_selectedCategory) {
        case 'query':
          return queryData;
        case 'page':
          return pageData;
        case 'country':
          return countryData;
        case 'appearance':
          return appearanceData;
        case 'device':
          return deviceData;
        default:
          return [];
      }
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Button Row for selecting different categories
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
                    'Trending data',
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15),
                    bottomLeft:Radius.circular(15),
                  ),
                  color: Colors.blue[100],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Trending \n Parameters:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(height:35,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'query';
                                  });
                                },
                                child: Text(
                                  'Keywords',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4,),
                            Container(
                              height:35,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'page';
                                  });
                                },
                                child: Text(
                                  'Pages',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4,),
                            Container(
                              height:35,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'country';
                                  });
                                },
                                child: Text(
                                  'Countries',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4,),
                            Container(
                              height:35,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'appearance';
                                  });
                                },
                                child: Text(
                                  'Appearance',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4,),
                            Container(
                              height:35,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'device';
                                  });
                                },
                                child: Text(
                                  'Devices',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _buildDataView(_getDataForSelectedCategory()),
            ),
          ],
        ),
      ),
    );
  }
}
