import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ================= DATE + TIME COMBINE =================
DateTime combineDateAndTime(Timestamp date, String time) {
  final datePart = date.toDate();

  final parts = time.split(' ');
  final hm = parts[0].split(':');

  int hour = int.tryParse(hm[0]) ?? 0;
  int minute = int.tryParse(hm[1]) ?? 0;
  final period = parts.length > 1 ? parts[1] : 'AM';

  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;

  return DateTime(
    datePart.year,
    datePart.month,
    datePart.day,
    hour,
    minute,
  );
}

/// ================= SAFE BOOKING DATE =================
DateTime getBookingDate(Map<String, dynamic> data) {
  if (data['date'] == null || data['time'] == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return combineDateAndTime(
    data['date'] as Timestamp,
    data['time'] as String,
  );
}

/// ================= LATEST ACTION DATE =================
/// 🔥 This decides the order in the list
DateTime getLatestActionDate(Map<String, dynamic> data) {
  if (data['cancelledAt'] != null && data['cancelledAt'] is Timestamp) {
    return (data['cancelledAt'] as Timestamp).toDate();
  }

  // fallback for old records
  return getBookingDate(data);
}

class CancelledOrdersScreen extends StatelessWidget {
  const CancelledOrdersScreen({super.key});

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'Cancelled Orders',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user?.uid)
            .where('status', whereIn: ['cancelled', 'cancelled_by_worker'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No cancelled orders'));
          }

          final bookings = snapshot.data!.docs;

          /// 🔥 SORT BY MOST RECENT ACTION
          bookings.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aDT = getLatestActionDate(aData);
            final bDT = getLatestActionDate(bData);

            return bDT.compareTo(aDT); // latest first
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data =
                  bookings[index].data() as Map<String, dynamic>;

              final status = data['status'] ?? 'cancelled';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    data['serviceName'] ?? 'Service',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${data['date'] != null ? (data['date'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}',
                      ),
                      Text('Time: ${data['time'] ?? 'N/A'}'),
                      if (status == 'cancelled_by_worker')
                        const Text(
                          'This booking was cancelled by the worker.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      status == 'cancelled_by_worker'
                          ? 'Cancelled by Worker'
                          : 'Cancelled',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
