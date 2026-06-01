import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'worker_profile_screen.dart';
import 'package:geolocator/geolocator.dart';



Future<void> openGoogleMaps(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ================= MAP HELPERS =================

Future<void> openUserLocation(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );

  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched) {
    debugPrint('❌ Could not open location');
  }
}

Future<void> openDirections({
  required double bookingLat,
  required double bookingLng,
}) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$bookingLat,$bookingLng',
  );

  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched) {
    debugPrint('❌ Could not launch Google Maps');
  }
}

DateTime combineDateAndTime(Timestamp date, String time) {
  final datePart = date.toDate();
  final parts = time.split(' ');
  final hm = parts[0].split(':');

  int hour = int.parse(hm[0]);
  int minute = int.parse(hm[1]);
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

String formatBookingDate(Timestamp timestamp) {
  final date = timestamp.toDate();
  return '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year}';
}

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color themeColor = Color(0xFF4A90E2);

  final user = FirebaseAuth.instance.currentUser;

  bool isOnline = false;
  bool loading = true;

  String workerName = '';
  String workerServiceKey = '';

  double? workerLat;
  double? workerLng;

  late TabController _tabController;


// ================= 🔔 SAVE WORKER FCM TOKEN =================
Future<void> saveWorkerFcmToken() async {
  final worker = FirebaseAuth.instance.currentUser;
  if (worker == null) return;

  final token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await FirebaseFirestore.instance
        .collection('workers')
        .doc(worker.uid)
        .set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWorkerData();

    saveWorkerFcmToken(); // 🔔 ADD THIS LINE
    _getWorkerLocation(); // 👈 ADD THIS LINE

    autoCancelExpiredBookings();

    Timer.periodic(const Duration(seconds: 30), (_) async {
      await autoCancelExpiredBookings();
      if (mounted) setState(() {});
    });
  }

  Future<void> _getWorkerLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      workerLat = position.latitude;
      workerLng = position.longitude;
    });
  }

  Future<void> _loadWorkerData() async {
    final doc = await FirebaseFirestore.instance
        .collection('workers')
        .doc(user!.uid)
        .get();

    final data = doc.data()!;
    setState(() {
      workerName = data['name'];
      workerServiceKey = data['serviceKey'];
      isOnline = data['isOnline'];
      loading = false;
    });
  }

  double calculateDistanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const double earthRadius = 6371; // km

    final double dLat = _degToRad(lat2 - lat1);
    final double dLng = _degToRad(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  // ================= CONFIRM CANCEL JOB =================
  void _confirmCancelJob(String bookingId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Job'),
        content: const Text(
          'Are you sure you want to cancel this job?\n'
          'The customer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .update({
                'status': 'cancelled_by_worker',
                'cancelledAt': Timestamp.now(),
              });
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ================= NEW REQUESTS =================
  Widget _pendingRequests() {
    if (!isOnline) {
      return const Center(
        child: Text(
          'You are offline.\nGo online to receive requests.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceKey', isEqualTo: workerServiceKey)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

       
        if (docs.isEmpty) {
          return const Center(child: Text('No new requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(data['serviceName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('Time: ${data['time']}'),
                    if (data['date'] != null)
                      Text(
                        'Date: ${formatBookingDate(data['date'] as Timestamp)}',
                      ),

                    Text('Time: ${data['time']}'),
                    const SizedBox(height: 6),
                    if (data['bookingLat'] != null &&
                        data['bookingLng'] != null)
                      TextButton.icon(
                        icon: const Icon(Icons.location_on),
                        label: const Text('View Location'),
                        onPressed: () {
                          openUserLocation(
                            (data['bookingLat'] as num).toDouble(),
                            (data['bookingLng'] as num).toDouble(),
                          );
                        },
                      ),

                    if (workerLat != null &&
                        workerLng != null &&
                        data['bookingLat'] != null &&
                        data['bookingLng'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '📏 Distance: ${calculateDistanceKm(
                            lat1: workerLat!,
                            lng1: workerLng!,
                            lat2: (data['bookingLat'] as num).toDouble(),
                            lng2: (data['bookingLng'] as num).toDouble(),
                          ).toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(doc.id)
                            .update({
                          'status': 'rejected',
                          'rejectedAt': Timestamp.now(),
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(doc.id)
                            .update({
                          'status': 'accepted',
                          'workerId': user!.uid,
                          'acceptedAt': Timestamp.now(),
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= MY JOBS =================
  Widget _myJobs() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('workerId', isEqualTo: user!.uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No active jobs'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Title
                    Text(
                      data['serviceName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 🔹 Time
                    Text('Time: ${data['time']}'),

                    const SizedBox(height: 12),

                    // 🔹 ACTION BUTTONS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ❌ Cancel
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            _confirmCancelJob(doc.id);
                          },
                        ),

                        // 🧭 Directions
                        if (data['bookingLat'] != null &&
                            data['bookingLng'] != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            onPressed: () {
                              openDirections(
                                bookingLat:
                                    (data['bookingLat'] as num).toDouble(),
                                bookingLng:
                                    (data['bookingLng'] as num).toDouble(),
                              );
                            },
                          ),

                        // ✅ Complete
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(doc.id)
                                .update({
                              'status': 'completed',
                              'completedAt': Timestamp.now(),
                            });
                          },
                          child: const Text(
                            'Complete',
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
    );
  }
// ================= COMPLETED TASKS =================

  Widget _completedTasks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('workerId', isEqualTo: user!.uid)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No completed tasks yet'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final date = data['completedAt'] != null
                ? (data['completedAt'] as Timestamp)
                    .toDate()
                    .toString()
                    .split(' ')[0]
                : 'N/A';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                title: Text(data['serviceName'] ?? 'Service'),
                subtitle: Text('Completed on: $date'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'Welcome, $workerName',
          style: const TextStyle(color: Colors.white),
        ),

        /// 🔥 LIVE PROFILE IMAGE (REAL FIX)
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('workers')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String? photoUrl;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                photoUrl = data['photoUrl'];
              }

              return IconButton(
                icon: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, color: themeColor)
                      : null,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkerProfileScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: const Color.fromARGB(255, 41, 40, 40),
          tabs: const [
            Tab(text: 'New Requests'),
            Tab(text: 'My Jobs'),
            Tab(text: 'Completed Tasks'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOnline ? 'Status: Online' : 'Status: Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
                Switch(
                  value: isOnline,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (value) async {
                    setState(() => isOnline = value);
                    await FirebaseFirestore.instance
                        .collection('workers')
                        .doc(user!.uid)
                        .update({'isOnline': value});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _pendingRequests(),
                _myJobs(),
                _completedTasks(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
