import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  final user = FirebaseAuth.instance.currentUser!;
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  File? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    nameController.text = user.displayName ?? '';
    emailController.text = user.email ?? '';
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);

    try {
      // 🔹 Update Name
      if (nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(nameController.text.trim());
      }

      // 🔹 Update Email (Firebase safe way)
      if (emailController.text.trim() != user.email &&
          emailController.text.isNotEmpty) {
        await user.verifyBeforeUpdateEmail(
          emailController.text.trim(),
        );
      }

      // 🔹 Upload Image
      if (_image != null) {
        final imageUrl =
            await CloudinaryService.uploadImage(_image!);
        if (imageUrl != null) {
          await user.updatePhotoURL(imageUrl);
        }
      }

      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null) as ImageProvider?,
                child: user.photoURL == null && _image == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                ),
                onPressed: _loading ? null : _saveProfile,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
