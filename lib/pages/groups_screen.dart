import 'dart:convert';
import 'dart:ffi';
import 'package:dotphi_seo_app/model/login_model.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

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


  const GroupsScreen({super.key, required this.onGroupUpdated, required this.group,required this.projectCode});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}
class _GroupsScreenState extends State<GroupsScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _groups = [];
  int contactedCount = 0;
  int uncontactedCount=0;
  List<Map<String, dynamic>> users = [];
  late Map<String, dynamic> _group;
  DateTime? _selectedDate;
  String? _selectedOption;
  Map<String, dynamic>? _expandedGroup;


  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('groups') ?? '[]';
    print('Groups loaded: $groupsString'); // Debug print
    setState(() {
      _groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));
    });
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
  Future<void> _deleteGroup(String id) async {
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
  }
  Future<void> _showDeleteConfirmationDialog(BuildContext context, String groupId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this group? This action cannot be undone.'),
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
                await _deleteGroup(groupId);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(true); // Navigate back to the GroupsPage and pass true to indicate deletion
              },
            ),
          ],
        );
      },
    );
  }
  void _groupOptionsBottomSheet(BuildContext context, Map<String, dynamic> group) {
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
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                  child: Text(
                    "Group Options",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue.shade900),
                title: Text(
                  'Edit group details',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the modal sheet
                  _navigateToEditGroupPage(group); // Pass the group data to the function
                },
              ),
              Divider(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close the modal sheet
                  _showDeleteConfirmationDialog(context, group['id']); // Pass the group ID to the function
                },
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.blue.shade900),
                  title: Text(
                    'Delete group',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        _loadGroups();
      });
    }
  }
  void _userOptionDialog(BuildContext context, Map<String, dynamic> group, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Options",
            style: TextStyle(color: Colors.blue.shade900),
          ),
          titlePadding: EdgeInsets.all(15),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(FontAwesomeIcons.paperPlane, color: Colors.blue.shade900),
                title: Text(
                  'Send Content',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitialContentPage(user: user), // Pass the user data correctly
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.close, color: Colors.blue.shade900),
                title: Text(
                  'Edit follow up date',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _followUpBottomSheet(
                    context,
                    user, // Pass the specific user object
                        (selectedDate) {
                      // Handle selected follow-up date for the user
                      print('Follow-up date selected: $selectedDate for user: ${user['name']}');

                      // Update the user’s follow-up date in your application state or UI
                      // For example, you might want to refresh the user details or update the UI
                    },
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.perm_contact_cal_sharp, color: Colors.blue.shade900),
                title: Text(
                  'Remove from group',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the dialog
                  _showDeleteUserConfirmationDialog(context, group, user['name']);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _showDeleteUserConfirmationDialog(BuildContext context, Map<String, dynamic> group, String userName) async {
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
                await deleteUser(group, userName);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> deleteUser(Map<String, dynamic> group, String userName) async {
    setState(() {
      // Remove the user from the selected group's user list
      group['users'].removeWhere((user) => user['name'] == userName);
    });

    // Save the updated groups back to SharedPreferences if needed
    final prefs = await SharedPreferences.getInstance();
    final updatedGroupsString = jsonEncode(_groups);
    await prefs.setString('groups', updatedGroupsString);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$userName removed from ${group['name']}')),
    );
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
  void _followUpBottomSheet(BuildContext context, Map<String, dynamic> user, Function(DateTime) onDateSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            DateTime? _selectedDate; // Track the selected date

            // Load the saved date for the specific user
            void _loadSavedDate() async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? dateString = prefs.getString('followUpDate_${user['name']}');
              if (dateString != null) {
                setState(() {
                  _selectedDate = DateTime.parse(dateString);
                });
              }
            }

            _loadSavedDate(); // Call the function to load the saved date

            Widget _buildListTile(String title, DateTime? date, [String? option]) {
              return ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    color: _selectedDate == date ? Colors.white : Colors.blue.shade900,
                  ),
                ),
                tileColor: _selectedDate == date ? Colors.blue.shade900 : null, // Change background color if selected
                onTap: () async {
                  setState(() {
                    _selectedDate = date; // Update selected date
                  });
                  if (user.isNotEmpty) { // Ensure the user object is not empty
                    await _saveFollowUpDate(user['name'], date ?? DateTime.now()); // Save date for the specific user
                    Navigator.pop(context);
                    onDateSelected(date ?? DateTime.now()); // Pass the selected date to the callback
                  } else {
                    // Handle the case where the user object is empty
                    print('User object is empty');
                  }
                },
              );
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
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                      child: Text(
                        "Schedule follow up for ${user['name']}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildListTile('Today', DateTime.now()),
                          _buildListTile('Tomorrow', DateTime.now().add(Duration(days: 1))),
                          _buildListTile('3 days from now', DateTime.now().add(Duration(days: 3))),
                          _buildListTile('1 week from now', DateTime.now().add(Duration(days: 7))),
                          _buildListTile('1 month from now', DateTime.now().add(Duration(days: 30))),
                          ListTile(
                            title: Text(
                              'Select custom date and time',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showCalendarBottomSheet(context, (date) async {
                                await _saveFollowUpDate(user['name'], date); // Save date for the specific user
                                onDateSelected(date); // Pass the selected date to the callback
                              });
                            },
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
    _loadGroups();
    widget.onGroupUpdated?.call();
  }
  void _toggleGroup(Map<String, dynamic> group) {
    setState(() {
      if (_expandedGroup == group) {
        _expandedGroup = null; // Collapse if the same group is tapped
      } else {
        _expandedGroup = group; // Expand the selected group
      }
    });
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGroups();
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
    _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
        mainAxisSize: MainAxisSize.min,
        children: 'Groups'.split('').map((letter) {
      int fontSize = 35 - 'Groups'.indexOf(letter) * 4;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: fontSize.toDouble(),
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
            fontFamily:
            'Poppins',
          ),
        ),
       );
        }).toList(),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SizedBox(height: 20,),
          _groups.isEmpty?Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(width:double.infinity,
                decoration:BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Add Groups to show',style: TextStyle(fontSize: 15,color: Colors.white, fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,),),
            )),
          ): Container(
            child: Expanded(
              child: ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  final isExpanded = _expandedGroup == group;
              
                  return Column(
                    children: [
                      Container(
                        height: 50,
                        width: double.infinity, // Use double.infinity to take up full width
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                        margin: EdgeInsets.only(top: 8.0,left:10,right:10),
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
                            Icon(Icons.group, color: Color(group['color'])),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                group['name'],
                                style: const TextStyle(fontSize: 15.0, color: Colors.black,fontFamily:
                                'Poppins',),
                              ),
                            ),
                            SizedBox(width:150,),
                            GestureDetector(
                              onTap: () => _toggleGroup(group), // Call the _toggleGroup function when tapped
                              child: isExpanded
                                  ? Icon(Icons.keyboard_arrow_up)
                                  : Icon(Icons.keyboard_arrow_down),
                            ),
                            const SizedBox(width: 19),
                            Text('${group['users']?.length ?? 0}',style: TextStyle(fontFamily:
                            'Poppins',),),
                            SizedBox(width: 10,),
                            GestureDetector(
                                onTap:(){
                                  _groupOptionsBottomSheet(context, group);
                                },
                                child: const Icon(Icons.more_vert,color:Colors.black))
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          margin:EdgeInsets.symmetric(horizontal:10),
                          decoration:BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            boxShadow: [BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            )],
                          ),
                          child: Column(
                            children: group['users']!.map<Widget>((user) {
                              return ListTile(
                                leading: Image.asset(
                                  'assets/images/notification1.gif',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  user['name'],
                                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16,),
                                ),
                                subtitle: Text(
                                  user['email'],
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey[600]),
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    _userOptionDialog(context, group, user);
                                  },
                                  icon: Icon(Icons.more_vert, color: Colors.grey,),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newGroup = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroupPage(
                onGroupCreated: _onGroupUpdated, // Pass callback to CreateGroupPage
              ),
            ),
          );

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
  final VoidCallback onGroupCreated;
  CreateGroupPage({required this.onGroupCreated});
  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}
