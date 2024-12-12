import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../model/login_model.dart';
import '../notification_services/notification_provider.dart';
import 'leads_screen.dart' ;
class NotificationHistoryScreen extends StatefulWidget {
  final User? user; // Made nullable
  final String? selectedProjectCode; // Made nullable
  final String? projectUrl; // Made nullable

  NotificationHistoryScreen({
    Key? key,
    this.user, // No longer required
    this.selectedProjectCode, // No longer required
    this.projectUrl, // No longer required
  }) : super(key: key);


  @override
  _NotificationHistoryScreenState createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {

  StreamController<List<Map<String, dynamic>>> _notificationStreamController =
  StreamController<List<Map<String, dynamic>>>();

  List<Map<String, dynamic>> _notifications = [];
  String? selectedProjectCode;
  int unreadCount = 0;
  User? user;



  @override
  void initState() {
    super.initState();
    selectedProjectCode = widget.selectedProjectCode; // Initialize selectedProjectCode
    print('Selected Project Code in initState: ${widget.selectedProjectCode}');
    fetchNotifications();
    startListeningForUpdates();
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }

  void startListeningForUpdates() {
    Timer.periodic(Duration(seconds: 30), (timer) {
      fetchNotifications();
    });
  }

  Future<void> fetchNotifications() async {
    final url = Uri.parse(
        'https://clients.dotphi.com/application/controllers/Api/notification_feeder.php?project_code=${widget.selectedProjectCode}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _notifications = responseData.map((notification) {

            print('Response Data: $responseData');
            // print('API Response: ${response.body}');
            // print('Notification data: $notification');
            return {
              'id': notification['id'],
              'title': notification['title'],
              'description': notification['description'],
              'time': calculateTimeDifference(notification['date_time']),
              'read': notification['read'],
            };
          }).toList();

          unreadCount = _notifications.where((n) => !n['read']).length;
          final newUnreadCount = _notifications.where((n) => !n['read']).length;
          Provider.of<UnreadCountProvider>(context, listen: false).updateUnreadCount(newUnreadCount);
            print('CODE::::$selectedProjectCode');

        });


      } else {
        print('Failed to fetch notifications');

      }
    } catch (error) {
      print('Error fetching notifications: $error');

    }
  }

  String calculateTimeDifference(String dateTimeString) {
    DateTime notificationTime = DateTime.parse(dateTimeString);
    DateTime currentTime = DateTime.now();
    Duration difference = currentTime.difference(notificationTime);

    if (difference.inDays >= 7) {
      return DateFormat('MMM dd, yyyy').format(notificationTime);
    } else if (difference.inHours >= 24) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }

  // Modify markAsRead function to handle null notification ID
  void markAsRead(int index, int? notificationId) async {
    if (notificationId == null) {
      print('Notification ID is null');
      return;
    }

    // Check if the widget is mounted before calling setState
    if (!mounted) {
      return;
    }

    // Send a request to mark the notification as read
    final markAsReadUrl = Uri.parse(
        'https://clients.dotphi.com/application/controllers/Api/mark_notification_read.php');

    try {
      await http.post(markAsReadUrl, body: {'notification_id': notificationId.toString()});
    } catch (error) {
      print('Error marking notification as read: $error');
    }

    // Check again if the widget is mounted before calling setState
    if (!mounted) {
      return;
    }

    setState(() {
      _notifications[index]['read'] = true;
      unreadCount = _notifications.where((n) => !n['read']).length;
      print('COUNT:$unreadCount');
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(

        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 50,
          toolbarOpacity: 0.7,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(25),
              bottomLeft: Radius.circular(25),
            ),
          ),
          title: Row(
            children: 'Notification'.split('').map((letter) {
              int fontSize = 30 - 'Notification'.indexOf(letter) * 1;
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
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.notifications),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
          body: _notifications.isEmpty
              ? Center(
                child: Image.asset('assets/images/empty.png',
                  height:120,width: 120, ),
          )
              : RefreshIndicator(
            color: Colors.blue.shade900,
            onRefresh: () => fetchNotifications(), // Call fetchNotifications when refreshing
            child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  var notification = _notifications[index];
                  bool isRead = notification['read'];

                  return GestureDetector(
                      onTap: () {
                        int notificationId = int.parse(notification['id']);
                        markAsRead(index, notificationId);
                        print('Notification read statussss: $isRead}');
                        print('COUNT:$unreadCount');

                        if (notification['title'] == "New Enquiry") {
                          Navigator.pushReplacement(
                            context, MaterialPageRoute(
                              builder: (context) => ApiScreen(
                                    user: widget.user,
                                    projectUrl: widget.projectUrl,
                                    selectedProjectCode: widget.selectedProjectCode),),);
                        } else {
                          Navigator.pushReplacement(
                            context, MaterialPageRoute(
                              builder: (context) => ApiScreen(
                                    user: widget.user,
                                    projectUrl: widget.projectUrl,
                                    selectedProjectCode: widget
                                        .selectedProjectCode,
                                  ),),);}},
                      child: Card(
                        elevation: 5,
                        margin: const EdgeInsets.all(10),
                        color: isRead == true ? Colors.white : Colors.blue.shade100,
                        child: ListTile(
                          leading: Image.asset(
                            isRead == true ? 'assets/images/close.png' : 'assets/images/open.png',
                            width: 30, // specify the desired width
                            height: 30, // specify the desired height
                          ),
                          title: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead == true ? FontWeight.normal :FontWeight.bold ,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          subtitle: Text(
                            notification['description'] ?? '',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),),
                          trailing: Text(
                            notification['time'] ?? '', // Display time
                            style: TextStyle(
                              color: Colors.black54,
                              fontStyle: FontStyle.italic, fontFamily: 'Poppins',
                            ),),),),);
                  }),
              ),);}}





