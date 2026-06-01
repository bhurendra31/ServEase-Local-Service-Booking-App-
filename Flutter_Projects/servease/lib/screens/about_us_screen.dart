import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome to ServEase',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              Text(
                'ServEase is a local service booking platform designed to '
                'connect users with trusted service professionals such as '
                'cleaners, electricians, plumbers, and other skilled workers.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),

              Text(
                'Our mission is to simplify everyday service bookings by '
                'providing a fast, reliable, and user-friendly platform '
                'that benefits both customers and service providers.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                'Why ServEase?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),

              Text(
                '• Easy service booking\n'
                '• Verified local workers\n'
                '• Transparent booking status\n'
                '• Real-time updates\n'
                '• Secure and reliable\n',
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 20),

              Text(
                'Thank you for choosing ServEase.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
