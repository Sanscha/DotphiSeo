import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../model/login_model.dart';
import 'login_screen.dart';

class ApiService {
  static Future<ApiResponse<User>> login(String email, String password, String? fcmToken) async {
    try {
      var url = Uri.parse('https://clients.dotphi.com/Api/Login/index');
      var response = await http.post(url, body: {
        'email': email,
        'password': password,
        'lead_fcm': fcmToken ?? '',
      });

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          List<dynamic> userData = jsonResponse['data'];
          User user = User.fromJson(userData[0]);
          return ApiResponse(data: user, rawResponse: response.body, status: Status.SUCCESS);
        } else {
          return ApiResponse(data: null, rawResponse: response.body, status: Status.ERROR);
        }
      } else {
        return ApiResponse(data: null, rawResponse: 'An error occurred from server while logging in.', status: Status.ERROR);
      }
    } catch (e) {
      return ApiResponse(data: null, rawResponse: 'An error occurred: $e', status: Status.ERROR);
    }
  }

  static Future<void> resetPassword(BuildContext context, String email) async {
    final String apiUrl = 'https://clients.dotphi.com/Api/Login/forgot_password';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        _handleResponse(context, response);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  static void _handleResponse(BuildContext context, http.Response response) {
    final Map<String, dynamic> responseData = json.decode(response.body);

    Fluttertoast.showToast(
      msg: responseData['message'],
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: responseData['status'] == 'success'
          ? Colors.green
          : Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    if (responseData['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreenn()),
      );
    }
  }

}

class ApiResponse<T> {
  final T? data;
  final String rawResponse;
  final Status status;

  ApiResponse({required this.data, required this.rawResponse, required this.status});
}

enum Status { SUCCESS, ERROR }
