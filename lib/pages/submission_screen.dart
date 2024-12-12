import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  List<dynamic>? subTypeList; // To store the fetched data
  bool isLoading = true; // Track the loading state

  @override
  void initState() {
    super.initState();
    fetchSubTypeList(); // Call the API in initState
  }

  Future<void> fetchSubTypeList() async {
    const String apiUrl = 'https://clients.dotphi.com/Api/Login/sub_type_list';

    try {
      // Send a GET request to the API
      final response = await http.get(Uri.parse(apiUrl));

      // Check the response status code
      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = json.decode(response.body);

        // Ensure the expected format is used
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          setState(() {
            subTypeList = data['data']; // Access the 'data' field
            isLoading = false; // Data loaded successfully
          });
        } else {
          throw Exception('Unexpected JSON format');
        }
      } else {
        throw Exception(
            'Failed to load sub type list: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error fetching sub type list: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Submission Sites',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body:

      isLoading
          ? Center(child: SpinKitCircle(color: Colors.blue.shade900,)) // Show loader while loading
          : subTypeList != null && subTypeList!.isNotEmpty
          ? ListView.builder(
        itemCount: subTypeList!.length,
        itemBuilder: (context, index) {
          final item = subTypeList![index];
          final submissionName = item['submission_name'] ?? 'Unknown';
          final submissionId=item['submission_id']?? 'Unknown';// Safely access 'submission_name'

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 70, width: 360,
              // padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2, blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
                ],
              ),
              child: ListTile(
                title: Text(
                  submissionName,
                  style: TextStyle(fontWeight: FontWeight.w600,fontFamily: 'Poppins'),
                ), // Display 'submission_name'
                subtitle: Text('Status: ${item['status'] ?? 'N/A'}',style: TextStyle(fontFamily: 'Poppins'),),
                onTap: (){Navigator.push(context,MaterialPageRoute(builder: (context)=>SubmissionDetailsScreen(submissionName: submissionName, submissionId: submissionId,)));},
              ),
            ),
          );
        },
      )
          : Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.black, fontSize: 15,fontFamily: 'Poppins'),
        ),
      ),
    );
  }
}

class SubmissionDetailsScreen extends StatefulWidget {
  final String submissionName;
  final String submissionId;

  const SubmissionDetailsScreen({
    super.key,
    required this.submissionName,
    required this.submissionId,
  });

  @override
  State<SubmissionDetailsScreen> createState() => _SubmissionDetailsScreenState();
}

class _SubmissionDetailsScreenState extends State<SubmissionDetailsScreen> {
  List<dynamic>? submissionDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubmissionSiteList(widget.submissionId); // Call the API
  }

  Future<void> fetchSubmissionSiteList(String submissionId) async {
    const String apiUrl = 'https://clients.dotphi.com/Api/Login/sub_site_list';

    try {
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
      final body = {'submission_id': submissionId};

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          setState(() {
            submissionDetails = data['data'];
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected JSON format');
        }
      } else {
        throw Exception(
            'Failed to fetch submission site list: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching submission site list: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.submissionName),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : submissionDetails != null && submissionDetails!.isNotEmpty
          ? ListView.builder(
        itemCount: submissionDetails!.length,
        itemBuilder: (context, index) {
          final detail = submissionDetails![index];
          return ListTile(
            title: Text(detail['site_name'] ?? 'Unknown'),
            subtitle: Text(detail['status'] ?? 'N/A'),
          );
        },
      )
          : Center(
        child: Text(
          'No submission details available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
