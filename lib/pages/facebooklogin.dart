import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'facebookanalytics_screen.dart';

class FacebookLoginButton extends StatelessWidget {
  final Function(String accessToken) onLoginSuccess;

  const FacebookLoginButton({
    Key? key,
    required this.onLoginSuccess,
  }) : super(key: key);

  Future<void> _handleLogin(BuildContext context) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: [ 'email',
          'public_profile',
          'pages_read_engagement',
          'pages_show_list',
          'read_insights', // Add permission for reading insights
          'ads_management' // Add permission for accessing ads data (if required)],
      ]);

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;

        if (accessToken != null) {
          // Verify token validity
          await _validateToken(accessToken, context);
          onLoginSuccess(accessToken);
          Navigator.push(context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                accessToken: accessToken,
              ),
            ),
          );

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Access Token Missing")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Failed: ${result.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // This function checks if the token is valid
  Future<void> _validateToken(String token, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://graph.facebook.com/v12.0/me?access_token=$token'),
      );

      if (response.statusCode == 200) {
        // If the token is valid
        final data = jsonDecode(response.body);
        print("Token is valid for user: ${data['name']}");
      } else {
        // If the token is invalid
        throw Exception('Invalid Token');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Token validation failed: $e")),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleLogin(context),
      child: Text("Login with Facebook"),
    );
  }
}
