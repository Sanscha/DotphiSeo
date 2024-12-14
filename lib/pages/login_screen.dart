import 'package:dotphi_seo_app/pages/submission_screen.dart';
import 'package:dotphi_seo_app/pages/phoneverification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:twitter_login/twitter_login.dart';
import '../model/login_model.dart';
import '../notification_services/notification_services.dart';
import 'api_service.dart';
import 'package:dotphi_seo_app/model/login_model.dart' as custom;
import 'forgot_password.dart';
import 'googlelogin_screen.dart';
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
  String? displayName;

  @override
  void initState() {
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit();
    notificationServices.getDeviceToken().then((value) {
      print('device token');
      print(value);
    });
  }


  Future<firebase_auth.UserCredential> signInWithFacebook() async {
    isLoading = true;

    // Facebook login
    final LoginResult loginResult = await FacebookAuth.instance.login();

    if (loginResult.status == LoginStatus.success) {
      final AuthCredential facebookAuthCredential =
      FacebookAuthProvider.credential('${loginResult.accessToken?.tokenString}');

      // Sign in with Facebook credential
      firebase_auth.UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);

      // Get the Firebase user
      firebase_auth.User? user = userCredential.user;

      displayName = user?.displayName; // Save the display name in a local variable

      if (displayName != null) {
        print('User display name: $displayName');
      } else {
        print('No display name available');
      }

      // Get the user profile (email, phone, etc.)
      final userData = await FacebookAuth.instance.getUserData();

      // Access user email and phone number
      String? email = userData['email'];  // Email
      String? phoneNumber = userData['phone']; // Phone number (if available)

      print('User email: $email');
      print('User phone number: $phoneNumber');

      isLoading = false;
      return userCredential;
    } else {
      isLoading = false;
      throw Exception('Facebook login failed');
    }
  }



  Future<UserCredential> signInWithTwitter(BuildContext context) async {
    // Create a TwitterLogin instance
    final twitterLogin = TwitterLogin(
      apiKey: 'gDaeOcK2ukTnJIeiKU4yfWGgk',
      apiSecretKey: 'qhhttDghKx5STS8fA0FBSgdrlMx2z2E7Rb3D1nWcErOzkZMvT0',
      redirectURI: 'twittersdk://',
    );

    // Trigger the sign-in flow
    final authResult = await twitterLogin.login();

    if (authResult.authToken != null && authResult.authTokenSecret != null) {
      // Create a credential from the access token
      final twitterAuthCredential = TwitterAuthProvider.credential(
        accessToken: authResult.authToken!,
        secret: authResult.authTokenSecret!,
      );

      // Sign in with Firebase using the Twitter credential
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(twitterAuthCredential);

      // Get the logged-in user
      firebase_auth.User? user = userCredential.user;
      print(user);

      // Navigate to NavBarScreen and pass user details
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NavBarScreen(
              displayName: user.displayName ?? "Unknown User",

            ),
          ),
        );
      }

      // Return the UserCredential object
      return userCredential;
    } else {
      throw Exception("Twitter sign-in failed");
    }
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

    ApiResponse<custom.User> apiResponse =
        await ApiService.login(email, password, fcmToken);

    if (apiResponse.status == Status.SUCCESS) {
      custom.User user = apiResponse.data!;
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
      CustomToast.show(
          'Invalid email or password. Please enter correct details.');
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[900]!, Colors.blue[400]!],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 100),
              Image.asset(
                'assets/images/dotphi.png',
                width: 150,
                height: 150,
              ),
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          SizedBox(height: 40),
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Colors.grey[600],
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
                                vertical: 15,
                                horizontal: 20,
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
                                    vertical: 15,
                                    horizontal: 20,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                ),
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
                                      _isObscured
                                          ? Icons.visibility_off
                                          : Icons.visibility,
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
                                    fontSize: 18,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPasswordScreen(
                                      selectedProjectCode:
                                          LoginScreenn.selectedProjectCode,
                                      projectUrl: LoginScreenn.projectUrl,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 22),
                          Text("Login as Guest",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Call the signInWithFacebook function
                                      final userCredential =
                                          await signInWithFacebook();

                                      // Navigate to another page upon successful login
                                      if (userCredential.user != null) {
                                        CustomToast.show('Login successful',
                                            backgroundColor: Colors.green);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                NavBarScreen(displayName: displayName,), // Replace `NextPage` with your desired screen
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Handle login error (optional)
                                      print('Error during Facebook login: $e');
                                      CustomToast.show(
                                          'Facebook login failed. Please try again.',
                                          backgroundColor: Colors.red);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/facebook.png',
                                        width: 30.0, // Set the width of the image
                                        height:
                                            30.0, // Set the height of the image
                                        fit: BoxFit.cover,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  GoogleloginScreen()));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/google.png',
                                          width:
                                              30.0, // Set the width of the image
                                          height:
                                              30.0, // Set the height of the image
                                          fit: BoxFit.cover,
                                        ),
                                      ],
                                    )),
                              ),
                              Container(
                                child: ElevatedButton(
                                    onPressed: () {
                                      signInWithTwitter(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/twitter.png',
                                          width:
                                              30.0, // Set the width of the image
                                          height:
                                              30.0, // Set the height of the image
                                          fit: BoxFit.cover,
                                        ),
                                      ],
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
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
