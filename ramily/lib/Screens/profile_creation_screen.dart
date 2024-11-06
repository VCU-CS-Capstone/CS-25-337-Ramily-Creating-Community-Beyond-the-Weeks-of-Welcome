// lib/screens/profile_creation_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController _customInterestController = TextEditingController();

  // Privacy policy-related state
  bool _privacyPolicyClicked = false;
  bool _privacyPolicyChecked = false;

  // Disclosure of student contact information-related state
  bool _contactInfoPolicyClicked = false;
  bool _contactInfoPolicyChecked = false;

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
  final List<String> _availableInterests = [
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
  Set<String> _selectedInterests = Set<String>();

  // Custom Interests
  int _customInterestsCount = 0;
  final int _maxCustomInterests = 2;
  final int _customInterestCharLimit = 15;
  final int _maxTotalInterests = 4; // Total interests limit

  final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery or camera
  Future<void> _pickImage() async {
    // Show the bottom sheet to choose from Gallery or Camera
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
                // Pick image from the gallery (default behavior)
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
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
                // Pick image from the camera
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
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
    if (_formKey.currentState!.validate() && _privacyPolicyChecked && _contactInfoPolicyChecked) {
      if (_selectedInterests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one interest')),
        );
        return;
      }

      // Collect all the data
      final profileData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'major': _selectedMajor,
        'pronouns': _selectedPronoun,
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests.toList(),
      };

      // Handle profile submission logic here
      // For example, send data to a server or save locally

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile Submitted Successfully!')),
      );

      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (!_privacyPolicyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please agree to the privacy policy')),
      );
    } else if (!_contactInfoPolicyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please agree to the Disclosure of student contact information')),
      );
    }
  }

  // Function to open privacy policy link
  Future<void> _openPrivacyPolicy() async {
    const url = 'https://www.vcu.edu/privacy-statement/#:~:text=Commitment%20to%20privacy,only%20to%20the%20extent%20necessary'; // VCU Privacy Policy
    if (await canLaunch(url)) {
      await launch(url);
      setState(() {
        _privacyPolicyClicked = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  // Function to open disclosure policy link
  Future<void> _openContactInfoPolicy() async {
    const url = 'https://registrar.vcu.edu/records/family-educational-rights-and-privacy-act/student-contact-information/'; // Student Contact Disclosure
    if (await canLaunch(url)) {
      await launch(url);
      setState(() {
        _contactInfoPolicyClicked = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the link')),
      );
    }
  }

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
              ),
              SizedBox(height: 16.0),

              // Interests Checkbox
              Text('Select Interests:'),
              Wrap(
                children: _availableInterests.map((interest) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FilterChip(
                      label: Text(interest),
                      selected: _selectedInterests.contains(interest),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (_selectedInterests.length < _maxTotalInterests) {
                              _selectedInterests.add(interest);
                            }
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),

              // Custom Interest (Allow up to 2 additional interests)
              if (_customInterestsCount < _maxCustomInterests)
                TextFormField(
                  controller: _customInterestController,
                  decoration: InputDecoration(
                    labelText: 'Custom Interest',
                    prefixIcon: Icon(Icons.add),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: _customInterestCharLimit,
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return null;
                    }
                    return 'Please enter a custom interest';
                  },
                ),
              SizedBox(height: 16.0),

              // Bio Field
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText:
                      'e.g., Passionate about technology and music. Love hiking on weekends.',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a bio' : null,
              ),
              SizedBox(height: 24.0),

              // Privacy Policy Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _privacyPolicyChecked,
                    onChanged: _privacyPolicyClicked
                        ? (bool? value) {
                            setState(() {
                              _privacyPolicyChecked = value!;
                            });
                          }
                        : null,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openPrivacyPolicy,
                      child: Text(
                        'I agree to the privacy policy.',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Disclosure of student contact information Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _contactInfoPolicyChecked,
                    onChanged: _contactInfoPolicyClicked
                        ? (bool? value) {
                            setState(() {
                              _contactInfoPolicyChecked = value!;
                            });
                          }
                        : null,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openContactInfoPolicy,
                      child: Text(
                        'I agree to the Disclosure of student contact information.',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.0),

              // Submit Button
              ElevatedButton(
                onPressed: _submitProfile,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
