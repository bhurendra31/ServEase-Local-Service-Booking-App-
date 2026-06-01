import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 COMBINE DATE + TIME INTO DATETIME
DateTime combineDateAndTime(Timestamp date, String time) {
  final datePart = date.toDate();

  final parts = time.split(' ');
  final hm = parts[0].split(':');

  int hour = int.parse(hm[0]);
  final int minute = int.parse(hm[1]);
  final period = parts[1];

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

/// 🔥 AUTO-CANCEL EXPIRED BOOKINGS (FIRESTORE)
Future<void> autoCancelExpiredBookings() async {
  final now = DateTime.now();

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('status', isEqualTo: 'pending')
      .get();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    if (data['date'] == null || data['time'] == null) continue;

    final bookingDT = combineDateAndTime(
      data['date'] as Timestamp,
      data['time'] as String,
    );

    if (bookingDT.isBefore(now)) {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(doc.id)
          .update({
        'status': 'cancelled',
        'cancelledBy': 'system',
        'cancelledAt': Timestamp.now(),
      });
    }
  }
}

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  final worker = FirebaseAuth.instance.currentUser;

  String workerServiceKey = '';
  String workerName = '';
  String workerPhone = '';

  bool loading = true;

  Timer? _uiRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWorkerServiceKey();  
    autoCancelExpiredBookings(); // 🔥 Initial cleanup

    // 🔁 Repeat every 1 minute
    _uiRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        await autoCancelExpiredBookings();
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  /// 🔹 LOAD worker data
  Future<void> _loadWorkerServiceKey() async {
    if (worker == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('workers')
        .doc(worker!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        workerServiceKey = data['serviceKey'] ?? '';
        workerName = data['name'] ?? '';
        workerPhone = data['phone'] ?? '';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (worker == null) {
      return const Scaffold(
        body: Center(child: Text('Worker not logged in')),
      );
    }

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'Pending Requests',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('serviceKey', isEqualTo: workerServiceKey)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();

          /// 🔥 UI-SIDE FILTER
          final bookings = snapshot.data!.docs.where((doc) {
  final data = doc.data() as Map<String, dynamic>;

  // ⛔ Skip expired bookings
  if (data['date'] == null || data['time'] == null) return false;

  final bookingDT = combineDateAndTime(
    data['date'] as Timestamp,
    data['time'] as String,
  );

  if (bookingDT.isBefore(DateTime.now())) return false;

  // ⛔ Hide booking if THIS worker already rejected it
  final rejectedWorkers =
      (data['rejectedWorkers'] ?? []) as List<dynamic>;

  if (rejectedWorkers.contains(worker!.uid)) return false;

  return true;
}).toList();

          
          // final bookings = snapshot.data!.docs.where((doc) {
          //   final data = doc.data() as Map<String, dynamic>;

          //   if (data['date'] == null || data['time'] == null) return false;

          //   final bookingDT = combineDateAndTime(
          //     data['date'] as Timestamp,
          //     data['time'] as String,
          //   );

          //   return bookingDT.isAfter(now);
          // }).toList();

          if (bookings.isEmpty) {
            return const Center(
              child: Text('No pending booking requests'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['serviceName'] ?? 'Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Date: ${(data['date'] as Timestamp).toDate().toString().split(' ')[0]}',
                      ),
                      Text('Time: ${data['time']}'),
                      if (data['createdAt'] != null)
                        Text(
                          'Booked on: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // OutlinedButton(
                          //   style: OutlinedButton.styleFrom(
                          //     side: const BorderSide(color: Colors.red),
                          //   ),
                          //   onPressed: () async {
                          //     await FirebaseFirestore.instance
                          //         .collection('bookings')
                          //         .doc(doc.id)
                          //         .update({
                          //       'status': 'cancelled_by_worker',
                          //       'cancelledAt': Timestamp.now(),
                          //     });
                          //   },
                          //   child: const Text(
                          //     'Reject',
                          //     style: TextStyle(color: Colors.red),
                          //   ),
                          // ),

                          OutlinedButton(
  onPressed: () async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(doc.id)
        .update({
      'rejectedWorkers': FieldValue.arrayUnion([worker!.uid]),
    });
  },
  child: const Text(
    'Reject',
    style: TextStyle(color: Colors.red),
  ),
),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(doc.id)
                                  .update({
                                'status': 'accepted',
                                'workerId': worker!.uid,
                                'workerName': workerName,
                                'workerPhone': workerPhone,
                                'acceptedAt': Timestamp.now(),
                              });
                              // await FirebaseFirestore.instance
                              //     .collection('bookings')
                              //     .doc(doc.id) // ✅ FIXED
                              //     .update({
                              //   'status': 'accepted',
                              //   'workerId': worker!.uid, // ✅ REQUIRED
                              //   'workerName': workerName, // optional
                              //   'workerPhone': workerPhone, // optional
                              //   'acceptedAt': Timestamp.now(),
                              // });
                            },
                            child: const Text(
                              'Accept',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
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
