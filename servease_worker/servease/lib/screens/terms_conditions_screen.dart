import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _TitleText('Terms & Conditions'),
            _BodyText(
              'Welcome to ServEase. By using this application, you agree to the following Terms & Conditions. Please read them carefully.',
            ),

            _TitleText('1. Acceptance of Terms'),
            _BodyText(
              'By accessing or using the ServEase application, you agree to be bound by these terms. If you do not agree, please do not use the app.',
            ),

            _TitleText('2. Service Description'),
            _BodyText(
              'ServEase is a local service booking platform that connects users with service providers such as cleaners, plumbers, electricians, and others. ServEase does not directly provide services.',
            ),

            _TitleText('3. User Responsibilities'),
            _BulletText('Provide accurate and complete information'),
            _BulletText('Maintain the security of your account'),
            _BulletText('Do not misuse the platform'),

            _TitleText('4. Booking & Cancellation'),
            _BodyText(
              'Bookings are subject to availability. Users may cancel bookings before the service begins. ServEase may cancel bookings in case of misuse.',
            ),

            _TitleText('5. Service Providers'),
            _BodyText(
              'Service providers operate independently. ServEase does not guarantee service quality or outcomes.',
            ),

            _TitleText('6. Payments'),
            _BodyText(
              'Payment terms (if applicable) will be shown during booking. ServEase is not responsible for disputes unless stated otherwise.',
            ),

            _TitleText('7. User Conduct'),
            _BulletText('No abusive or offensive behavior'),
            _BulletText('No illegal activities'),
            _BulletText('No false or misleading information'),

            _TitleText('8. Limitation of Liability'),
            _BodyText(
              'ServEase is not liable for service delays, quality issues, losses, or damages resulting from services booked through the app.',
            ),

            _TitleText('9. Account Termination'),
            _BodyText(
              'ServEase may suspend or terminate accounts that violate these terms.',
            ),

            _TitleText('10. Privacy'),
            _BodyText(
              'Your privacy is important to us. Please refer to our Privacy Policy for details.',
            ),

            _TitleText('11. Changes to Terms'),
            _BodyText(
              'ServEase may update these Terms & Conditions at any time. Continued use of the app means acceptance of updated terms.',
            ),

            _TitleText('12. Contact Us'),
            _BodyText(
              'If you have questions, contact us at support@servease.com',
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Custom Widgets for clean UI
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
