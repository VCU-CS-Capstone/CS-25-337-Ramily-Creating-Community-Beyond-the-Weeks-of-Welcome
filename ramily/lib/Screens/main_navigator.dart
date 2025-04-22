import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'constants.dart'; 


// Main app navigation approach
class MainNavigator extends StatefulWidget {
  final String email;
  
  const MainNavigator({super.key, required this.email});

  @override
  _MainNavigatorState createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(email: widget.email),
      ChatScreen(email: widget.email),
      ProfileScreen(email: widget.email),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // Fixed bottom navigation bar implementation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey[400],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}