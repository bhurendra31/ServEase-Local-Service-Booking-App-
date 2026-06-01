import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'profile_details_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
      List.generate(6, (_) => FocusNode());

  static const List<String> registeredUsers = [
    '+9779812035113',
    '+919798690551',
  ];

  String getOtp() {
    return controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter 6-digit OTP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            /// 🔢 OTP BOXES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextFormField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color.fromARGB(255, 34, 34, 34)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color.fromARGB(255, 71, 125, 226), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            /// ✅ VERIFY BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                ),
                onPressed: () async {
                  final otp = getOtp();

                  if (otp.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid OTP')),
                    );
                    return;
                  }

                  try {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: widget.verificationId,
                      smsCode: otp,
                    );

                    final userCredential =
                        await FirebaseAuth.instance
                            .signInWithCredential(credential);

                    final phone =
                        userCredential.user?.phoneNumber ?? '';

                    if (registeredUsers.contains(phone)) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProfileDetailsScreen(),
                        ),
                      );
                    }
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid OTP')),
                    );
                  }
                },
                child: const Text(
                  'Verify OTP',
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
    );
  }
}
