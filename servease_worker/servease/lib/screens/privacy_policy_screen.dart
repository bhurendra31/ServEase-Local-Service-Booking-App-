import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _TitleText('Privacy Policy'),
            _BodyText(
              'At ServEase, we value your privacy and are committed to protecting your personal information.',
            ),

            _TitleText('1. Information We Collect'),
            _BulletText('Name, phone number, and email address'),
            _BulletText('Address and location details'),
            _BulletText('Booking and service history'),
            _BulletText('Profile image (if uploaded)'),

            _TitleText('2. How We Use Your Information'),
            _BulletText('To create and manage your account'),
            _BulletText('To process service bookings'),
            _BulletText('To communicate booking updates'),
            _BulletText('To improve app functionality'),

            _TitleText('3. Data Sharing'),
            _BodyText(
              'Your information may be shared with service providers only for completing your requested services. We do not sell your personal data.',
            ),

            _TitleText('4. Data Security'),
            _BodyText(
              'We use industry-standard security measures to protect your data, including secure authentication and database rules.',
            ),

            _TitleText('5. User Control'),
            _BodyText(
              'You can update your profile information anytime from the Profile section of the app.',
            ),

            _TitleText('6. Cookies & Tracking'),
            _BodyText(
              'ServEase may use analytics tools to improve user experience. No sensitive data is tracked without consent.',
            ),

            _TitleText('7. Third-Party Services'),
            _BodyText(
              'We may use third-party services such as Firebase and Cloudinary to store data securely.',
            ),

            _TitleText('8. Policy Updates'),
            _BodyText(
              'This Privacy Policy may be updated from time to time. Continued use of the app implies acceptance.',
            ),

            _TitleText('9. Contact Us'),
            _BodyText(
              'If you have any privacy-related concerns, contact us at privacy@servease.com',
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
