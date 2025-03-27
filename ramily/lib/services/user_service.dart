import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if the current user has a document in Firestore
  Future<void> ensureUserDocument() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Check if document exists
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!doc.exists) {
        // Create a basic document that will be completed later
        await _firestore.collection('users').doc(currentUser.uid).set({
          'email': currentUser.email ?? '',
          'name': currentUser.displayName ?? '',
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        });
        print('Created basic user document for ${currentUser.uid}');
      }
    } catch (e) {
      print('Error ensuring user document: $e');
    }
  }

  // Sync display name between Auth and Firestore
  Future<void> syncUserNameData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get the Firestore document
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        
        String firestoreName = userData['name'] ?? '';
        String authName = currentUser.displayName ?? '';
        
        // Case 1: Firestore has name but Auth doesn't
        if (firestoreName.isNotEmpty && authName.isEmpty) {
          await currentUser.updateDisplayName(firestoreName);
          print('Updated Auth display name from Firestore');
        }
        
        // Case 2: Auth has name but Firestore doesn't
        else if (firestoreName.isEmpty && authName.isNotEmpty) {
          // Try to split the display name into first and last name
          List<String> nameParts = authName.split(' ');
          String firstName = nameParts.first;
          String lastName = nameParts.length > 1 ? nameParts.last : '';
          
          await _firestore.collection('users').doc(currentUser.uid).update({
            'name': authName,
            'firstName': firstName,
            'lastName': lastName
          });
          print('Updated Firestore name from Auth');
        }
      }
    } catch (e) {
      print('Error syncing user data: $e');
    }
  }
  
  // Fix empty fields for specific user
  Future<void> fixEmptyFields(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> updates = {};
        
        // Check for each field that might be empty and update if needed
        if (!userData.containsKey('interests') || (userData['interests'] as List).isEmpty) {
          updates['interests'] = [];
        }
        
        if (!userData.containsKey('major') || userData['major'] == '') {
          updates['major'] = 'Major Not Listed/Undecided';
        }
        
        if (!userData.containsKey('pronouns') || userData['pronouns'] == '') {
          updates['pronouns'] = '';
        }
        
        if (!userData.containsKey('bio') || userData['bio'] == '') {
          updates['bio'] = '';
        }
        
        if (!userData.containsKey('bioPrompt') || userData['bioPrompt'] == '') {
          updates['bioPrompt'] = '';
        }
        
        if (!userData.containsKey('bioAnswer') || userData['bioAnswer'] == '') {
          updates['bioAnswer'] = '';
        }
        
        // Apply updates if needed
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(uid).update(updates);
          print('Fixed empty fields for user $uid');
        }
      }
    } catch (e) {
      print('Error fixing empty fields: $e');
    }
  }
  
  // Get user profile by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }
  
  // Get user profile by uid
  Future<Map<String, dynamic>?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user by id: $e');
      return null;
    }
  }
}