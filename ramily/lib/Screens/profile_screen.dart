// ProfileScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_editor.dart';
import 'constants.dart' as constants;

class ProfileScreen extends StatefulWidget {
  final String email;
  
  const ProfileScreen({super.key, required this.email});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  late Map<String, dynamic> _userData = {};
  
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }
  
  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        _navigateToLogin();
        return;
      }
      
      // Fetch user data from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();
      
      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        // If document doesn't exist, use basic info
        setState(() {
          _userData = {
            'profile_picture': '',
            'firstName': authUser.displayName?.split(' ').first ?? 'Guest',
            'lastName': (authUser.displayName?.split(' ').length ?? 0) > 1 
                ? authUser.displayName?.split(' ').last 
                : 'User',
            'name': authUser.displayName ?? 'Guest User',
            'email': authUser.email ?? widget.email,
            'major': 'Undeclared',
            'pronouns': 'Not specified',
            'interests': <String>[],
            'bio': 'No bio yet',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _userData = {
          'profile_picture': '',
          'name': 'Guest User',
          'email': widget.email,
          'major': 'Undeclared',
          'pronouns': 'Not specified',
          'interests': <String>[],
          'bio': 'No bio yet',
        };
        _isLoading = false;
      });
    }
  }
  
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
  
  Future<void> _logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    _navigateToLogin();
  }
  
  void _openEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(email: widget.email),
      ),
    ).then((_) {
      // Refresh data when returning from editor
      _fetchUserData();
    });
  }
  
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: constants.kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                      image: DecorationImage(
                        image: _userData['profile_picture'] != null && _userData['profile_picture'] != ''
                            ? FileImage(File(_userData['profile_picture']))
                            : const AssetImage('assets/logo.png') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _userData['name'] ?? 'Guest User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: constants.kDarkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData['email'] ?? widget.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileInfoCard(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _openEditor(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: constants.kVCUGold.withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      minimumSize: const Size(200, 46),
                      elevation: 0,
                    ),
                    child: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _logOut(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: constants.kPrimaryColor.withOpacity(0.7), width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      minimumSize: const Size(200, 46),
                    ),
                    child: const Text('Log Out', style: TextStyle(fontSize: 16, color: constants.kVCURed)),
                  ),
                ],
              ),
            ),
      ),
    );
  }
  
  Widget _buildProfileInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileInfoRow(
              icon: Icons.school,
              title: 'Major',
              value: _getMajorDisplay(),
            ),
            const Divider(height: 24),
            _buildProfileInfoRow(
              icon: Icons.person,
              title: 'Pronouns',
              value: _getPronounsDisplay(),
            ),
            const Divider(height: 24),
            _buildProfileInfoRow(
              icon: Icons.interests,
              title: 'Interests',
              value: _getInterestsDisplay(),
            ),
            const Divider(height: 24),
            _buildProfileInfoRow(
              icon: Icons.info_outline,
              title: 'Bio',
              value: _getBioDisplay(),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getMajorDisplay() {
    String major = _userData['major'] ?? 'Undeclared';
    if (major.contains('Not Listed') || major.contains('Undecided')) {
      return 'Undeclared';
    }
    return major;
  }
  
  String _getPronounsDisplay() {
    return _userData['pronouns'] == null || _userData['pronouns'] == '' 
        ? 'Not specified'
        : _userData['pronouns'];
  }
  
  String _getInterestsDisplay() {
    List<dynamic> interests = _userData['interests'] ?? [];
    if (interests.isEmpty) {
      return 'None added yet';
    }
    
    // Convert all interests to strings and join with commas
    return interests.map((e) => e.toString()).join(', ');
  }
  
  String _getBioDisplay() {
    return _userData['bio'] == null || _userData['bio'] == '' 
        ? 'No bio yet'
        : _userData['bio'];
  }
  
  Widget _buildProfileInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: constants.kVCUGold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: constants.kPrimaryColor.withOpacity(0.8), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: constants.kDarkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}