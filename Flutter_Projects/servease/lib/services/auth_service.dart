import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Email Login
  Future<User?> loginWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // ✅ Email Register
  Future<User?> registerWithEmail(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _saveUser(result.user!);
    return result.user;
  }

  // ✅ Save user to Firestore
  Future<void> _saveUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
