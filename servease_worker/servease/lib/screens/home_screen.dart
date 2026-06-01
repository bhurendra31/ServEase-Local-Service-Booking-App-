import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_address_screen.dart';
import '../models/service_model.dart';
import 'service_booking_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  final String userAddress = 'Janakpur, Nepal';
  final user = FirebaseAuth.instance.currentUser;

  // 🔍 SEARCH CONTROLLER
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Timer? _autoCancelTimer;

  final List<ServiceModel> services = [
    ServiceModel(name: 'Utensils Cleaning', icon: '🍽️'),
    ServiceModel(name: 'Bathroom_Surface', icon: '🚿'),
    ServiceModel(name: 'Dusting', icon: '🧽'),
    ServiceModel(name: 'Laundry', icon: '👕'),
    ServiceModel(name: 'Staircase', icon: '🪜'),
    ServiceModel(name: 'Plumbing', icon: '🚰'),
    ServiceModel(name: 'Electrician', icon: '⚡'),
    ServiceModel(name: 'Car Washer', icon: '🚗'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    autoCancelExpiredBookings();

    _autoCancelTimer = Timer.periodic(
    const Duration(minutes: 1),
    (_) {
      autoCancelExpiredBookings();
    },
  );
  }

  @override
  void dispose() {
    _autoCancelTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  // ================= DATE + TIME HELPER =================
  DateTime? combineDateAndTime(dynamic date, dynamic time) {
    if (date == null || time == null) return null;
    if (date is! Timestamp || time is! String) return null;

    final datePart = date.toDate();
    final parts = time.split(' ');
    if (parts.length != 2) return null;

    final hm = parts[0].split(':');
    if (hm.length != 2) return null;

    int hour = int.tryParse(hm[0]) ?? 0;
    int minute = int.tryParse(hm[1]) ?? 0;
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

 // ================= AUTO CANCEL LOGIC =================
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

      if (bookingDT != null && bookingDT.isBefore(now)) {
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


  // ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: _currentIndex == 0 ? _homeContent() : _bookingsContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark), label: 'Bookings'),
        ],
      ),
    );
  }

  // ================= HOME TAB =================
  Widget _homeContent() {
    // 🔍 FILTER SERVICES
    final filteredServices = services.where((service) {
      return service.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF4A90E2),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(Icons.person,
                                    color: Color(0xFF4A90E2))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ServEase',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Local Service Booking',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyAddressScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.location_on,
                              color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Janakpur, Nepal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 🔍 SEARCH FIELD (WORKING)
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🧹 SERVICES GRID (FILTERED)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final service = filteredServices[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ServiceBookingScreen(serviceName: service.name),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(service.icon, style: const TextStyle(fontSize: 55)),
                      const SizedBox(height: 10),
                      Text(
                        service.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= BOOKINGS TAB =================
  Widget _bookingsContent() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A90E2),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() => _currentIndex = 0); // go back to Home tab
            },
          ),
          title:
              const Text('My Bookings', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed/Cancalled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _bookingList(user.uid, true),
            _bookingList(user.uid, false),
          ],
        ),
      ),
    );
  }

  // ================= BOOKING LIST =================
  Widget _bookingList(String userId, bool showUpcoming) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();

        final bookings = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bookingDT = combineDateAndTime(data['date'], data['time']);

          if (bookingDT == null) return false;
          final status = data['status'];

          if (showUpcoming) {
            return bookingDT.isAfter(now) &&
                (status == 'pending' || status == 'accepted');
          } else {
            return status == 'completed' ||
                status == 'cancelled' ||
                status == 'cancelled_by_worker';
          }
        }).toList();

        if (bookings.isEmpty) {
          return const Center(
            child: Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        bookings.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          Timestamp getLatestTimestamp(Map<String, dynamic> data) {
            return (data['cancelledAt'] ??
                data['completedAt'] ??
                data['createdAt']) as Timestamp;
          }

          final aTime = getLatestTimestamp(aData).toDate();
          final bTime = getLatestTimestamp(bData).toDate();

          return bTime.compareTo(aTime); // 🔥 latest first
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'];

            Color chipColor;
            switch (status) {
              case 'pending':
                chipColor = Colors.orange;
                break;
              case 'accepted':
              case 'completed':
                chipColor = Colors.green;
                break;
              default:
                chipColor = Colors.red;
            }

            return Card(
              child: ListTile(
                title: Text(
                  data['serviceName'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${(data['date'] as Timestamp).toDate().toString().split(' ')[0]}',
                    ),
                    Text('Time: ${data['time']}'),

                    // 🔹 SHOW WORKER DETAILS AFTER ACCEPT
                    if (status == 'accepted' || status == 'completed')
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.blue),
                        onPressed: () async {
                          final workerId = data['workerId'];

                          if (workerId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Worker not assigned yet')),
                            );
                            return;
                          }

                          final workerDoc = await FirebaseFirestore.instance
                              .collection('workers')
                              .doc(workerId)
                              .get();

                          if (!workerDoc.exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Worker profile not found')),
                            );
                            return;
                          }

                          final worker = workerDoc.data()!;

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(worker['name'] ?? 'Worker'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (worker['photoUrl'] != null)
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          NetworkImage(worker['photoUrl']),
                                    ),
                                  const SizedBox(height: 10),
                                  Text('Phone: ${worker['phone'] ?? 'N/A'}'),
                                  if (worker['rating'] != null)
                                    Text('Rating: ⭐ ${worker['rating']}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    //worker completed the job

                    if (status == 'completed' && data['rating'] == null)
                      TextButton(
                        onPressed: () async {
                          int selectedRating = 0;

                          await showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: const Text('Rate Worker'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(5, (index) {
                                            return IconButton(
                                              icon: Icon(
                                                Icons.star,
                                                color: index < selectedRating
                                                    ? Colors.amber
                                                    : Colors.grey,
                                                size: 32,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  selectedRating = index + 1;
                                                });
                                              },
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Tap a star to rate',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: selectedRating == 0
                                            ? null
                                            : () async {
                                                await FirebaseFirestore.instance
                                                    .collection('bookings')
                                                    .doc(doc.id)
                                                    .update({
                                                  'rating': selectedRating
                                                });

                                                Navigator.pop(dialogContext);
                                              },
                                        child: const Text('Submit'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: const Text('Rate Worker'),
                      ),

                    // 🔴 WORKER CANCEL MESSAGE
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        status == 'cancelled_by_worker'
                            ? 'Cancelled by Worker'
                            : status[0].toUpperCase() + status.substring(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: chipColor,
                    ),
                    if (showUpcoming && status == 'pending')
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(doc.id)
                              .update({
                            'status': 'cancelled',
                            'cancelledAt': Timestamp.now(),
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
}