class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  Future<void> _saveGroup(String name, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('groups') ?? '[]';
    final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));

    groups.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'color': color.value,
      'users': []
    });

    final updatedGroupsString = jsonEncode(groups);
    await prefs.setString('groups', updatedGroupsString);
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
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
            fontFamily:
            'Poppins',
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
                          if (groupName.isNotEmpty) {
                            await _saveGroup(groupName, _selectedColor);
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
        'users': groups[groupIndex]['users'], // Preserve existing users
      };

      // Save the updated groups list back to SharedPreferences
      final updatedGroupsString = jsonEncode(groups);
      await prefs.setString('groups', updatedGroupsString);
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

class GroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final Function()? onGroupUpdated;



  GroupDetailsPage({
    required this.group,
    this.onGroupUpdated,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}
class _GroupDetailsPageState extends State<GroupDetailsPage> {
  List<Map<String, dynamic>> users = [];
  late Map<String, dynamic> _group;
  DateTime? _selectedDate;
  String? _selectedOption;


  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadGroupUsers();
  }
  @override
  void didUpdateWidget(covariant GroupDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group != oldWidget.group) {
      setState(() {
        _group = widget.group;
        _loadGroupUsers();
      });
    }
  }
  @override
  void didPopNext() {
    // Refresh group details when returning from EditGroupPage
    _loadGroupUsers();
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
  Future<void> _deleteGroup(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('groups') ?? '[]';
    final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));

    // Remove the group with the specified ID
    groups.removeWhere((group) => group['id'] == id);

    // Save the updated groups list back to SharedPreferences
    final updatedGroupsString = jsonEncode(groups);
    await prefs.setString('groups', updatedGroupsString);

    // Notify that data has been updated
    widget.onGroupUpdated?.call();
  }
  Future<void> _showDeleteConfirmationDialog(BuildContext context, String groupId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this group? This action cannot be undone.'),
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
                await _deleteGroup(groupId);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(true); // Navigate back to the GroupsPage and pass true to indicate deletion
              },
            ),
          ],
        );
      },
    );
  }
  void _groupOptionsBottomSheet(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                  child: Text(
                    "Group Options",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue.shade900),
                title: Text(
                  'Edit group details',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the modal sheet
                  _navigateToEditGroupPage();
                },
              ),
              Divider(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close the modal sheet
                  _showDeleteConfirmationDialog(context, _group['id']);
                },
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.blue.shade900),
                  title: Text(
                    'Delete group',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _navigateToEditGroupPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupPage(
          groupId: _group['id'],
          initialName: _group['name'],
          initialColor: Color(_group['color']),
        ),
      ),
    );
    if (result == true) {
      _loadGroupUsers(); // Refresh users list if needed
    }
  }
  void _userOptionSheet(BuildContext context, Map<String, dynamic> user) {
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
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                  child: Text(
                    "Options",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(FontAwesomeIcons.paperPlane, color: Colors.blue.shade900),
                title: Text(
                  'Send Content',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitialContentPage(user: user), // Pass the user data correctly
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.close, color: Colors.blue.shade900),
                title: Text(
                  'Edit follow up date',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _followUpBottomSheet(
                    context,
                    user, // Pass the specific user object
                        (selectedDate) {
                      // Handle selected follow-up date for the user
                      print('Follow-up date selected: $selectedDate for user: ${user['name']}');

                      // Update the user’s follow-up date in your application state or UI
                      // For example, you might want to refresh the user details or update the UI
                    },
                  );
                },
              ),

              Divider(),
              ListTile(
                leading: Icon(Icons.perm_contact_cal_sharp, color: Colors.blue.shade900),
                title: Text(
                  'Remove from group',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the modal sheet
                  _showDeleteUserConfirmationDialog(context, user['name']);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _showDeleteUserConfirmationDialog(BuildContext context, String userName) async {
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
                await deleteUser(userName);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> deleteUser(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('groups') ?? '[]';
    final List<Map<String, dynamic>> groups = List<Map<String, dynamic>>.from(jsonDecode(groupsString));
    // Find the group by ID and remove the user from that group
    for (var group in groups) {
      if (group['id'] == _group['id']) {
        group['users'].removeWhere((user) => user['name'] == userName);
        break;
      }
    }
    // Save the updated groups list back to SharedPreferences
    final updatedGroupsString = jsonEncode(groups);
    await prefs.setString('groups', updatedGroupsString);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User removed from group')));
    // Update the UI
    _loadGroupUsers();
    // Notify listeners or update the UI if needed
    widget.onGroupUpdated?.call();// Refresh the users list in the group
  }
  Future<void> _saveFollowUpDate(String userId, DateTime date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('followUpDate_$userId', date.toIso8601String());
  }
  void _followUpBottomSheet(BuildContext context, Map<String, dynamic> user, Function(DateTime) onDateSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            DateTime? _selectedDate; // Track the selected date

            // Load the saved date for the specific user
            void _loadSavedDate() async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? dateString = prefs.getString('followUpDate_${user['name']}');
              if (dateString != null) {
                setState(() {
                  _selectedDate = DateTime.parse(dateString);
                });
              }
            }

            _loadSavedDate(); // Call the function to load the saved date

            Widget _buildListTile(String title, DateTime? date, [String? option]) {
              return ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    color: _selectedDate == date ? Colors.white : Colors.blue.shade900,
                  ),
                ),
                tileColor: _selectedDate == date ? Colors.blue.shade900 : null, // Change background color if selected
                onTap: () async {
                  setState(() {
                    _selectedDate = date; // Update selected date
                  });
                  if (user.isNotEmpty) { // Ensure the user object is not empty
                    await _saveFollowUpDate(user['name'], date ?? DateTime.now()); // Save date for the specific user
                    Navigator.pop(context);
                    onDateSelected(date ?? DateTime.now()); // Pass the selected date to the callback
                  } else {
                    // Handle the case where the user object is empty
                    print('User object is empty');
                  }
                },
              );
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
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                      child: Text(
                        "Schedule follow up for ${user['name']}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildListTile('Today', DateTime.now()),
                          _buildListTile('Tomorrow', DateTime.now().add(Duration(days: 1))),
                          _buildListTile('3 days from now', DateTime.now().add(Duration(days: 3))),
                          _buildListTile('1 week from now', DateTime.now().add(Duration(days: 7))),
                          _buildListTile('1 month from now', DateTime.now().add(Duration(days: 30))),
                          ListTile(
                            title: Text(
                              'Select custom date and time',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showCalendarBottomSheet(context, (date) async {
                                await _saveFollowUpDate(user['name'], date); // Save date for the specific user
                                onDateSelected(date); // Pass the selected date to the callback
                              });
                            },
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_group['name'],
            style: TextStyle(fontFamily:
            'Poppins',),),
            GestureDetector(
              onTap: () {
                _groupOptionsBottomSheet(context);
              },
              child: Text(
                "Options",
                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 14,fontFamily:
                'Poppins',),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                )],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Image.asset(
                      'assets/images/notification1.gif',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      user['name'],
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      user['email'],
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        _userOptionSheet(context, user);
                      },
                      icon: Icon(Icons.more_vert, color: Colors.grey,),
                    ),
                  ),
                  // SizedBox(height: 5,),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
