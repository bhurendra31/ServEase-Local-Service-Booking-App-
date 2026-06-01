// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'booking_status_screen.dart';
// import '../constants/service_keys.dart';

// class ServiceBookingScreen extends StatefulWidget {
//   final String serviceName;

//   const ServiceBookingScreen({
//     super.key,
//     required this.serviceName,
//   });

//   @override
//   State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
// }

// class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
//   DateTime? selectedDate;
//   TimeOfDay? selectedTime;

//   static const Color themeColor = Color(0xFF4A90E2);

//   Future<void> _confirmBooking() async {
//     if (selectedDate == null || selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select date & time')),
//       );
//       return;
//     }

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final serviceKey = serviceKeyMap[widget.serviceName];

//     if (serviceKey == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid service selected')),
//       );
//       return;
//     }

//     final bookingDoc = await FirebaseFirestore.instance
//         .collection('bookings')
//         .add({
//       'userId': user.uid,
//       'serviceName': widget.serviceName,
//       'serviceKey': serviceKey, // 🔥 FIXED
//       'date': Timestamp.fromDate(selectedDate!),
//       'time': selectedTime!.format(context),
//       'status': 'pending',
//       'workerId': null,
//       'createdAt': Timestamp.now(),
//     });

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BookingStatusScreen(
//           bookingId: bookingDoc.id,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: themeColor,
//         title: Text(widget.serviceName,
//             style: const TextStyle(color: Colors.white)),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: _confirmBooking,
//               child: const Text('Confirm Booking'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_status_screen.dart';
import '../constants/service_keys.dart';

class ServiceBookingScreen extends StatefulWidget {
  final String serviceName;

  const ServiceBookingScreen({
    super.key,
    required this.serviceName,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  static const Color themeColor = Color(0xFF4A90E2);

  // ================= SLOT AVAILABILITY CHECK =================
  Future<bool> _isSlotAvailable({
    required DateTime date,
    required String time,
    required String serviceKey,
  }) async {
    final query = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceKey', isEqualTo: serviceKey)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .where('time', isEqualTo: time)
        .where('status', whereIn: ['pending', 'accepted'])
        .get();

    return query.docs.isEmpty; // true = slot free
  }

  // ================= CONFIRM BOOKING =================
  Future<void> _confirmBooking() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date & time')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final serviceKey = serviceKeyMap[widget.serviceName];
    if (serviceKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid service selected')),
      );
      return;
    }

    final timeString = selectedTime!.format(context);

    // 🔒 CHECK SLOT AVAILABILITY
    final isAvailable = await _isSlotAvailable(
      date: selectedDate!,
      time: timeString,
      serviceKey: serviceKey,
    );

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('This time slot is already booked. Please choose another.'),
        ),
      );
      return;
    }

    // ✅ CREATE BOOKING
    final docRef = await FirebaseFirestore.instance.collection('bookings').add({
      'userId': user.uid,
      'serviceName': widget.serviceName,
      'serviceKey': serviceKey,
      'date': Timestamp.fromDate(selectedDate!),
      'time': timeString,
      'status': 'pending',
      'workerId': null,
      'createdAt': Timestamp.now(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingStatusScreen(
          bookingId: docRef.id,
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.serviceName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSelectionCard(
              title: 'Select Date',
              value: selectedDate == null
                  ? 'Choose date'
                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              icon: Icons.calendar_today,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                    selectedTime = null;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            _buildSelectionCard(
              title: 'Select Time',
              value: selectedTime == null
                  ? 'Choose time'
                  : selectedTime!.format(context),
              icon: Icons.access_time,
              onTap: () async {
                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select date first'),
                    ),
                  );
                  return;
                }

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime != null) {
                  setState(() => selectedTime = pickedTime);
                }
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _confirmBooking,
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  // ================= REUSABLE CARD =================
  Widget _buildSelectionCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: themeColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
