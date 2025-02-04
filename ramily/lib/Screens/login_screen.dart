import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_creation_screen.dart'; // Import ProfileCreationScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Key for the form
  final _formKey = GlobalKey<FormState>();

  // Dummy password
  final String _dummyPassword = 'dummyPassword123!';

  // Function to handle login
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = 'dummyPassword123!'; // Use the shared dummy password

      try {
        // Sign in with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user;

        if (user != null) {
          // Check and fetch user data from Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            // If user data doesn't exist in Firestore, create a new entry
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'email': email,
              'createdAt': DateTime.now(),
            });
          }

          // Navigate to the HomeScreen with user data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(email: email),
            ),
          );

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, $email!')),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        } else {
          message = 'Login failed. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 100.0),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/Paint_Ramily.png',
                        height: 180.0,
                        width: 180.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/Ramily_Titleblack.png',
                    height: 100.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90.0),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32.0),
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: const Color.fromARGB(255, 240, 240, 243),
                      textStyle: const TextStyle(fontSize: 18.0),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileCreationScreen(),
                        ),
                      );
                    },
                    child: const Text(
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
