import 'dart:convert';
import 'dart:ffi';
import 'package:dotphi_seo_app/model/login_model.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'leads_screen.dart';


class Group {
  final String name;
  final Color color;

  Group({required this.name, required this.color});
}

class GroupsScreen extends StatefulWidget {
  final Function()? onGroupUpdated;
  final String projectCode;
  final Map<String, dynamic> group;
  final String uniqueId;


  const GroupsScreen({super.key, required this.onGroupUpdated, required this.group,required this.projectCode, required this.uniqueId});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}
class _GroupsScreenState extends State<GroupsScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _groups = [];
  int contactedCount = 0;
  int uncontactedCount=0;
  List<Map<String, dynamic>> users = [];
  late Map<String, dynamic> _group;
  DateTime? _selectedFollowUpDate;
  List<dynamic> _users = [];
  Map<String, dynamic>? _expandedGroup;
  bool _isLoading = true;


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
  Future<void> fetchUsersInGroup(String projectUniqueCode, String groupId) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Define the request body for x-www-form-urlencoded
      Map<String, String> body = {
        'project_unique_code': projectUniqueCode,
        'group_id': groupId,
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/login/get_users_in_group'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the response indicates success and contains users
        if (responseData['status'] == 'success' && responseData['users'] is List) {
          setState(() {
            _users = responseData['users']; // Store fetched users in state
          });
          print('Fetched users: $_users'); // Display fetched users
        } else {
          print('Error fetching users: ${responseData['message']}');
        }
      } else {
        print('Failed to fetch users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors during the request
      print('An error occurred while fetching users: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _deleteGroup(String id) async {
    try {
      // Make API call to delete the group on the server
      final response = await http.post(
        Uri.parse('https://clients.dotphi.com/Api/login/delete_group'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'group_id': id},
      );

      // Check if the API call was successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          // Successfully deleted from server, proceed to delete from SharedPreferences

          final prefs = await SharedPreferences.getInstance();
          final groupsString = prefs.getString('groups') ?? '[]';
          final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));

          // Remove the group with the specified ID
          groups.removeWhere((group) => group['id'] == id);

          // Save the updated groups list back to SharedPreferences
          final updatedGroupsString = jsonEncode(groups);
          await prefs.setString('groups', updatedGroupsString);

          // Update the in-memory list
          setState(() {
            _groups = groups;
          });

          // Update user's group lists
          final userKeys = prefs.getKeys().where((key) => key.startsWith('groups_'));
          for (String userKey in userKeys) {
            List<String> userGroupNames = prefs.getStringList(userKey) ?? [];
            userGroupNames.removeWhere((groupName) => groupName == id);
            await prefs.setStringList(userKey, userGroupNames);
          }

          // Notify that data has been updated
          widget.onGroupUpdated?.call();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: Colors.blue.shade900,
          ));
        } else {
          // Show error from server response
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete group: ${responseData['message']}'),
            backgroundColor: Colors.red.shade900,
          ));
        }
      } else {
        // Show error if status code is not 200
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete group. Status code: ${response.statusCode}'),
          backgroundColor: Colors.red.shade900,
        ));
      }
    } catch (e) {
      // Handle any errors during the HTTP request
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred: $e'),
        backgroundColor: Colors.red.shade900,
      ));
    }
  }

  Future<void> _updateUserContactedStatus(String userId, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStatus = prefs.getBool('contacted_$userId') ?? false;

    if (currentStatus != status) {
      await prefs.setBool('contacted_$userId', status);
      await _updateContactedCounts(status, currentStatus);
    }
  }
  Future<void> _updateContactedCounts(bool newStatus, bool oldStatus) async {
    final prefs = await SharedPreferences.getInstance();
    int contactedCount = prefs.getInt('contacted_count') ?? 0;
    int uncontactedCount = prefs.getInt('uncontacted_count') ?? 0;

    if (newStatus && !oldStatus) {
      // User was previously uncontacted and is now contacted
      contactedCount++;
      uncontactedCount--;
    } else if (!newStatus && oldStatus) {
      // User was previously contacted and is now uncontacted
      contactedCount--;
      uncontactedCount++;
    }

    await prefs.setInt('contacted_count', contactedCount);
    await prefs.setInt('uncontacted_count', uncontactedCount);

    // Update the local state
    setState(() {
      this.contactedCount = contactedCount;
      this.uncontactedCount = uncontactedCount;
    });
  }
  void _loadGroupUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('groups') ?? '[]';
    final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));

    // Find the group to refresh
    final updatedGroup = groups.firstWhere((group) => group['id'] == _group['id'], orElse: () => _group);
    setState(() {
      _group = updatedGroup;
      users = List<Map<String, dynamic>>.from(_group['users'] ?? []);
    });
  }
  void _groupOptionsBottomSheet(BuildContext context, String groupId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                  child: Center(
                    child: Text(
                      "Group Options",
                      style: TextStyle(color: Colors.blue.shade900,fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(15)
                ),
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.white),
                  title: Text(
                    'Edit group details',
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                  ),
                  // onTap: () {
                  //   Navigator.pop(context); // Close the modal sheet
                  //   _navigateToEditGroupPage();
                  // },
                ),
              ),
              SizedBox(height: 10,),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close the modal sheet
                  _showDeleteConfirmationDialog(context, groupId);
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: ListTile(
                    leading: Icon(Icons.delete, color:  Colors.white),
                    title: Text(
                      'Delete group',
                      style: TextStyle(color:  Colors.white,fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25,)
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String groupId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Confirm Deletion',style: TextStyle(fontFamily: 'Poppins',fontSize: 20,color: Colors.blue.shade900),)),
          content: Text('Are you sure you want to delete this group? This action cannot be undone.',style: TextStyle(fontFamily: 'Poppins')),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',style: TextStyle(fontFamily: 'Poppins',color: Colors.blue.shade900),),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete',style: TextStyle(fontFamily: 'Poppins',color: Colors.blue.shade900),),
              onPressed: () async {
                await _deleteGroup(groupId);
                Navigator.of(context).pop(); // Close the dialog
                _loadGroups(widget.projectCode);
                // Navigator.of(context).pop(true); // Navigate back to the GroupsPage and pass true to indicate deletion
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _postFollowUpDate(String uniqueId, String seoId, DateTime followupDate) async {
    final url1 = 'https://clients.dotphi.com/Api/login/lead'; // First API URL
    final url2 = 'https://clients.dotphi.com/Api/Login/livechat'; // Second API URL
    final url3 = 'https://clients.dotphi.com/Api/login/paid_lead'; // Third API URL

    // Format the date as 'dd-MM-yyyy'
    String formattedDate = DateFormat('dd-MM-yyyy').format(followupDate);

    // Construct the x-www-form-urlencoded request body for the first API (lead)
    String requestBody1 = 'unique_id=${Uri.encodeQueryComponent(uniqueId)}'
        '&seo_id=${Uri.encodeQueryComponent(seoId)}'
        '&followup=${Uri.encodeQueryComponent(formattedDate)}';

    print('Request body 1: $requestBody1'); // Log the request body for the first API

    // First API call (lead)
    final response1 = await http.post(
      Uri.parse(url1),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: requestBody1, // Pass the encoded body for the first API
    );

    print('Response 1 status code: ${response1.statusCode}'); // Log the response status code for the first API
    print('Response 1 body: ${response1.body}'); // Log the response body for the first API

    if (response1.statusCode == 200) {
      // Handle success for the first API
      print('Follow-up date posted successfully for the first API: ${response1.body}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Follow-up date changed successfully to ${formattedDate}", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ));

      // Save follow-up date in SharedPreferences based on seoId for the first API
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('followup_date_$seoId', formattedDate);

      // Second API call (livechat)
      String requestBody2 = 'unique_id=${Uri.encodeQueryComponent(uniqueId)}'
          '&seo_id=${Uri.encodeQueryComponent(seoId)}'
          '&followup_updated=${Uri.encodeQueryComponent(formattedDate)}';

      print('Request body 2: $requestBody2'); // Log the request body for the second API

      final response2 = await http.post(
        Uri.parse(url2),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody2, // Pass the encoded body for the second API
      );

      print('Response 2 status code: ${response2.statusCode}'); // Log the response status code for the second API
      print('Response 2 body: ${response2.body}'); // Log the response body for the second API

      if (response2.statusCode == 200) {
        // Handle success for the second API
        print('Second API call succeeded: ${response2.body}');
      } else {
        // Handle failure for the second API
        print('Failed to call second API: ${response2.body}');
      }

      // Third API call (paid_lead)
      String requestBody3 = 'unique_id=${Uri.encodeQueryComponent(uniqueId)}'
          '&seo_id=${Uri.encodeQueryComponent(seoId)}'
          '&followup_date=${Uri.encodeQueryComponent(formattedDate)}';

      print('Request body 3: $requestBody3'); // Log the request body for the third API

      final response3 = await http.post(
        Uri.parse(url3),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody3, // Pass the encoded body for the third API
      );

      print('Response 3 status code: ${response3.statusCode}'); // Log the response status code for the third API
      print('Response 3 body: ${response3.body}'); // Log the response body for the third API

      if (response3.statusCode == 200) {
        // Handle success for the third API
        print('Third API call succeeded: ${response3.body}');
      } else {
        // Handle failure for the third API
        print('Failed to call third API: ${response3.body}');
      }
    } else {
      // Handle failure for the first API
      print('Failed to post follow-up date to the first API: ${response1.body}');
    }
  }


  Future<void> _navigateToEditGroupPage(Map<String, dynamic> group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupPage(
          groupId: group['id'],
          initialName: group['name'],
          initialColor: Color(group['color']),
        ),
      ),
    );

    if (result == true) {
      setState(() {
        // Reload or update the groups list
        _loadGroups(widget.projectCode);
      });
    }
  }
  void _userOptionDialog(BuildContext context, String projectUniqueCode, String groupId, String paidId,String username) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Options",
              style: TextStyle(color: Colors.blue.shade900,fontFamily: 'Poppins',fontSize: 20),
            ),
          ),
          titlePadding: EdgeInsets.all(15),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: ListTile(
                    leading: Icon(Icons.close, color: Colors.white),
                    title: Text(
                      'Edit follow up date',
                      style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      String username = projectUniqueCode ?? '';
                      String uniqueId = widget.uniqueId?? '';
                      String seoId =paidId ?? '';

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
                           Navigator.pop(context);
                            },
                        _postFollowUpDate, // Pass the post function here
                      );

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
                    leading: Icon(Icons.perm_contact_cal_sharp, color: Colors.white),
                    title: Text(
                      'Remove from group',
                      style: TextStyle( color:Colors.white,fontFamily: 'Poppins'),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      print(projectUniqueCode);
                      print(groupId);
                      print(paidId);// Close the dialog

                      // Call the delete confirmation dialog with required parameters
                      _showDeleteUserConfirmationDialog(
                        context,
                        projectUniqueCode,
                        groupId,
                        paidId,
                      );
                    },
                  ),
                ),
                SizedBox(height: 25,)
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _showDeleteUserConfirmationDialog(
      BuildContext context,
      String projectUniqueCode,
      String groupId,
      String paidId
      ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this user? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                // Call deleteUser with the required parameters
                await deleteUser(projectUniqueCode, groupId, paidId);
                Navigator.of(context).pop(); // Close the dialog

              },
            ),
          ],
        );
      },
    );
  }


  Future<void> deleteUser(String projectUniqueCode, String groupId, String paidId) async {
    try {
      // API endpoint URL
      final url = Uri.parse('https://clients.dotphi.com/Api/login/remove_user_from_group');
      print(projectUniqueCode);
      print(groupId);
      print(paidId);

      // POST request with the necessary parameters
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'project_unique_code': projectUniqueCode,
          'group_id': groupId,
          'paid_id': paidId,
        },
      );

      // Log the response body for debugging
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      // Parse the response
      final responseData = jsonDecode(response.body);

      // Check if deletion was successful based on the API's response
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User removed successfully from group $groupId'),backgroundColor: Colors.blue.shade900,),
        );
        fetchUsersInGroup(projectUniqueCode,groupId);
      } else {
        // Show error message from API response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove user: ${responseData['message'] ?? 'Unknown error'}'),backgroundColor: Colors.red,),
        );
      }
    } catch (e) {
      // Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing user: $e'),backgroundColor: Colors.red,),
      );
    }
  }




  Future<void> _saveFollowUpDate(String userName, DateTime date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('follow_up_date_$userName', date.toIso8601String());

    // Format the date to dd/MM/yyyy
    String formattedDate = DateFormat('dd/MM/yyyy').format(date);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Follow up scheduled on $formattedDate'),
        backgroundColor: Colors.blue.shade900,
      ),
    );
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
                      color:
                           Colors.white,
                      fontFamily: 'Poppins',


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
                          "Schedule follow-up for $username",
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
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.blue.shade900,
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

  void _showCalendarBottomSheet(BuildContext context, Function(DateTime) onDateSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Column(
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
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                  child: Text(
                    "Select a date",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                  onDateChanged: (date) {
                    Navigator.pop(context);
                    onDateSelected(date);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _onGroupUpdated() {
    widget.onGroupUpdated?.call();
  }
  Future<void> _toggleGroup(Map<String, dynamic> group) async {
    setState(() {
      if (_expandedGroup == group) {
        _expandedGroup = null; // Collapse if the same group is tapped
        _users = []; // Clear users list when collapsing
      } else {
        _expandedGroup = group; // Expand the selected group
        _isLoading = true; // Start loading
      }
    });

    // Fetch users only if expanding
    if (_expandedGroup != null) {
      await fetchUsersInGroup(widget.projectCode, group['group_id'].toString());
      setState(() {
        _isLoading = false; // Stop loading once data is fetched
      });
    }
  }






  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGroups(widget.projectCode);
    _group = widget.group;
    _loadGroupUsers();
  }
  @override
  void didUpdateWidget(covariant GroupsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group != oldWidget.group) {
      setState(() {
        _group = widget.group;
        _loadGroupUsers();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadGroups(widget.projectCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/groups.png',
              height:60 ,width: 60,),
            Text(
              'Groups',
              style: TextStyle(
                fontSize: 24, fontFamily: 'Poppins',
                fontWeight: FontWeight.bold, color: Colors.blue[900],
              ),
            ),
          ],
        )
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          _groups.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Add Groups to show',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
              : _isLoading // Check loading state
              ? Center(child: SpinKitCircle(color: Colors.blue.shade900,)) // Show loader
              :Expanded(
            child: ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                final isExpanded = _expandedGroup == group;
                return Column(
                  children: [
                    // Group Container
                    Container(
                      height: 50,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      margin: const EdgeInsets.only(top: 8.0, left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
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
                          Image.asset(
                            'assets/images/group.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              group['group_name'],
                              style: const TextStyle(fontSize: 15.0, color: Colors.black, fontFamily: 'Poppins'),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleGroup(group),
                            child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                          ),
                          const SizedBox(width: 19),
                          GestureDetector(
                            onTap: () =>
                                _groupOptionsBottomSheet(context, group['group_id']),
                            child: const Icon(Icons.more_vert, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    // Expanded Users List or Loader
                    if (isExpanded)
                      _isLoading
                          ? CircularProgressIndicator()
                          : Container(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                        margin: const EdgeInsets.only(top:1,left: 10, right: 10),
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
                        child: Column(
                          children: _users.map<Widget>((user) {
                            // Extract user details
                            final userName = user['seo_user_name'] ?? user['paid_user_name'] ?? user['live_user_name'] ?? 'Unknown User';
                            final paidId = user['seo_id'] ?? user['paid_id'] ?? user['live_id'];

                            // Define the image path based on conditions
                            String imagePath;
                            if (user['seo_id'] != null && user['seo_id'] != '0') {
                              imagePath = 'assets/images/email.gif'; // Email GIF for seo_id
                            } else if (user['paid_id'] != null && user['paid_id'] != '0') {
                              imagePath = 'assets/images/advertising.gif'; // Notification GIF for paid_id
                            } else if (user['live_id'] != null && user['live_id'] != '0') {
                              imagePath = 'assets/images/chatleads.gif'; // Live leads GIF for live_id
                            } else {
                              imagePath = 'assets/images/default.gif'; // Default GIF
                            }

                            // Construct the row
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  // Image
                                  Image.asset(
                                    imagePath,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 10), // Spacing between image and text

                                  // User name and creation date
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(DateTime.parse(user['created_at'])),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // More options icon
                                  IconButton(
                                    onPressed: () => _userOptionDialog(
                                      context,
                                      user['project_unique_code'],
                                      group['group_id'],
                                      paidId,
                                      userName,
                                    ),
                                    icon: const Icon(Icons.more_vert, color: Colors.black),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                      ),
                  ],
                );
              },
            ),
          )

        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newGroup = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroupPage(
                onGroupCreated: _onGroupUpdated, projectUniqueCode: widget.projectCode, // Pass callback to CreateGroupPage
              ),
            ),

          );
          _loadGroups(widget.projectCode);

          if (newGroup != null) {
            _onGroupUpdated();
          }
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue.shade900,
      ),
    );
  }
}

class CreateGroupPage extends StatefulWidget {
  String projectUniqueCode;
  final VoidCallback onGroupCreated;
  CreateGroupPage({required this.onGroupCreated, required this.projectUniqueCode});
  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}
class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  Future<void> _saveGroup(String name, Color color, String projectUniqueCode) async {
    final url = Uri.parse('https://clients.dotphi.com/Api/login/create_group');

    // Prepare the body data for the API
    Map<String, String> body = {
      'group_name': name,
      'color': color.value.toString(), // Pass color as a string
      'project_unique_code': projectUniqueCode, // Add the project unique code
    };

    // Call the API
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: body,
    );

    if (response.statusCode == 200) {
      // Handle success (you can process response data here if needed)
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'success') {
        print("Group created successfully");
      } else {
        print("Failed to create group: ${responseData['message']}");
      }
    } else {
      // Handle error
      print("Failed to create group. Status code: ${response.statusCode}");
    }
  }

  Widget buildColorPicker({
    required Color selectedColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    final List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
    ];

    return Container(
      height: 200.0, // Set a fixed height or use constraints
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: colors.length,
        itemBuilder: (BuildContext context, int index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () {
              onColorChanged(color);
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(50.0),
                border: Border.all(
                  color: selectedColor == color ? Colors.black : Colors.transparent,
                  width: 2.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create New Group",
          style: TextStyle(
            fontSize: 24, fontFamily: 'Poppins',
            fontWeight: FontWeight.bold, color: Colors.blue[900],
          ),
        ),
      ),
      body:
           Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: [
                          Text("GROUP NAME:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                            fontFamily:
                            'Poppins',
                          ),),
                          SizedBox(width: 2),
                          Expanded(
                      child: TextField(
                                  controller: _groupNameController,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none
                                      ),
                                      hintText: "Enter group name",
                                      labelStyle:TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily:
                                        'Poppins',
                                      ) ),
                      ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text('GROUP COLOR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily:
                        'Poppins',
                      ),),
                      SizedBox(height: 10),
                      buildColorPicker(
                        selectedColor: _selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                      _selectedColor = color;
                          });
                        },
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          final groupName = _groupNameController.text;
                          print('widget.projectUniqueCode');
                          print(widget.projectUniqueCode);
                          if (groupName.isNotEmpty) {
                            await _saveGroup(groupName,_selectedColor,widget.projectUniqueCode);
                            widget.onGroupCreated(); // Invoke the callback
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)
                          )
                        ),
                        child: Text('Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily:
                          'Poppins',
                        ),),
                      ),
                    ],
            ),
          ),


       )
    ;}
}
class EditGroupPage extends StatefulWidget {
  final String groupId;
  final String initialName;
  final Color initialColor;

