import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (+91XXXXXXXXXX)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final phone = _phoneController.text.trim();

                // ✅ Phone validation
                if (!RegExp(r'^\+\d{10,13}$').hasMatch(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter valid phone number'),
                    ),
                  );
                  return;
                }

                await _auth.verifyPhoneNumber(
                  phoneNumber: phone,

                  // 🔹 Auto verification (Android)
                  verificationCompleted: (PhoneAuthCredential credential) async {
                    await _auth.signInWithCredential(credential);
                  },

                  // 🔹 Error handling
                  verificationFailed: (FirebaseAuthException e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? 'Verification failed')),
                    );
                  },

                  // 🔹 OTP sent
                  codeSent: (String verificationId, int? resendToken) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtpScreen(
                          verificationId: verificationId,
                        ),
                      ),
                    );
                  },

                  // 🔹 Timeout
                  codeAutoRetrievalTimeout: (String verificationId) {},
                );
              },
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
