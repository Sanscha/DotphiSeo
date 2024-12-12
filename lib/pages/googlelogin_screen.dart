import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dotphi_seo_app/pages/submission_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'flutter_toast.dart';

class GoogleloginScreen extends StatefulWidget {
  const GoogleloginScreen({super.key});

  @override
  State<GoogleloginScreen> createState() => _GoogleloginScreenState();
}

class _GoogleloginScreenState extends State<GoogleloginScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _isObscured = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isVisible = true;



  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      CustomToast.show('Login successful!', backgroundColor: Colors.green);
      print("User logged in: ${userCredential.user?.email}");

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubmissionScreen()),
      );
    } on FirebaseAuthException catch (e) {
      CustomToast.show('Failed to log in: ${e.message}', backgroundColor: Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
              SizedBox(height: 40),
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
                    child:
                   Column(
                      children: [
                        SizedBox(height: 40),
                       Image.asset('assets/images/google.png',
                       width: 40,
                       height:40,
                       fit: BoxFit.cover,),
                        SizedBox(height: 15),
                        isLoading?
                        Center(
                          child: Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 20,),
                                SpinKitCircle(color: Colors.blue.shade900,),
                                SizedBox(height: 20,),
                                Text("Logging in with Google",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins', color: Colors.black,
                                ),)],
                            ),
                          ),
                        ):
                        Container(
                          child: Column(
                            children: [
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 24, fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold, color: Colors.blue[900],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 5,),
                              Text(
                                'Continue with Google',
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
                                onPressed:() {
                                  _loginWithEmailPassword();
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
                                    child:Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 18, fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold, color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account?",
                                    style: TextStyle( fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[600],),),
                                  GestureDetector(
                                    onTap: (){Navigator.push(context,MaterialPageRoute(builder: (context)=>GoogleSignUpScreen()));},
                                    child: Text('Signup',
                                      style: TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold, color: Colors.blue[900],
                                      ),),
                                  )
                                ],
                              ),
                            ],
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

class GoogleSignUpScreen extends StatefulWidget {
  const GoogleSignUpScreen({super.key});

  @override
  State<GoogleSignUpScreen> createState() => _GoogleSignUpScreenState();
}

class _GoogleSignUpScreenState extends State<GoogleSignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _isObscured = true;

  Future<void> _signUpWithEmailPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update the user's display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());
      await userCredential.user?.reload();

      CustomToast.show('Sign-up successful!', backgroundColor: Colors.green);

      print("User signed up: ${userCredential.user?.email}");

      // Navigate to another screen or home screen upon successful sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SubmissionScreen()),
      );

    } on FirebaseAuthException catch (e) {
      String message = 'Failed to sign up: ${e.message}';
      CustomToast.show(message, backgroundColor: Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
              SizedBox(height: 40),
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
                    child: isLoading?Container(
                      child: Row(
                        children: [
                          Image.asset('assets/images/google.png',
                            width: 5,
                            height:5,
                            fit: BoxFit.cover,),
                          Text('Signing in with Google'),
                        ],
                      ),
                    ):Column(
                      children: [
                        SizedBox(height: 40),
                        Image.asset('assets/images/google.png',
                          width: 40,
                          height:40,
                          fit: BoxFit.cover,),

                        SizedBox(height: 15),
                        Text(
                          'Signup',
                          style: TextStyle(
                            fontSize: 24, fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold, color: Colors.blue[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5,),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
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
                          onPressed: isLoading?null:() {
                            _signUpWithEmailPassword();
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
                              child:Text(
                                'SignUp',
                                style: TextStyle(
                                  fontSize: 18, fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold, color: Colors.white,
                                ),
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

