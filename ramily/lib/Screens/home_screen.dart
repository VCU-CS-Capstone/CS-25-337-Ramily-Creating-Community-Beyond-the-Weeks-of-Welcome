import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional: Prevent user from navigating back to Profile Creation
      // by removing the back button in the AppBar
      appBar: AppBar(
        title: Text('RAMily Home'),
        automaticallyImplyLeading: false, // Hides the back button
      ),
      body: Center(
        child: Text(
          'Welcome to RAMily!',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
