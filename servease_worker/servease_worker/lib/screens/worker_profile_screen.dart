import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../utils/cloudinary_config.dart';
import 'worker_login_screen.dart'; // ✅ ADD THIS

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  User? user = FirebaseAuth.instance.currentUser;
  bool _uploading = false;

  // ================= IMAGE PICK & UPLOAD =================
  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/dx36430fh/image/upload'),
    );

    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath('file', picked.path),
    );

    final response = await request.send();
    final resStr = await response.stream.bytesToString();
    final data = json.decode(resStr);

    final imageUrl = data['secure_url'];
    await user!.updatePhotoURL(imageUrl);

    await FirebaseFirestore.instance.collection('workers').doc(user!.uid).set({
      'photoUrl': imageUrl,
    }, SetOptions(merge: true)); // 🔥 IMPORTANT

    await user!.reload();

    setState(() {
      user = FirebaseAuth.instance.currentUser;
      _uploading = false;
    });
  }

  // ================= DELETE ACCOUNT =================
  Future<void> _deleteAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(currentUser.uid)
          .delete();

      await currentUser.delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WorkerLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Re-login required to delete account'),
        ),
      );
    }
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WorkerLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workers')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ================= PROFILE IMAGE =================
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: themeColor,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _uploading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: themeColor,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(data['phone'] ?? ''),
                const SizedBox(height: 20),

                _infoTile(
                  'Status',
                  data['isOnline'] == true ? 'Online' : 'Offline',
                ),

                const Spacer(),

                // ================= DELETE ACCOUNT =================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'Are you sure you want to permanently delete your account?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteAccount();
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ================= LOGOUT =================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Do you want to logout from your account?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _logout();
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
