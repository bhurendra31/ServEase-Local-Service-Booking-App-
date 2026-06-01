import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'worker_home_screen.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  final String phone; // ✅ RECEIVED FROM OTP

  const WorkerProfileSetupScreen({
    super.key,
    required this.phone,
  });

  @override
  State<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState
    extends State<WorkerProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? selectedService;
  bool isLoading = false;

  final List<String> services = [
  'Utensils Cleaning',
  'Bathroom & Surface',
  'Dusting',
  'Laundry',
  'Staircase',
  'Plumbing',
  'Electrician',
  'Car Washer',
];

  final user = FirebaseAuth.instance.currentUser;

  static const Color themeColor = Color(0xFF4A90E2);

  @override
  void initState() {
    super.initState();
    // ✅ Autofill phone from OTP screen
    _phoneController.text = widget.phone;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all details')),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseFirestore.instance
    .collection('workers')
    .doc(user!.uid)
    .set({
  'name': _nameController.text.trim(),
  'phone': widget.phone,
  'serviceKey': selectedService!.toLowerCase(), // 🔥 ADD THIS
  'serviceName': selectedService,               // optional UI
  'isOnline': false,
  'createdAt': Timestamp.now(),
});

    setState(() => isLoading = false);

    // ✅ Go to Worker Home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WorkerHomeScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 NAME
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 📞 PHONE (READ ONLY)
            TextField(
              controller: _phoneController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 🧰 SERVICE
            DropdownButtonFormField<String>(
              value: selectedService,
              items: services
                  .map(
                    (service) => DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedService = value);
              },
              decoration: const InputDecoration(
                labelText: 'Select Service',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                ),
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
