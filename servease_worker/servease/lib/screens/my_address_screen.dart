import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'select_location_map_screen.dart';

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({super.key});

  @override
  State<MyAddressScreen> createState() => _MyAddressScreenState();
}

class _MyAddressScreenState extends State<MyAddressScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController addressController = TextEditingController();

  // 🔹 USE CURRENT LOCATION
  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permission permanently denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.first;

      final address =
          '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('addresses')
          .add({
        'address': address,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location added')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
    }
  }

  // 🔹 DELETE ADDRESS
  Future<void> _deleteAddress(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('addresses')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: themeColor,
        title:
            const Text('My Addresses', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ➕ ADD ADDRESS
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectLocationMapScreen(),
                ),
              );

              if (result != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('addresses')
                    .add({
                  'address': result['address'],
                  'latitude': result['lat'],
                  'longitude': result['lng'],
                  'createdAt': Timestamp.now(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address added from map')),
                );
              }
            },
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: const [
                  Icon(Icons.add, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Add address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),

          // 📍 USE CURRENT LOCATION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location, color: themeColor),
                label: const Text(
                  'Use current location',
                  style: TextStyle(
                      color: themeColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: themeColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'SAVED ADDRESSES',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 ADDRESS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('addresses')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No saved addresses'));
                }

                final addresses = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final doc = addresses[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: themeColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              data['address'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteAddress(doc.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
