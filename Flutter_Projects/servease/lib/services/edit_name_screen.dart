import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key});

  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  static const Color themeColor = Color(0xFF4A90E2);

  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = user?.displayName ?? '';
  }

  Future<void> _saveName() async {
    final newName = nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    await user!.updateDisplayName(newName);
    await user!.reload();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Name updated successfully')),
    );

    Navigator.pop(context, true); // ✅ notify profile screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Name'),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                ),
                onPressed: _saveName,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
