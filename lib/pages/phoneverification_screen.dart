import 'package:dotphi_seo_app/pages/demo_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';


class PhoneverificationScreen extends StatefulWidget {
  const PhoneverificationScreen({super.key});

  @override
  State<PhoneverificationScreen> createState() => _PhoneverificationScreenState();
}

class _PhoneverificationScreenState extends State<PhoneverificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = "";
  bool isLoading = false;
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IN');  // Default country code as 'IN'

  Future<void> verifyPhoneNumber() async {
    isLoading=true;
    // Make sure to access the phoneNumber string from _phoneNumber
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneNumber.phoneNumber!,  // Access the phone number
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification has completed
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DemoScreen()),
        ); // Navigate to Home on success
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle verification failure
        print('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        // Store verification ID when OTP is sent
        setState(() {
          _verificationId = verificationId;
        });
        isLoading=false;
        // Navigate to OTP Verification screen with verificationId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              verificationId: verificationId,
              phoneNo: _phoneNumber.phoneNumber!,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout if the OTP isn't received in time
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  Future<void> signInWithOTP() async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    // Navigate to home screen or do something else on success
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
              Image.asset(
                'assets/images/dotphi.png',
                width: 150,
                height: 150,
              ),
              SizedBox(height: 40),
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Image.asset(
                          'assets/images/phone.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 15),
                        isLoading
                            ? Center(
                          child: Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 20),
                                SpinKitCircle(
                                  color: Colors.blue.shade900,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "Wait for OTP",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    color: Colors.black,
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                            : Container(
                          child: Column(
                            children: [
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Continue with Phone no',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 40),
                              Container(
                                width: 500, // Adjust the width as needed
                                child: InternationalPhoneNumberInput(
                                  onInputChanged: (PhoneNumber number) {
                                    setState(() {
                                      _phoneNumber = number; // Update phone number
                                    });
                                  },
                                  initialValue: _phoneNumber,
                                  textFieldController: _phoneController,
                                  inputDecoration: InputDecoration(
                                    labelText: 'Phone no',
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
                                  formatInput: false,
                                  selectorConfig: SelectorConfig(
                                    selectorType: PhoneInputSelectorType.DIALOG,
                                    showFlags: true,
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  verifyPhoneNumber();
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
                                      'Request OTP',
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

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNo;

  OtpVerificationScreen({required this.verificationId, required this.phoneNo});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Function to handle OTP entry and manage focus
  void _onOtpDigitEntered(int index) {
    if (_otpControllers[index].text.length == 1) {
      if (index < 5) {
        // Move to next field
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        // If last field, unfocus the keyboard
        FocusScope.of(context).unfocus();
      }
    } else if (_otpControllers[index].text.isEmpty && index > 0) {
      // If backspacing, go to previous field
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  // Combine OTP from individual boxes and verify
  Future<void> signInWithOTP() async {
    String otpCode = _otpControllers.map((c) => c.text).join();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DemoScreen()),
      );
    } catch (e) {
      print("Error signing in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
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
              SizedBox(height: 40),
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Image.asset(
                          'assets/images/phone.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Verification Code',
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We have sent the code verification to your Mobile No',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${widget.phoneNo}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.blue[100],
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Poppins',
                                  ),
                                  onChanged: (_) => _onOtpDigitEntered(index),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: signInWithOTP,
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
                                'Submit',
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


