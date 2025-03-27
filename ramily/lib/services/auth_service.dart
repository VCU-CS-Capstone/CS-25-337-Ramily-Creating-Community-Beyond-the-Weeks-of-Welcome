import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current authenticated user
  User? get currentUser => _auth.currentUser;

  // Register a user with email/password and complete profile data
  Future<User?> registerUser(String email, String password, String firstName, String lastName, Map<String, dynamic> profileData) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Set display name (full name)
      String fullName = '$firstName $lastName';
      await userCredential.user!.updateDisplayName(fullName);

      // Create a complete profile document in Firestore with all user data
      String uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set(profileData);

      print("Successfully created user and profile in Firestore: $uid");
      return userCredential.user;
    } catch (e) {
      print("Error registering user: $e");
      return null;
    }
  }

  // Sign in a user
  Future<User?> signInUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login timestamp
      String uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).update({
        'last_login': FieldValue.serverTimestamp()
      });
      
      return userCredential.user;
    } catch (e) {
      print("Error signing in user: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error getting user profile: $e");
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      
      // If name is being updated, also update Auth display name
      if (data.containsKey('firstName') || data.containsKey('lastName')) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          String firstName = data['firstName'] ?? userData['firstName'] ?? '';
          String lastName = data['lastName'] ?? userData['lastName'] ?? '';
          String fullName = '$firstName $lastName'.trim();
          
          if (fullName.isNotEmpty) {
            User? user = _auth.currentUser;
            if (user != null && user.uid == uid) {
              await user.updateDisplayName(fullName);
            }
          }
        }
      }
      
      return true;
    } catch (e) {
      print("Error updating user profile: $e");
      return false;
    }
  }
}