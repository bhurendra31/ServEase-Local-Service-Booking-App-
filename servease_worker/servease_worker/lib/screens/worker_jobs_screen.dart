import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'worker_profile_screen.dart';

Future<void> openGoogleMaps(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// ================= LOGIC ONLY (NO UI) =================
/// 🔹 Combine Firestore date + time string
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

/// 🔹 Auto cancel expired pending bookings
Future<void> autoCancelExpiredBookings() async {
  final now = DateTime.now();

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('status', isEqualTo: 'pending')
      .get();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    if (data['date'] == null || data['time'] == null) continue;

    final bookingDT =
        combineDateAndTime(data['date'], data['time']);

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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // 🔥 ONLY LOGIC ADDED (NO UI CHANGE)
    autoCancelExpiredBookings();

    _loadWorkerData();
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
                subtitle: Text('Time: ${data['time']}'),
              ),
            );
          },
        );
      },
    );
  }

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
              child: ListTile(
                title: Text(data['serviceName']),
                subtitle: Text('Time: ${data['time']}'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'New Requests'),
            Tab(text: 'My Jobs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _pendingRequests(),
          _myJobs(),
        ],
      ),
    );
  }
}
