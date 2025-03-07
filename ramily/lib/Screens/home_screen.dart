import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'matching_screen.dart';
import 'profile_editor.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, dynamic> _currentUser;
  bool _isLoading = true;

  final List<Widget> _pages = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        setState(() {
          _currentUser = userQuery.docs.first.data();
          _pages.addAll([
            _buildHomeContent(),
            _buildMessagesContent(),
            _buildProfileContent(),
          ]);
          _isLoading = false;
        });
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  void _openEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditorScreen(email: widget.email,), // Navigate to the ProfileEditor screen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RAMily',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUserInfoSection(),
          _buildQuickAccessButtons(),
          _buildNewsFeedSection(),
        ],
      ),
    );
  }

  Widget _buildMessagesContent() {
    return const Center(
      child: Text(
        'Messages',
        style: TextStyle(fontSize: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildProfileContent() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading profile information.'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No profile data found.'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: userData['profile_picture'] != ''
                      ? FileImage(File(userData['profile_picture']))
                          as ImageProvider
                      : const AssetImage('assets/logo.png'),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Name: ${userData['name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Email: ${userData['email']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Major: ${userData['major']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Pronouns: ${userData['pronouns'] ?? 'Not specified'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Interests: ${userData['interests'].join(', ')}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Bio: ${userData['bio']}',
                style: const TextStyle(fontSize: 16),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openEditor,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18.0),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _currentUser['profile_picture'] != null &&
                    _currentUser['profile_picture'].isNotEmpty
                ? FileImage(File(_currentUser['profile_picture']))
                : const AssetImage('assets/logo.png')
                    as ImageProvider,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Welcome, ${_currentUser['name']}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickButton(
            icon: Icons.map_outlined,
            label: 'Traditions',
            onTap: () {
              // TODO: Navigate to Traditions screen
            },
          ),
          _buildQuickButton(
            icon: Icons.people_outline,
            label: 'Matching',
            onTap: () {
              // Navigate to MatchingScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchingScreen(
                  ),
                ),
              );
            },
          ),
          _buildQuickButton(
            icon: Icons.school_outlined,
            label: 'Rambassadors',
            onTap: () {
              // TODO: Navigate to Rambassadors screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, size: 28, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildNewsFeedSection() {
    final List<Map<String, String>> newsFeed = [
      {
        'title': 'Welcome to VCU!',
        'content': 'We are excited to have you on campus.',
      },
      {
        'title': 'Upcoming Events',
        'content': 'Don\'t miss the Welcome Week activities!',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newsFeed.length,
      itemBuilder: (context, index) {
        final newsItem = newsFeed[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              title: Text(
                newsItem['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                newsItem['content']!,
                style: const TextStyle(color: Colors.black54),
              ),
              onTap: () {
                // Could navigate to a detailed news page
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _currentUser['profile_picture'] != null &&
                          _currentUser['profile_picture'].isNotEmpty
                      ? FileImage(File(_currentUser['profile_picture']))
                      : const AssetImage('assets/logo.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 16),
                Text(
                  _currentUser['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.school_outlined,
            text: 'Canvas',
            onTap: () => _launchURL('https://canvas.vcu.edu/'),
          ),
          _buildDrawerItem(
            icon: Icons.navigation_outlined,
            text: 'Navigate',
            onTap: () => _launchURL('https://navigate.vcu.edu/'),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.black87),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.black87),
            ),
            onTap: _logOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(text, style: const TextStyle(color: Colors.black87)),
      onTap: onTap,
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}
