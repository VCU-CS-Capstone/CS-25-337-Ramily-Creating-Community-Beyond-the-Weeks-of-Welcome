// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_creation_screen.dart'; // Import ProfileCreationScreen

class LoginScreen extends StatefulWidget {
  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Key for the form
  final _formKey = GlobalKey<FormState>();

  // Hardcoded dummy credentials
  final String _dummyEmail = 'student@vcu.edu';
  final String _dummyPassword = 'password123';

  // Function to handle login
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      if (email == _dummyEmail && password == _dummyPassword) {
        // Navigate to the home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $email!')),
        );
      } else {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional: Set a background color
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 100.0),

            // Center the Stack
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Background Image behind the logo
                  Container(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/Paint_Ramily.png', // Your background image
                        height: 180.0, // Adjust size as needed
                        width: 180.0, // Equal to height for circle
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Word Logo Image
                  Image.asset(
                    'assets/Ramily_Titleblack.png', // Your word logo image
                    height: 100.0, // Adjust size as needed
                  ),
                ],
              ),
            ),

            SizedBox(height: 90.0),

            // Login Form
            Form(
              key: _formKey, // Assign the form key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      // Email validation
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      // Simple email validation
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.0),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    obscureText: true,
                    validator: (value) {
                      // Password validation
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 32.0),

                  // Login button
                  ElevatedButton(
                    onPressed: _handleLogin,
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: const Color.fromARGB(255, 240, 240, 243),
                      textStyle: TextStyle(fontSize: 18.0),
                    ),
                  ),

                  SizedBox(height: 16.0),

                  // Additional options (Sign Up)
                  TextButton(
                    onPressed: () {
                      // Navigate to Profile Creation Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileCreationScreen()),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
