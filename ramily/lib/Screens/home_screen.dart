import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'matching_screen.dart';
import 'profile_editor.dart';
import 'package:ramily/Screens/constants.dart' as constants;
import 'package:ramily/Screens/traditions_screen.dart';
import 'matching_onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _currentUser;
  bool _isLoading = true;
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserData();
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      // Fetch user data from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();

      if (docSnapshot.exists) {
        _currentUser = docSnapshot.data() as Map<String, dynamic>;
      } else {
        // If no document exists, use basic info from Auth
        _currentUser = {
          'profile_picture': '',
          'firstName': authUser.displayName?.split(' ').first ?? 'Guest',
          'lastName': (authUser.displayName?.split(' ').length ?? 0) > 1 
              ? authUser.displayName?.split(' ').last 
              : 'User',
          'name': authUser.displayName ?? 'Guest User',
          'email': authUser.email ?? 'unknown@example.com',
          'major': 'Undeclared',
          'pronouns': 'Not specified',
          'interests': <String>[],
          'bio': 'No bio yet',
        };
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Fallback to basic info if Firestore fetch fails
      _currentUser = {
        'profile_picture': '',
        'firstName': authUser.displayName?.split(' ').first ?? 'Guest',
        'lastName': (authUser.displayName?.split(' ').length ?? 0) > 1 
            ? authUser.displayName?.split(' ').last 
            : 'User',
        'name': authUser.displayName ?? 'Guest User',
        'email': authUser.email ?? 'unknown@example.com',
        'major': 'Undeclared',
        'pronouns': 'Not specified',
        'interests': <String>[],
        'bio': 'No bio yet',
      };
    }

    setState(() {
      _isLoading = false;
      _animController.forward();
    });
  }

  void _openEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(email: widget.email),
      ),
    ).then((_) {
      // Refresh data when returning from profile editor
      _fetchUserData();
    });
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: constants.kVCUBlack,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: constants.kVCUBlack),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: constants.kDarkText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logOut();
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: constants.kVCURed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Check if the user has completed the matching onboarding
  Future<void> _openMatchingScreen() async {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Check if this user has completed onboarding in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      // Check if document exists and has the onboarding flag
      final bool onboardingCompleted = userDoc.exists && 
          userDoc.data()?.containsKey('matchingOnboardingCompleted') == true &&
          userDoc.data()?['matchingOnboardingCompleted'] == true;
      
      if (onboardingCompleted) {
        // If onboarding is completed, go directly to matching screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MatchingScreen()),
        );
      } else {
        // If first time, show onboarding
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MatchingOnboardingScreen()),
        );
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
      // If there's an error, default to showing the matching screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MatchingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constants.kVCUWhite,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: constants.kVCUGold))
            : AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildStatCards(),
                                  const SizedBox(height: 24),
                                  _buildActionRequired(),
                                  const SizedBox(height: 24),
                                  _buildCampusEventsSection(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Use firstName from Firestore or fallback
    String displayName = _currentUser['firstName'] ?? 
                         (_currentUser['name']?.split(' ').first ?? 'Guest');
                         
    // Capitalize first letter if not already capitalized
    displayName = _capitalizeFirstLetter(displayName);

    // Format the major display
    String majorDisplay = _currentUser['major'] ?? 'Undeclared';
    // If major is too long or contains "Not Listed", simplify it
    if (majorDisplay.contains('Not Listed') || majorDisplay.contains('Undecided')) {
      majorDisplay = 'Undeclared';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Profile picture
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: constants.kVCUWhite, width: 2),
              boxShadow: [
                BoxShadow(
                  color: constants.kVCUBlack.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              image: DecorationImage(
                image: _currentUser['profile_picture'] != ''
                    ? FileImage(File(_currentUser['profile_picture']))
                    : const AssetImage('assets/logo.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: constants.kVCUBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: constants.kVCUGold),
                    const SizedBox(width: 4),
                    Text(
                      majorDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        color: constants.kDarkText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Settings dropdown menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined, color: constants.kVCUBlack),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'edit_profile') {
                _openEditor();
              } else if (value == 'logout') {
                _showSignOutDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'edit_profile',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: constants.kVCUBlack, size: 20),
                    const SizedBox(width: 12),
                    const Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: constants.kVCURed, size: 20),
                    const SizedBox(width: 12),
                    const Text('Log Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        // Traditions Button - using VCU Blue
        Expanded(
          child: _buildStatCardButton(
            title: "Traditions",
            color: constants.kVCUGold,
            icon: Icons.map_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TraditionsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardButton(
            title: "Matching",
            color: constants.kVCUGold,
            icon: Icons.people_outline,
            onTap: _openMatchingScreen, // Use the new method for checking onboarding status
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardButton({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: constants.kVCUBlack,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: constants.kVCUBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: constants.kVCUBlack,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRequired() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Action Required",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: constants.kVCUBlack,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: constants.kVCURed,
                shape: BoxShape.circle,
              ),
              child: const Text(
                "1",
                style: TextStyle(color: constants.kVCUWhite, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          color: constants.kVCUWhite,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: constants.kVCUGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: constants.kVCUGreen, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Verify Student ID",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: constants.kVCUBlack,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Required to access all campus features",
                        style: TextStyle(
                          color: constants.kDarkText,fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "1 hr",
                  style: TextStyle(
                    color: constants.kDarkText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampusEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Campus Events",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: constants.kVCUBlack,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "See all",
                style: TextStyle(color: constants.kVCUBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          title: "Welcome Week Kickoff",
          description: "Join us for food, games, and meet fellow students",
          date: "March 25",
          location: "Student Commons",
          color: constants.kVCUPurple,
          icon: Icons.celebration,
        ),
        const SizedBox(height: 16),
        _buildEventCard(
          title: "Ram Spirit Rally",
          description: "Show your VCU pride and cheer on the Rams!",
          date: "March 28",
          location: "Siegel Center",
          color: constants.kAccentColor,
          icon: Icons.sports,
        ),
        const SizedBox(height: 16),
        _buildEventCard(
          title: "Major & Minor Fair",
          description: "Explore academic programs and career opportunities",
          date: "April 2",
          location: "University Student Commons",
          color: constants.kTraditionsColor,
          icon: Icons.school,
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required String title,
    required String description,
    required String date,
    required String location,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: constants.kVCUWhite,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: constants.kVCUBlack,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: constants.kDarkText,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: constants.kDarkText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        color: constants.kDarkText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: constants.kVCUGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Join",
                    style: TextStyle(
                      color: constants.kVCUBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}