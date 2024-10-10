
import 'package:shared_preferences/shared_preferences.dart';

Future<User> getUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String clientId = prefs.getString('clientId') ?? '';
  String email = prefs.getString('email') ?? '';
  String phone = prefs.getString('phone') ?? '';
  String username = prefs.getString('username') ?? '';
  String status = prefs.getString('status') ?? '';
  String created = prefs.getString('created') ?? '';
  String modified = prefs.getString('modified') ?? '';
  String project_id = prefs.getString('project_id') ?? '';
  String projectUniqueCode = prefs.getString('project_unique_code') ?? '';

  User user = User(
    clientId: clientId,
    email: email,
    phone: phone,
    username: username,
    status: status,
    created: created,
    modified: modified,
    project_id: project_id,
    project_unique_code: projectUniqueCode,
  );
  return user;
}



class User {
  final String clientId;
  final String email;
  final String phone;
  final String username;
  // final String password;
  final String status;
  final String created;
  final String modified;
  final String project_id;
  final String  project_unique_code;

  User({
    required this.clientId,
    required this.email,
    required this.phone,
    required this.username,
    // required this.password,
    required this.status,
    required this.created,
    required this.modified,
    required this.project_id,

    required this.project_unique_code,
  });


  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'email': email,
      'phone': phone,
      'username': username,
      'status': status,
      'created': created,
      'modified': modified,
      'project_id': project_id,
      'project_unique_code': project_unique_code,
    };
  }


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      clientId: json['client_id'],
      email: json['email'],
      phone: json['phone'],
      username: json['username'],
      // password: json['password'],
      status: json['status'],
      created: json['created'],
      modified: json['modified'],
      project_id: json['project_id'],

      project_unique_code:json['project_unique_code'],
    );
  }
}

class UserStorage {
  static Future<void> storeUser(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    prefs.setString('loginResponse', user.toJson().toString());
    prefs.setBool('isLoggedIn', true);
    prefs.setString('clientId', user.clientId);
    prefs.setString('email', user.email);
    prefs.setString('phone', user.phone);
    prefs.setString('username', user.username);
    prefs.setString('status', user.status);
    prefs.setString('created', user.created);
    prefs.setString('modified', user.modified);
    prefs.setString('project_id', user.project_id);
    prefs.setString('project_unique_code', user.project_unique_code);
  }
}


