import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color themeColor = Color(0xFF4A90E2);
  final TextEditingController phoneController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 20),

                const Text(
                  'ServEase',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),

                const SizedBox(height: 6),
                const Text('Local Services Booking'),

                const SizedBox(height: 40),

                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+91',
                          prefixIcon: const Icon(Icons.phone),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                          ),
                          onPressed: loading ? null : sendOtp,
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
    );
  }

  // ================= SEND OTP =================
  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    final validIndia = phone.startsWith('+91') && phone.length == 13;
    final validNepal = phone.startsWith('+977') && phone.length == 14;

    if (!validIndia && !validNepal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid phone number')),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,

      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() => loading = false);
      },

      verificationFailed: (e) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed')),
        );
      },

      codeSent: (verificationId, resendToken) {
        setState(() => loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(verificationId: verificationId),
          ),
        );
      },

      codeAutoRetrievalTimeout: (verificationId) {
        setState(() => loading = false);
      },
    );
  }
}
