// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'worker_otp_screen.dart';

// class WorkerLoginScreen extends StatefulWidget {
//   const WorkerLoginScreen({super.key});

//   @override
//   State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
// }

// class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
//   final TextEditingController phoneController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   static const Color themeColor = Color(0xFF4A90E2);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: themeColor,
//         title: const Text('Phone Login'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: phoneController,
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(
//                 labelText: 'Phone (+91XXXXXXXXXX)',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),

//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: themeColor,
//                 ),
//                 onPressed: () async {
//                   final phone = phoneController.text.trim();

//                   // ✅ SAME LOGIC
//                   if (!RegExp(r'^\+\d{10,13}$').hasMatch(phone)) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Enter valid phone number'),
//                       ),
//                     );
//                     return;
//                   }

//                   await _auth.verifyPhoneNumber(
//                     phoneNumber: phone,
//                     verificationCompleted:
//                         (PhoneAuthCredential credential) async {
//                       await _auth.signInWithCredential(credential);
//                     },
//                     verificationFailed: (FirebaseAuthException e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content:
//                               Text(e.message ?? 'Verification failed'),
//                         ),
//                       );
//                     },
//                     codeSent: (verificationId, _) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => WorkerOtpScreen(
//                             verificationId: verificationId,
//                             phone: phone,
//                           ),
//                         ),
//                       );
//                     },
//                     codeAutoRetrievalTimeout: (_) {},
//                   );
//                 },
//                 child: const Text(
//                   'Send OTP',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'worker_otp_screen.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF), // light background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              /// 🔹 LOGO
              Column(
                children: [
                  Image.asset(
                    'assets/images/looogo.png', // 🔴 make sure this exists
                    height: 90,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ServEase Worker',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Local Services Booking',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              /// 🔹 PHONE INPUT CARD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.phone, color: themeColor),
                    hintText: '+91XXXXXXXXXX',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 CONTINUE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    final phone = phoneController.text.trim();

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
                      verificationCompleted:
                          (PhoneAuthCredential credential) async {
                        await _auth.signInWithCredential(credential);
                      },
                      verificationFailed: (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(e.message ?? 'Verification failed'),
                          ),
                        );
                      },
                      codeSent: (verificationId, _) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerOtpScreen(
                              verificationId: verificationId,
                              phone: phone,
                            ),
                          ),
                        );
                      },
                      codeAutoRetrievalTimeout: (_) {},
                    );
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
