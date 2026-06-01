import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingScreen extends StatefulWidget {
  final String providerName;
  final String service;

  const BookingScreen({
    super.key,
    required this.providerName,
    required this.service,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedAddress = 'Not provided';
  double latitude = 0.0;
  double longitude = 0.0;

  /// 🔹 Normalize DateTime to minute precision
  DateTime _toMinute(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);

  /// 🔹 Combine date + time
  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// 🔹 Check if booking is valid (FINAL AUTHORITY)
  bool _isValidBooking(DateTime bookingDT) {
    final now = _toMinute(DateTime.now());
    final booking = _toMinute(bookingDT);
    return booking.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 📅 DATE PICKER
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );

                if (pickedDate == null) return;

                selectedDate = pickedDate;
                selectedTime = null; // reset time
                setState(() {});
              },
              child: Text(
                selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${selectedDate!.toString().split(' ')[0]}',
              ),
            ),

            const SizedBox(height: 10),

            /// ⏰ TIME PICKER
            ElevatedButton(
              onPressed: selectedDate == null
                  ? null
                  : () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime == null) return;

                      final bookingDT = _combine(selectedDate!, pickedTime);

                      if (!_isValidBooking(bookingDT)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No past booking allowed'),
                          ),
                        );
                        return;
                      }

                      selectedTime = pickedTime;
                      setState(() {});
                    },
              child: Text(
                selectedTime == null
                    ? 'Select Time'
                    : 'Time: ${selectedTime!.format(context)}',
              ),
            ),

            const SizedBox(height: 20),

            /// ✅ CONFIRM BOOKING
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login')),
                  );
                  return;
                }

                if (selectedDate == null || selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Select date and time'),
                    ),
                  );
                  return;
                }

                final bookingDT = _combine(selectedDate!, selectedTime!);

                if (!_isValidBooking(bookingDT)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No past booking allowed'),
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('bookings').add({
                  'serviceKey': widget.service.toLowerCase(),
                  'serviceName': widget.service,
                  'providerName': widget.providerName,
                  'status': 'pending',
                  'userId': user.uid,
                  'userName': user.displayName ?? 'Customer',
                  'userPhone': user.phoneNumber ?? 'Not available',
                  'userAddress': selectedAddress, // String
                  'userLat': latitude, // double
                  'userLng': longitude, // double
                  'date': Timestamp.fromDate(selectedDate!),
                  'time': selectedTime!.format(context),
                  'createdAt': Timestamp.now(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking placed successfully'),
                  ),
                );

                Navigator.pop(context);
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