  EditGroupPage({
    required this.groupId,
    required this.initialName,
    required this.initialColor,

  });

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}
class _EditGroupPageState extends State<EditGroupPage> {
  final _groupNameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _groupNameController.text = widget.initialName;
    _selectedColor = widget.initialColor;
  }

  Future<void> _updateGroup(String id, String name, Color color) async {
    final url = Uri.parse('https://clients.dotphi.com/Api/login/update_group');

    // Prepare the request body
    final Map<String, String> body = {
      'group_id': id,
      'group_name': name,
      'color': color.value.toString(), // Send the color as a string
    };

    try {
      // Make the POST request with x-www-form-urlencoded content type
      final response = await http.post(
        url,
        body: body, // Send the body as x-www-form-urlencoded
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      // Check the response status
      if (response.statusCode == 200) {
        // Request was successful, update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final groupsString = prefs.getString('groups') ?? '[]';
        final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));

        // Find the group to update
        final groupIndex = groups.indexWhere((group) => group['id'] == id);
        if (groupIndex != -1) {
          groups[groupIndex] = {
            'id': id,
            'name': name,
            'color': color.value,
          };

          // Save the updated groups list back to SharedPreferences
          final updatedGroupsString = jsonEncode(groups);
          await prefs.setString('groups', updatedGroupsString);
        }
      } else {
        // Handle error response
        print('Failed to update group. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the request
      print('Error updating group: $e');
    }
  }


  Widget buildColorPicker({
    required Color selectedColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    final List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
    ];

    return Container(
      height: 200.0,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: colors.length,
        itemBuilder: (BuildContext context, int index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () {
              onColorChanged(color);
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(50.0),
                border: Border.all(
                  color: selectedColor == color ? Colors.black : Colors.transparent,
                  width: 2.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Group',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
            fontFamily:
            'Poppins',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter group name',
                hintStyle: TextStyle(fontFamily:
                'Poppins',),
                labelText: 'Group Name',
                labelStyle:TextStyle(fontFamily:
                'Poppins',),
              ),
            ),
            SizedBox(height: 20),
            Text('Select Group Color',
            style: TextStyle(fontFamily:
            'Poppins',),),
            SizedBox(height: 10),
            buildColorPicker(
              selectedColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
              ),
              onPressed: () async {
                final groupName = _groupNameController.text;
                if (groupName.isNotEmpty) {
                  await _updateGroup(widget.groupId, groupName, _selectedColor);
                  Navigator.pop(context, true); // Indicate that data has changed
                }
              },
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white,fontFamily:
                'Poppins',),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class GroupDetailsPage extends StatefulWidget {
//   final Map<String, dynamic> group;
//   final Function()? onGroupUpdated;
//
//
//
//   GroupDetailsPage({
//     required this.group,
//     this.onGroupUpdated,
//   });
//
//   @override
//   State<GroupDetailsPage> createState() => _GroupDetailsPageState();
// }
// class _GroupDetailsPageState extends State<GroupDetailsPage> {
//   List<Map<String, dynamic>> users = [];
//   late Map<String, dynamic> _group;
//   DateTime? _selectedDate;
//   String? _selectedOption;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _group = widget.group;
//     _loadGroupUsers();
//   }
//   @override
//   void didUpdateWidget(covariant GroupDetailsPage oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.group != oldWidget.group) {
//       setState(() {
//         _group = widget.group;
//         _loadGroupUsers();
//       });
//     }
//   }
//   @override
//   void didPopNext() {
//     // Refresh group details when returning from EditGroupPage
//     _loadGroupUsers();
//   }
//   void _loadGroupUsers() async {
//     final prefs = await SharedPreferences.getInstance();
//     final groupsString = prefs.getString('groups') ?? '[]';
//     final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));
//
//     // Find the group to refresh
//     final updatedGroup = groups.firstWhere((group) => group['id'] == _group['id'], orElse: () => _group);
//     setState(() {
//       _group = updatedGroup;
//       users = List<Map<String, dynamic>>.from(_group['users'] ?? []);
//     });
//   }
//   Future<void> _deleteGroup(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final groupsString = prefs.getString('groups') ?? '[]';
//     final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));
//
//     // Remove the group with the specified ID
//     groups.removeWhere((group) => group['id'] == id);
//
//     // Save the updated groups list back to SharedPreferences
//     final updatedGroupsString = jsonEncode(groups);
//     await prefs.setString('groups', updatedGroupsString);
//
//     // Notify that data has been updated
//     widget.onGroupUpdated?.call();
//   }
//   Future<void> _showDeleteConfirmationDialog(BuildContext context, String groupId) async {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Confirm Deletion'),
//           content: Text('Are you sure you want to delete this group? This action cannot be undone.'),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () async {
//                 await _deleteGroup(groupId);
//                 Navigator.of(context).pop(); // Close the dialog
//                 Navigator.of(context).pop(true); // Navigate back to the GroupsPage and pass true to indicate deletion
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//   void _groupOptionsBottomSheet(BuildContext context, String groupId) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade900,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(10),
//                     topRight: Radius.circular(10),
//                   ),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
//                   child: Text(
//                     "Group Options",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//               ListTile(
//                 leading: Icon(Icons.edit, color: Colors.blue.shade900),
//                 title: Text(
//                   'Edit group details',
//                   style: TextStyle(color: Colors.blue.shade900),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context); // Close the modal sheet
//                   _navigateToEditGroupPage();
//                 },
//               ),
//               Divider(),
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pop(context); // Close the modal sheet
//                   _showDeleteConfirmationDialog(context, groupId);
//                 },
//                 child: ListTile(
//                   leading: Icon(Icons.delete, color: Colors.blue.shade900),
//                   title: Text(
//                     'Delete group',
//                     style: TextStyle(color: Colors.blue.shade900),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   Future<void> _navigateToEditGroupPage() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EditGroupPage(
//           groupId: _group['id'],
//           initialName: _group['name'],
//           initialColor: Color(_group['color']),
//         ),
//       ),
//     );
//     if (result == true) {
//       _loadGroupUsers(); // Refresh users list if needed
//     }
//   }
//   void _userOptionSheet(BuildContext context, Map<String, dynamic> user) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 height: 50,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
//                   child: Text(
//                     "Options",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade900,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(10),
//                     topRight: Radius.circular(10),
//                   ),
//                 ),
//               ),
//               ListTile(
//                 leading: Icon(FontAwesomeIcons.paperPlane, color: Colors.blue.shade900),
//                 title: Text(
//                   'Send Content',
//                   style: TextStyle(color: Colors.blue.shade900),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => InitialContentPage(user: user), // Pass the user data correctly
//                     ),
//                   );
//                 },
//               ),
//               Divider(),
//               ListTile(
//                 leading: Icon(Icons.close, color: Colors.blue.shade900),
//                 title: Text(
//                   'Edit follow up date',
//                   style: TextStyle(color: Colors.blue.shade900),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _followUpBottomSheet(
//                     context,
//                     user, // Pass the specific user object
//                         (selectedDate) {
//                       // Handle selected follow-up date for the user
//                       print('Follow-up date selected: $selectedDate for user: ${user['name']}');
//
//                       // Update the user’s follow-up date in your application state or UI
//                       // For example, you might want to refresh the user details or update the UI
//                     },
//                   );
//                 },
//               ),
//
//               Divider(),
//               ListTile(
//                 leading: Icon(Icons.perm_contact_cal_sharp, color: Colors.blue.shade900),
//                 title: Text(
//                   'Remove from group',
//                   style: TextStyle(color: Colors.blue.shade900),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context); // Close the modal sheet
//                   _showDeleteUserConfirmationDialog(context, user['name']);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   Future<void> _showDeleteUserConfirmationDialog(BuildContext context, String groupId) async {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Confirm Deletion'),
//           content: Text('Are you sure you want to delete this user? This action cannot be undone.'),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () async {
//                 await deleteUser(groupId);
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//   Future<void> deleteUser(String userName) async {
//     final prefs = await SharedPreferences.getInstance();
//     final groupsString = prefs.getString('groups') ?? '[]';
//     final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));
//     // Find the group by ID and remove the user from that group
//     for (var group in groups) {
//       if (group['id'] == _group['id']) {
//         group['users'].removeWhere((user) => user['name'] == userName);
//         break;
//       }
//     }
//     // Save the updated groups list back to SharedPreferences
//     final updatedGroupsString = jsonEncode(groups);
//     await prefs.setString('groups', updatedGroupsString);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User removed from group')));
//     // Update the UI
//     _loadGroupUsers();
//     // Notify listeners or update the UI if needed
//     widget.onGroupUpdated?.call();// Refresh the users list in the group
//   }
//   Future<void> _saveFollowUpDate(String userId, DateTime date) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('followUpDate_$userId', date.toIso8601String());
//   }
//   void _followUpBottomSheet(BuildContext context, Map<String, dynamic> user, Function(DateTime) onDateSelected) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             DateTime? _selectedDate; // Track the selected date
//
//             // Load the saved date for the specific user
//             void _loadSavedDate() async {
//               SharedPreferences prefs = await SharedPreferences.getInstance();
//               String? dateString = prefs.getString('followUpDate_${user['name']}');
//               if (dateString != null) {
//                 setState(() {
//                   _selectedDate = DateTime.parse(dateString);
//                 });
//               }
//             }
//
//             _loadSavedDate(); // Call the function to load the saved date
//
//             Widget _buildListTile(String title, DateTime? date, [String? option]) {
//               return ListTile(
//                 title: Text(
//                   title,
//                   style: TextStyle(
//                     color: _selectedDate == date ? Colors.white : Colors.blue.shade900,
//                   ),
//                 ),
//                 tileColor: _selectedDate == date ? Colors.blue.shade900 : null, // Change background color if selected
//                 onTap: () async {
//                   setState(() {
//                     _selectedDate = date; // Update selected date
//                   });
//                   if (user.isNotEmpty) { // Ensure the user object is not empty
//                     await _saveFollowUpDate(user['name'], date ?? DateTime.now()); // Save date for the specific user
//                     Navigator.pop(context);
//                     onDateSelected(date ?? DateTime.now()); // Pass the selected date to the callback
//                   } else {
//                     // Handle the case where the user object is empty
//                     print('User object is empty');
//                   }
//                 },
//               );
//             }
//
//             return Container(
//               height: MediaQuery.of(context).size.height * 0.4,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: MediaQuery.of(context).size.width,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade900,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(10),
//                         topRight: Radius.circular(10),
//                       ),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
//                       child: Text(
//                         "Schedule follow up for ${user['name']}",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           _buildListTile('Today', DateTime.now()),
//                           _buildListTile('Tomorrow', DateTime.now().add(Duration(days: 1))),
//                           _buildListTile('3 days from now', DateTime.now().add(Duration(days: 3))),
//                           _buildListTile('1 week from now', DateTime.now().add(Duration(days: 7))),
//                           _buildListTile('1 month from now', DateTime.now().add(Duration(days: 30))),
//                           ListTile(
//                             title: Text(
//                               'Select custom date and time',
//                               style: TextStyle(color: Colors.blue.shade900),
//                             ),
//                             onTap: () {
//                               Navigator.pop(context);
//                               _showCalendarBottomSheet(context, (date) async {
//                                 await _saveFollowUpDate(user['name'], date); // Save date for the specific user
//                                 onDateSelected(date); // Pass the selected date to the callback
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//   void _showCalendarBottomSheet(BuildContext context, Function(DateTime) onDateSelected) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.4,
//           child: Column(
//             children: [
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade900,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(10),
//                     topRight: Radius.circular(10),
//                   ),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
//                   child: Text(
//                     "Select a date",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: CalendarDatePicker(
//                   initialDate: DateTime.now(),
//                   firstDate: DateTime.now(),
//                   lastDate: DateTime.now().add(Duration(days: 365)),
//                   onDateChanged: (date) {
//                     Navigator.pop(context);
//                     onDateSelected(date);
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(_group['name'],
//             style: TextStyle(fontFamily:
//             'Poppins',),),
//             GestureDetector(
//               onTap: () {
//                 _groupOptionsBottomSheet(context,_group['id']);
//               },
//               child: Text(
//                 "Options",
//                 style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 14,fontFamily:
//                 'Poppins',),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView.builder(
//           itemCount: users.length,
//           itemBuilder: (context, index) {
//             final user = users[index];
//             return Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 color: Colors.white,
//                 boxShadow: [BoxShadow(
//                   color: Colors.grey.withOpacity(0.5),
//                   spreadRadius: 3,
//                   blurRadius: 5,
//                   offset: const Offset(0, 3),
//                 )],
//               ),
//               child: Column(
//                 children: [
//                   ListTile(
//                     leading: Image.asset(
//                       'assets/images/notification1.gif',
//                       width: 40,
//                       height: 40,
//                       fit: BoxFit.cover,
//                     ),
//                     title: Text(
//                       user['name'],
//                       style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     subtitle: Text(
//                       user['email'],
//                       style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey[600]),
//                     ),
//                     trailing: IconButton(
//                       onPressed: () {
//                         _userOptionSheet(context, user);
//                       },
//                       icon: Icon(Icons.more_vert, color: Colors.grey,),
//                     ),
//                   ),
//                   // SizedBox(height: 5,),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
class InitialContentPage extends StatefulWidget {
  final String user;

  InitialContentPage({required this.user});

  @override
  _InitialContentPageState createState() => _InitialContentPageState();
}

class _InitialContentPageState extends State<InitialContentPage> {
  List<Map<String, String>> _savedMessages = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  // Load saved messages from SharedPreferences
  Future<void> _loadContent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedTitles = prefs.getStringList('savedTitles');
    List<String>? savedMessages = prefs.getStringList('savedMessages');

    if (savedTitles != null && savedMessages != null) {
      setState(() {
        _savedMessages = List.generate(savedTitles.length, (index) {
          return {
            'title': savedTitles[index],
            'message': savedMessages[index],
          };
        });
      });
    }
  }

  // Navigate to the WriteContentPage
  void _navigateToWriteContent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WriteContentPage()),
    );
    _loadContent(); // Reload content after returning
  }

  // Navigate to ContentDetailPage
  void _navigateToContentDetail(Map<String, String> content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailPage(
          user: widget.user, // Pass the user data from the widget
          title: content['title']!,
          message: content['message']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Content Overview',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _savedMessages.isNotEmpty
                  ? ListView.builder(
                itemCount: _savedMessages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _navigateToContentDetail(_savedMessages[index]),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _savedMessages[index]['title']!,
                                  style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                ),
                                Text(
                                  _savedMessages[index]['message']!,
                                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_sharp),
                        ],
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Text(
                  'No content available. Create new content.',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToWriteContent,
                child: Text(
                  'Create New Content',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class WriteContentPage extends StatefulWidget {
  @override
  _WriteContentPageState createState() => _WriteContentPageState();
}

class _WriteContentPageState extends State<WriteContentPage> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _messageController = TextEditingController();

  Future<void> _saveContent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? savedTitles = prefs.getStringList('savedTitles') ?? [];
    List<String>? savedMessages = prefs.getStringList('savedMessages') ?? [];

    savedTitles.add(_titleController.text);
    savedMessages.add(_messageController.text);

    await prefs.setStringList('savedTitles', savedTitles);
    await prefs.setStringList('savedMessages', savedMessages);

    Navigator.pop(context); // Return to the previous page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Message Template',
          style: TextStyle(color: Colors.white,fontFamily:
          'Poppins',),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title',
            style: TextStyle(fontFamily:
            'Poppins',),),
            SizedBox(height: 5),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text('Template Message',style: TextStyle(fontFamily:
            'Poppins',),),
            SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                  ),
                  onPressed: _saveContent,
                  child: Text(
                    'Create Template',
                    style: TextStyle(color: Colors.white,fontFamily:
                    'Poppins'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContentDetailPage extends StatelessWidget {
  final String title;
  final String message;
  final String user;

  ContentDetailPage({
    required this.title,
    required this.message,
    required this.user,
  });

  // void _sendMessageViaWhatsApp() async {
  //   final phoneNumber = user['phone']; // Replace with the recipient's phone number in international format
  //   final encodedMessage = Uri.encodeComponent(message);
  //   final url = 'whatsapp://send?phone=$phoneNumber&text=$encodedMessage';
  //
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     // Handle the case where WhatsApp cannot be launched
  //     print('Could not launch WhatsApp');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  // padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      children: [
                        // Text(
                        //   'Sending message to ${user['name']}',
                        //   style: TextStyle(fontWeight: FontWeight.bold),
                        // ),
                        Text(
                          'Message:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // SizedBox(height: 8),
                        // Expanded(
                        //   child: Text(message),
                        // ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Center(
            // child: Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton.icon(
            //       onPressed: _sendMessageViaWhatsApp,
            //       icon: FaIcon(
            //         FontAwesomeIcons.whatsapp, // WhatsApp icon
            //         color: Colors.green,
            //       ),
            //       label: Text(
            //         'Send via WhatsApp',
            //         style: TextStyle(color: Colors.white),
            //       ),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.blue.shade900, // Background color
            //       ),
            //     ),
            //   ),
            // ),
          ),
        ],
      ),
    );
  }
}