class InitialContentPage extends StatefulWidget {
  final Map<String, dynamic> user;

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
        title: Text('Content Overview', style: TextStyle(color: Colors.white,fontFamily:
        'Poppins',)),
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
                                  style: TextStyle(fontSize: 18,fontFamily:
                                  'Poppins',),
                                ),
                                Text(
                                  _savedMessages[index]['message']!,
                                  style: TextStyle(color: Colors.grey,fontFamily:
                                  'Poppins',),
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
                  style: TextStyle(fontSize: 16,fontFamily:
                  'Poppins',),
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
                  style: TextStyle(color: Colors.white,fontFamily:
                  'Poppins',),
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
  final Map<String, dynamic> user;

  ContentDetailPage({
    required this.title,
    required this.message,
    required this.user,
  });

  void _sendMessageViaWhatsApp() async {
    final phoneNumber = user['phone']; // Replace with the recipient's phone number in international format
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'whatsapp://send?phone=$phoneNumber&text=$encodedMessage';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Handle the case where WhatsApp cannot be launched
      print('Could not launch WhatsApp');
    }
  }

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
                        Text(
                          'Sending message to ${user['name']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendMessageViaWhatsApp,
                  icon: FaIcon(
                    FontAwesomeIcons.whatsapp, // WhatsApp icon
                    color: Colors.green,
                  ),
                  label: Text(
                    'Send via WhatsApp',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900, // Background color
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
