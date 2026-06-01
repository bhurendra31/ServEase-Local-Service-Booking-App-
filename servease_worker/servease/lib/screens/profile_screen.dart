import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'my_address_screen.dart';
import 'about_us_screen.dart';
import '../services/edit_name_screen.dart';
import 'home_screen.dart';
import 'cancelled_orders_screen.dart';
import 'login_screen.dart';
import '../utils/cloudinary_config.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  User? user = FirebaseAuth.instance.currentUser;
  bool _uploading = false;

  // 🔹 PICK + UPLOAD IMAGE
  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => _uploading = true);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/dx36430fh/image/upload',
      ),
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
    await user!.reload();

    setState(() {
      user = FirebaseAuth.instance.currentUser;
      _uploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // 🔙 BACK BUTTON
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
      ),

      body: Column(
        children: [
          // 🔵 HEADER
          Container(
            height: height * 0.28,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person,
                              size: 50, color: themeColor)
                          : null,
                    ),

                    // ✏️ IMAGE EDIT ICON
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
                              : const Icon(Icons.edit,
                                  size: 18, color: themeColor),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ✏️ EDIT NAME
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.displayName ?? 'ServEase User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditNameScreen(),
                          ),
                        );

                        if (updated == true) {
                          await user!.reload();
                          setState(() {
                            user = FirebaseAuth.instance.currentUser;
                          });
                        }
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  user?.phoneNumber ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 📘 MY BOOKINGS
          _menuItem(
            icon: Icons.bookmark,
            label: 'My Bookings',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(initialIndex: 1),
                ),
              );
            },
          ),

          // 📍 MY ADDRESS
          _menuItem(
            icon: Icons.location_on,
            label: 'My Address',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyAddressScreen(),
                ),
              );
            },
          ),

          // ❌ CANCELLED ORDERS
          _menuItem(
            icon: Icons.cancel,
            label: 'Cancelled Orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CancelledOrdersScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // ℹ️ ABOUT US
          _menuItem(
            icon: Icons.info_outline,
            label: 'About Us',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutUsScreen(),
                ),
              );
            },
          ),

          // 📜 TERMS
          _menuItem(
            icon: Icons.description_outlined,
            label: 'Terms & Conditions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TermsConditionsScreen(),
                ),
              );
            },
          ),

          // 🔐 PRIVACY
          _menuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrivacyPolicyScreen(),
                ),
              );
            },
          ),

          // 🆘 HELP
          _menuItem(
            icon: Icons.support_agent,
            label: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelpSupportScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // 🚪 LOGOUT
          _menuItem(
            icon: Icons.logout,
            label: 'Logout',
            color: Colors.red,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = themeColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
