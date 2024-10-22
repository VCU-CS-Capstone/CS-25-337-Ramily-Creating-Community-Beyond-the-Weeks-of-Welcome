import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart'; // Import the HomeScreen

class ProfileCreationScreen extends StatefulWidget {
  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for user input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Profile Picture
  File? _profileImage;

  // List of majors
  final List<String> _majors = [
    'Computer Science',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Civil Engineering',
    'Biology',
    'Business Administration',
    'Psychology',
    'Other',
  ];

  // List of pronouns
  final List<String> _pronouns = [
    'He/Him',
    'She/Her',
    'They/Them',
    'Prefer not to say',
    'Other',
  ];

  // List of interests
  final List<String> _interests = [
    'Sports',
    'Music',
    'Art',
    'Technology',
    'Literature',
    'Science',
    'Travel',
    'Gaming',
    'Photography',
    'Cooking',
    'Reading',
    'Fitness',
    'Movies',
    'Dance',
    'Writing',
  ];

  // Selected values
  String? _selectedMajor;
  String? _selectedPronoun;
  String? _selectedInterest1;
  String? _selectedInterest2;
  String? _selectedInterest3;
  String? _selectedInterest4;

  final ImagePicker _picker = ImagePicker();

  // Functions to pick image from gallery or camera
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _profileImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a Photo'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _profileImage = File(image.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      // Handle profile submission logic here (e.g., send data to backend)

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile Submitted Successfully!')),
      );

      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  // Helper methods to get available interests for each dropdown to prevent duplicates
  List<String> get _availableInterests1 => _interests;
  List<String> get _availableInterests2 => _selectedInterest1 != null
      ? _interests.where((interest) => interest != _selectedInterest1).toList()
      : _interests;
  List<String> get _availableInterests3 => _selectedInterest1 != null &&
          _selectedInterest2 != null
      ? _interests
          .where((interest) =>
              interest != _selectedInterest1 && interest != _selectedInterest2)
          .toList()
      : _interests;
  List<String> get _availableInterests4 => _selectedInterest1 != null &&
          _selectedInterest2 != null &&
          _selectedInterest3 != null
      ? _interests
          .where((interest) =>
              interest != _selectedInterest1 &&
              interest != _selectedInterest2 &&
              interest != _selectedInterest3)
          .toList()
      : _interests;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RAMily - Create Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.indigo,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.0),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              SizedBox(height: 16.0),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                    return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Major Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Major',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                value: _selectedMajor,
                items: _majors
                    .map((major) => DropdownMenuItem(
                          value: major,
                          child: Text(major),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMajor = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select your major' : null,
              ),
              SizedBox(height: 16.0),

              // Pronouns Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Pronouns',
                  prefixIcon: Icon(Icons.accessibility),
                  border: OutlineInputBorder(),
                ),
                value: _selectedPronoun,
                items: _pronouns
                    .map((pronoun) => DropdownMenuItem(
                          value: pronoun,
                          child: Text(pronoun),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPronoun = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select your pronouns' : null,
              ),
              SizedBox(height: 16.0),

              // Bio Field
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a bio' : null,
              ),
              SizedBox(height: 16.0),

              // Interests Section
              Text(
                'Select Your Interests',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),

              // Interest 1
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Interest 1',
                  prefixIcon: Icon(Icons.interests),
                  border: OutlineInputBorder(),
                ),
                value: _selectedInterest1,
                items: _availableInterests1
                    .map((interest) => DropdownMenuItem(
                          value: interest,
                          child: Text(interest),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInterest1 = value;
                    // Reset subsequent interests if necessary
                    _selectedInterest2 = null;
                    _selectedInterest3 = null;
                    _selectedInterest4 = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an interest' : null,
              ),
              SizedBox(height: 16.0),

              // Interest 2
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Interest 2',
                  prefixIcon: Icon(Icons.interests),
                  border: OutlineInputBorder(),
                ),
                value: _selectedInterest2,
                items: _availableInterests2
                    .map((interest) => DropdownMenuItem(
                          value: interest,
                          child: Text(interest),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInterest2 = value;
                    // Reset subsequent interests if necessary
                    _selectedInterest3 = null;
                    _selectedInterest4 = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an interest' : null,
              ),
              SizedBox(height: 16.0),

              // Interest 3
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Interest 3',
                  prefixIcon: Icon(Icons.interests),
                  border: OutlineInputBorder(),
                ),
                value: _selectedInterest3,
                items: _availableInterests3
                    .map((interest) => DropdownMenuItem(
                          value: interest,
                          child: Text(interest),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInterest3 = value;
                    // Reset subsequent interests if necessary
                    _selectedInterest4 = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an interest' : null,
              ),
              SizedBox(height: 16.0),

              // Interest 4
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Interest 4',
                  prefixIcon: Icon(Icons.interests),
                  border: OutlineInputBorder(),
                ),
                value: _selectedInterest4,
                items: _availableInterests4
                    .map((interest) => DropdownMenuItem(
                          value: interest,
                          child: Text(interest),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInterest4 = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an interest' : null,
              ),
              SizedBox(height: 32.0),

              // Submit Button
              SizedBox(
                width: double.infinity, // Makes the button take full width
                child: ElevatedButton(
                  onPressed: _submitProfile,
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
