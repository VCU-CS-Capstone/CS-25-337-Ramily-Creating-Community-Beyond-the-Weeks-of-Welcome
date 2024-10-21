import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String title;

  HomeScreen({this.title = 'Home'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RAMily Home'),
        automaticallyImplyLeading: false, // Hides the back button
      ),
      body: Center(
        child: Text(
          'Welcome to RAMily!',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
