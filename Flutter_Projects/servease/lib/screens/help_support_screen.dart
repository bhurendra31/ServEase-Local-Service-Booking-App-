import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _TitleText('Help & Support'),
            _BodyText(
              'We are here to help you with any issues or questions regarding ServEase.',
            ),

            _TitleText('Frequently Asked Questions'),

            _TitleText('1. How do I book a service?'),
            _BodyText(
              'Select a service from the home screen, choose date and time, and confirm your booking.',
            ),

            _TitleText('2. How can I cancel a booking?'),
            _BodyText(
              'Go to My Bookings → Upcoming → Tap the cancel icon.',
            ),

            _TitleText('3. How do I edit my profile?'),
            _BodyText(
              'Go to Profile → Tap edit icon near your name or profile photo.',
            ),

            _TitleText('4. Payment Issues'),
            _BodyText(
              'If you face payment issues, please contact our support team.',
            ),

            _TitleText('5. Service Complaints'),
            _BodyText(
              'You can report issues with service quality through Help & Support.',
            ),

            _TitleText('Contact Support'),
            _BulletText('Email: support@servease.com'),
            _BulletText('Phone: +977-9812035113'),
            _BulletText('Working Hours: 9 AM – 6 PM'),

            _TitleText('Feedback'),
            _BodyText(
              'Your feedback helps us improve ServEase. Feel free to share suggestions.',
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Reusable Widgets
class _TitleText extends StatelessWidget {
  final String text;
  const _TitleText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
