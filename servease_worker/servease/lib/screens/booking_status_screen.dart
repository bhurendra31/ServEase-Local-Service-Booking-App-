import 'package:flutter/material.dart';

class BookingStatusScreen extends StatelessWidget {
  final String bookingId;

  const BookingStatusScreen({
    super.key,
    required this.bookingId,
  });

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Booking Status'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: themeColor,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Booking ID: $bookingId',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text(
                'Go Home',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
