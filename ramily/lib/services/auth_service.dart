import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register a user
  Future<User?> registerUser(String email, String password, String username) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user ID
      String uid = userCredential.user!.uid;

      // Add user details to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'created_at': DateTime.now(),
      });

      return userCredential.user;
    } catch (e) {
      print("Error registering user: $e");
      return null;
    }
  }
}
