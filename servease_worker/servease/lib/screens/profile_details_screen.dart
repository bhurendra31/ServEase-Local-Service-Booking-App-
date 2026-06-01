import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController =
      TextEditingController();
  final TextEditingController lastNameController =
      TextEditingController();
  final TextEditingController emailController =
      TextEditingController();
  final TextEditingController addressController =
      TextEditingController();

  bool isLoading = false;

  // ================= SAVE PROFILE =================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'profileCompleted': true,
      });

      // ✅ Redirect to Home ONLY after save
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // 🔒 Cannot go back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),

              _inputField(
                controller: firstNameController,
                label: 'First Name',
                icon: Icons.person,
              ),

              const SizedBox(height: 15),

              _inputField(
                controller: lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 15),

              _inputField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                      .hasMatch(value)) {
                    return 'Enter valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              _inputField(
                controller: addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
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
                          'Save & Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELD WIDGET =================
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ??
          (value) =>
              value == null || value.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
