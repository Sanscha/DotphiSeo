import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'login_screen.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final selectedProjectCode;final String projectUrl;

  ForgotPasswordScreen({
    required this.selectedProjectCode, required this.projectUrl,
  });

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> _resetPassword(BuildContext context) async {
    final String email = emailController.text;
    setState(() {
      isLoading = true;
    });
    await ApiService.resetPassword(context, email);
    setState(() {
      isLoading = false;});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildForm(context),);
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: 'Enter email...',
        filled: true,
        fillColor: Colors.grey[200],
        labelStyle: TextStyle(
          fontFamily: 'Poppins', color: Colors.grey,),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 15, horizontal: 20,),),
      style: TextStyle(
        fontSize: 16, fontFamily: 'Poppins',),
      validator: _validateEmail,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  Widget _buildResetPasswordButton() {
    return ElevatedButton(
      onPressed: () {
        _resetPassword(context);
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
          child: isLoading
              ? SpinKitCircle(
            color: Colors.white, size: 40.0,)
              : Text(
            'RESET PASSWORD',
            style: TextStyle(
              fontSize: 18, fontFamily: 'Poppins',
              fontWeight: FontWeight.bold, color: Colors.white,),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Align(
      alignment: Alignment.bottomRight,
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreenn(),),
          );
        },
        child: Text(
          'Login ?',
          style: TextStyle(
            fontSize: 16, fontFamily: 'Poppins',
            fontWeight: FontWeight.bold, color: Colors.blue[900],),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
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
              _buildLogo(),
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40), topRight: Radius.circular(40),),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        _buildTitle(),
                        SizedBox(height: 20),
                        _buildSubtitle(),
                        SizedBox(height: 40),
                        _buildEmailField(),
                        SizedBox(height: 30),
                        _buildResetPasswordButton(),
                        SizedBox(height: 5),
                        _buildLoginLink(),
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

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/dotphi.png',
      width: 150, height: 150,);
  }

  Widget _buildTitle() {
    return Text(
      'Forgot Password',
      style: TextStyle(
        fontSize: 24, fontFamily: 'Poppins',
        fontWeight: FontWeight.bold, color: Colors.blue[900],),);
  }

  Widget _buildSubtitle() {
    return Text(
      'Enter your email to reset password',
      style: TextStyle(
        fontSize: 16, fontFamily: 'Poppins', color: Colors.grey[600],),
      textAlign: TextAlign.center,);
  }
}
