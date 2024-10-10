import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../notification_services/notification_services.dart';
import 'api_service.dart';
import '../model/login_model.dart';
import 'forgot_password.dart';
import 'navbar.dart';
import 'flutter_toast.dart'; // Import the CustomToast widget

class LoginScreenn extends StatefulWidget {
  static String projectUrl = "";
  static String selectedProjectCode = "";

  @override
  _LoginScreennState createState() => _LoginScreennState();
}

class _LoginScreennState extends State<LoginScreenn> {
  NotificationServices notificationServices = NotificationServices();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _isObscured = true;

  @override
  void initState(){
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit();
    notificationServices.getDeviceToken().then((value) {
      print('device token');
      print(value);
    });
  }

  Future<void> login(String email, String password) async {
    bool isConnected;
    try {
      isConnected = await InternetConnectionChecker().hasConnection;
    } on Exception catch (_) {
      isConnected = false;
    }

    if (!isConnected) {
      CustomToast.show('No internet connection.');
      return;
    }
    setState(() {
      isLoading = true;
    });

    String? fcmToken = await notificationServices.getDeviceToken();

    print('FCM Tokennnn: $fcmToken');

    if (email.isEmpty) {
      CustomToast.show('Please enter your email.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      CustomToast.show('Please enter your password.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    ApiResponse<User> apiResponse = await ApiService.login(email, password, fcmToken);

    if (apiResponse.status == Status.SUCCESS) {
      User user = apiResponse.data!;
      await UserStorage.storeUser(user); // Store user data

      CustomToast.show('Login successful!', backgroundColor: Colors.green);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NavBarScreen(
            user: user,
            projectUrl: LoginScreenn.projectUrl,
            selectedProjectCode: user.project_unique_code,
          ),
        ),
      );
    } else if (apiResponse.status == Status.ERROR) {
      CustomToast.show('Invalid email or password. Please enter correct details.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred from server while logging in.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.blue[900]!, Colors.blue[400]!],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 100),
              Image.asset('assets/images/dotphi.png',
                width: 150, height: 150,
              ),
              SizedBox(height: 20),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40), topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24, fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold, color: Colors.blue[900],
                          ),
                        ),

                        SizedBox(height: 15),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 20),
                        Stack(
                          children: [
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20,
                                ),
                              ),
                              style: TextStyle(fontSize: 16,),
                              obscureText: _isObscured,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Icon(
                                    _isObscured ? Icons.visibility_off : Icons.visibility,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            login(
                              _emailController.text.toString(),
                              _passwordController.text.toString(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Container(
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 18, fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold, color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height:5),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ForgotPasswordScreen(selectedProjectCode: LoginScreenn.selectedProjectCode, projectUrl: LoginScreenn.projectUrl,),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 16, fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold, color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
