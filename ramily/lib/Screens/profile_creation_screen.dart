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
  final TextEditingController _customInterestController = TextEditingController();
  final TextEditingController _promptAnswerController = TextEditingController();
  final TextEditingController _customMajorController = TextEditingController();

  // Privacy policy-related state
  bool _privacyPolicyChecked = false;

  // Disclosure of student contact information-related state
  bool _contactInfoPolicyChecked = false;

  // Profile Picture
  File? _profileImage;

  // List of pronouns
  final List<String> _pronouns = [
    'He/Him',
    'She/Her',
    'They/Them',
    'Prefer not to say',
    'Other',
  ];

  // List of majors (including 'Major Not Listed')
  final List<String> _allMajors = [
    'Accounting',
    'African American Studies',
    'Anthropology',
    'Art History',
    'Arts',
    'Bioinformatics',
    'Biology',
    'Biomedical Engineering',
    'Business',
    'Chemical and Life Science Engineering',
    'Chemistry',
    'Cinema',
    'Clinical Radiation Sciences',
    'Communication Arts',
    'Computer Engineering',
    'Computer Science',
    'Craft and Material Studies',
    'Criminal Justice',
    'Dance and Choreography',
    'Dental Hygiene',
    'Early Childhood Education and Teaching',
    'Economics',
    'Electrical Engineering',
    'Elementary Education and Teaching',
    'English',
    'Environmental Studies',
    'Fashion',
    'Finance',
    'Financial Technology',
    'Foreign Language',
    'Forensic Science',
    'Gender, Sexuality and Women’s Studies',
    'Graphic Design',
    'Health and Physical Education',
    'Health Services',
    'Health, Physical Education and Exercise Science',
    'History',
    'Homeland Security and Emergency Preparedness',
    'Human and Organizational Development',
    'Information Systems',
    'Interdisciplinary Studies',
    'Interior Design',
    'International Studies',
    'Kinetic Imaging',
    'Marketing',
    'Mass Communications',
    'Mathematical Sciences',
    'Mechanical Engineering',
    'Medical Laboratory Sciences',
    'Music',
    'Nursing',
    'Painting and Printmaking',
    'Pharmaceutical Sciences',
    'Philosophy',
    'Photography and Film',
    'Physics',
    'Political Science',
    'Psychology',
    'Real Estate',
    'Religious Studies',
    'Science',
    'Sculpture',
    'Social Work',
    'Sociology',
    'Special Education and Teaching',
    'Supply Chain Management',
    'Theatre',
    'Urban and Regional Studies',
    'Major Not Listed', // Add this at the end
  ];

  // Selected interests
  Set<String> _selectedInterests = Set<String>();

  // Selected values
  String? _selectedPronoun;
  String? _selectedMajor;

  // Custom Interests
  int _customInterestsCount = 0;
  final int _maxCustomInterests = 2;
  final int _customInterestCharLimit = 15;
  final int _maxTotalInterests = 4; // Total interests limit

  final ImagePicker _picker = ImagePicker();

  // Bio Prompts
  final List<String> _bioPrompts = [
    'What I\'m most excited for at VCU is ___',
    'I chose VCU because ___',
  ];
  String? _selectedPrompt;

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
    if (_formKey.currentState!.validate() &&
        _privacyPolicyChecked &&
        _contactInfoPolicyChecked) {
      if (_selectedInterests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one interest')),
        );
        return;
      }

      if (_selectedPrompt == null ||
          _promptAnswerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please complete the bio prompt')),
        );
        return;
      }

      // Determine the major to use
      String major = '';
      if (_selectedMajor == 'Major Not Listed') {
        if (_customMajorController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter your major')),
          );
          return;
        } else {
          major = _customMajorController.text.trim();
        }
      } else {
        major = _selectedMajor!;
      }

      // Collect all the data
      final profileData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'major': major,
        'pronouns': _selectedPronoun,
        'interests': _selectedInterests.toList(),
        'bio': _selectedPrompt!
            .replaceAll('___', _promptAnswerController.text.trim()),
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
        SnackBar(content: Text('Please agree to the Privacy Policy')),
      );
    } else if (!_contactInfoPolicyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please agree to the Disclosure of Student Contact Information')),
      );
    }
  }

  // Function to open privacy policy link
  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.vcu.edu/privacy-statement/');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  // Function to open disclosure policy link
  Future<void> _openContactInfoPolicy() async {
    final Uri url = Uri.parse(
        'https://registrar.vcu.edu/records/family-educational-rights-and-privacy-act/student-contact-information/');
    if (!await launchUrl(url)) {
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
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Major',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMajor,
                  isExpanded: true, // Fixes overflow
                  items: _allMajors
                      .map((major) => DropdownMenuItem(
                            value: major,
                            child: Text(
                              major,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMajor = value;
                      if (value != 'Major Not Listed') {
                        _customMajorController.clear();
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select your major' : null,
                ),
              ),
              SizedBox(height: 16.0),

              // Custom Major Input (Shown only when 'Major Not Listed' is selected)
              if (_selectedMajor == 'Major Not Listed') ...[
                TextFormField(
                  controller: _customMajorController,
                  decoration: InputDecoration(
                    labelText: 'Enter Your Major',
                    prefixIcon: Icon(Icons.edit),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your major'
                      : null,
                ),
                SizedBox(height: 16.0),
              ],

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

              // Interests Section
              Text(
                'Select Your Interests',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),

              // Instructions
              Text(
                'Choose up to $_maxTotalInterests interests that you are passionate about. You can also add up to $_maxCustomInterests custom interests.',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.0),

              // Interest Selection Grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 2.5, // Adjust as needed
                ),
                itemCount: _availableInterests.length,
                itemBuilder: (context, index) {
                  final interest = _availableInterests[index];
                  final isSelected = _selectedInterests.contains(interest);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest);
                        } else {
                          if (_selectedInterests.length < _maxTotalInterests) {
                            _selectedInterests.add(interest);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'You can select up to $_maxTotalInterests interests in total')),
                            );
                          }
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 4.0,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          interest,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16.0),

              // Custom Interest Input
              TextField(
                controller: _customInterestController,
                maxLength: _customInterestCharLimit,
                decoration: InputDecoration(
                  labelText: 'Add Custom Interest',
                  hintText:
                      'Enter your interest (max $_customInterestCharLimit chars)',
                  prefixIcon: Icon(Icons.add),
                  border: OutlineInputBorder(),
                  counterText: '', // Hide character counter
                  suffixIcon: IconButton(
                    icon: Icon(Icons.check),
                    onPressed: _customInterestsCount < _maxCustomInterests
                        ? () {
                            final customInterest =
                                _customInterestController.text.trim();
                            if (customInterest.isNotEmpty) {
                              if (customInterest.length >
                                  _customInterestCharLimit) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Interest must be less than $_customInterestCharLimit characters')),
                                );
                                return;
                              }
                              if (_selectedInterests
                                      .contains(customInterest) ||
                                  _availableInterests
                                      .contains(customInterest)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Interest already added')),
                                );
                              } else if (_selectedInterests.length <
                                  _maxTotalInterests) {
                                setState(() {
                                  _selectedInterests.add(customInterest);
                                  _customInterestsCount++;
                                  _customInterestController.clear();
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'You can select up to $_maxTotalInterests interests in total')),
                                );
                              }
                            }
                          }
                        : null, // Disable button if limit reached
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Display Selected Interests
              Text(
                'Selected Interests (${_selectedInterests.length}/$_maxTotalInterests):',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _selectedInterests.map((interest) {
                  final isCustomInterest =
                      !_availableInterests.contains(interest);
                  return Chip(
                    label: Text(interest),
                    backgroundColor:
                        isCustomInterest ? Colors.orangeAccent : null,
                    onDeleted: () {
                      setState(() {
                        _selectedInterests.remove(interest);
                        if (isCustomInterest) {
                          _customInterestsCount--;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),

              // Prompt Section
              Text(
                'Complete a Prompt',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),

              // Prompt Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select a Prompt',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                value: _selectedPrompt,
                items: _bioPrompts.map((prompt) {
                  return DropdownMenuItem(
                    value: prompt,
                    child: Text(prompt.replaceAll('___', '...')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPrompt = value;
                    _promptAnswerController.clear(); // Clear previous answer
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a prompt' : null,
              ),
              SizedBox(height: 16.0),

              // If a prompt is selected, show the answer field
              if (_selectedPrompt != null) ...[
                TextFormField(
                  controller: _promptAnswerController,
                  decoration: InputDecoration(
                    labelText: 'Your Answer',
                    hintText: _selectedPrompt != null
                        ? _selectedPrompt!.replaceAll('___', '...')
                        : 'Fill in the blank',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100, // Set your desired character limit
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please complete the prompt'
                      : null,
                ),
                SizedBox(height: 16.0),
              ],

              // Privacy Policy Checkbox using CheckboxListTile
              CheckboxListTile(
                value: _privacyPolicyChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _privacyPolicyChecked = value ?? false;
                  });
                },
                title: GestureDetector(
                  onTap: _openPrivacyPolicy,
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              // Disclosure of student contact information Checkbox using CheckboxListTile
              CheckboxListTile(
                value: _contactInfoPolicyChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _contactInfoPolicyChecked = value ?? false;
                  });
                },
                title: GestureDetector(
                  onTap: _openContactInfoPolicy,
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Disclosure of Student Contact Information',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              SizedBox(height: 32.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
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

  // List of available interests (add this if missing)
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
}
