import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SitemapDetailsScreen extends StatefulWidget {
  final List<dynamic> sitemaps;
  final String siteUrl;

  const SitemapDetailsScreen({required this.sitemaps, required this.siteUrl});

  @override
  State<SitemapDetailsScreen> createState() => _SitemapDetailsScreenState();
}

class _SitemapDetailsScreenState extends State<SitemapDetailsScreen> {
  // Helper function to format the date
  String formatDate(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A'; // Return 'N/A' if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container for "Sitemaps" title
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blue.shade900,
              ),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 8.0, top: 8.0, bottom: 8.0),
                child: Text(
                  'Sitemaps',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 18), // Spacer
            // Container for the site URL
            Container(
              alignment: Alignment.topLeft,
              child: Text(
                'URL: ${widget.siteUrl}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF4A261),
                ),
              ),
            ),
            SizedBox(height: 10), // Spacer
            // ListView for sitemaps
            Expanded(
              child: ListView.builder(
                itemCount: widget.sitemaps.length, // Accessing directly from widget.sitemaps
                itemBuilder: (context, index) {
                  final sitemap = widget.sitemaps[index]; // Accessing directly from widget.sitemaps

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.blue[100],
                    ),
                    child: ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Last Submitted:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' ${formatDate(sitemap['lastSubmitted'] ?? 'N/A')}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Last Downloaded:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' ${formatDate(sitemap['lastDownloaded'] ?? 'N/A')}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Warnings:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' ${sitemap['warnings'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Errors:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' ${sitemap['errors'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          if (sitemap['contents'] != null && sitemap['contents'] is List)
                            ...sitemap['contents'].map<Widget>((content) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Content Type:',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        ' ${content['type'] ?? 'N/A'} ',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Submitted:',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        ' ${content['submitted'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Indexed:',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        ' ${content['indexed'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
