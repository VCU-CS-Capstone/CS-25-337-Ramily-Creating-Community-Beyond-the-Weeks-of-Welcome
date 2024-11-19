import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  // You can pass any required data through the constructor
  // For example, the current user's profile data
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // User data
  Map<String, dynamic> _currentUser = {
    'name': 'John Doe',
    'profilePicture': 'assets/default_profile.png', // Update with actual path or URL
  };

  // Sample news feed data
  List<Map<String, String>> _newsFeed = [
    {
      'title': 'Welcome to VCU!',
      'content': 'We are excited to have you on campus.',
    },
    {
      'title': 'Upcoming Events',
      'content': 'Don\'t miss the Welcome Week activities!',
    },
    // Add more news items as needed
  ];

  // Selected index for Bottom Navigation Bar
  int _selectedIndex = 0;

  // Pages for Bottom Navigation Bar
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // Initialize _pages with widgets for each tab
    _pages.add(_buildHomeContent());
    _pages.add(_buildMessagesContent());
    _pages.add(_buildProfileContent());
  }

  // Bottom Navigation Bar tap handler
  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RAMily',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
        ],
      ),
    );
  }

  // User Info Section
  Widget _buildUserInfoSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(_currentUser['profilePicture']),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Welcome, ${_currentUser['name']}',
              style: TextStyle(
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

  // Quick Access Buttons
  Widget _buildQuickAccessButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickButton(
            icon: Icons.map_outlined,
            label: 'Traditions',
            onTap: () {
              // Navigate to Traditions screen
            },
          ),
          _buildQuickButton(
            icon: Icons.people_outline,
            label: 'Matching',
            onTap: () {
              // Navigate to Matching screen
            },
          ),
          _buildQuickButton(
            icon: Icons.school_outlined,
            label: 'Rambassadors',
            onTap: () {
              // Navigate to Rambassadors screen
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
            padding: EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 28,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // News Feed Section
  Widget _buildNewsFeedSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _newsFeed.length,
      itemBuilder: (context, index) {
        final newsItem = _newsFeed[index];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              title: Text(
                newsItem['title']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                newsItem['content']!,
                style: TextStyle(color: Colors.black54),
              ),
              onTap: () {
                // Navigate to detailed news item if needed
              },
            ),
          ),
        );
      },
    );
  }

  // Home Content
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

  // Messages Content Placeholder
  Widget _buildMessagesContent() {
    return Center(
      child: Text(
        'Messages',
        style: TextStyle(fontSize: 18, color: Colors.black87),
      ),
    );
  }

  // Profile Content Placeholder
  Widget _buildProfileContent() {
    return Center(
      child: Text(
        'Profile',
        style: TextStyle(fontSize: 18, color: Colors.black87),
      ),
    );
  }

  // Drawer with resources
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(_currentUser['profilePicture']),
                ),
                SizedBox(width: 16),
                Text(
                  _currentUser['name'],
                  style: TextStyle(
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
            onTap: () {
              Navigator.pop(context);
              _launchURL('https://canvas.vcu.edu/');
            },
          ),
          _buildDrawerItem(
            icon: Icons.navigation_outlined,
            text: 'Navigate',
            onTap: () {
              Navigator.pop(context);
              _launchURL('https://navigate.vcu.edu/');
            },
          ),
          // Add more resources as needed
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
      title: Text(
        text,
        style: TextStyle(color: Colors.black87),
      ),
      onTap: onTap,
    );
  }

  // Helper method to launch URLs
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
