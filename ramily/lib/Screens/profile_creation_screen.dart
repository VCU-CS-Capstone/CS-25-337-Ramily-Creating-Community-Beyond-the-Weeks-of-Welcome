import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramily/services/auth_service.dart';
import 'main_navigator.dart';
import 'constants.dart' as constants;
import 'package:image_cropper/image_cropper.dart';


class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track current step in the form
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _customInterestController = TextEditingController();
  final TextEditingController _promptAnswerController = TextEditingController();
  final TextEditingController _customMajorController = TextEditingController();

  // Privacy policy states
  bool _privacyPolicyChecked = false;
  bool _contactInfoPolicyChecked = false;

  // Profile Picture
  File? _profileImage;
  bool _isImagePickerActive = false;

  // Pronouns
  final List<String> _pronouns = [
    'He/Him',
    'She/Her',
    'They/Them',
    'He/They',
    'She/They',
    'All Pronouns',
    'Prefer not to say',
    'Other',
  ];
  String? _selectedPronoun;

  // Majors
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
    'Gender, Sexuality and Womens Studies',
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
    'Major Not Listed',
  ];
  String? _selectedMajor;

  // Interests
  final Set<String> _selectedInterests = <String>{};
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
    'Volunteering',
    'Sustainability',
    'Fashion',
    'Entrepreneurship',
    'Politics',
    'History',
    'Podcasts',
  ];
  int _customInterestsCount = 0;
  final int _maxCustomInterests = 2;
  final int _customInterestCharLimit = 15;
  final int _requiredInterests = 5; // Changed to require exactly 5 interests

  // Bio prompts
  final List<String> _bioPrompts = [
    'What I\'m most excited for at VCU is ___',
    'I chose VCU because ___',
    'One thing I hope to accomplish during my time at VCU is ___',
    'My favorite spot on campus is ___',
    'Something most people don\'t know about me is ___',
    'When I\'m not studying, you can find me ___',
    'My favorite class so far has been ___',
    'I\'m passionate about ___',
    'My dream career is ___',
    'My favorite thing about Richmond is ___',
  ];
  String? _selectedPrompt;

  // Pick image
  // Update the _pickImage method to include cropping functionality
  Future<void> _pickImage() async {
    if (_isImagePickerActive) return;
    
    setState(() {
      _isImagePickerActive = true;
    });
    
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  
                  if (image != null) {
                    // Launch the cropper
                    await _cropImage(File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  
                  if (image != null) {
                    // Launch the cropper
                    await _cropImage(File(image.path));
                  }
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _profileImage = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ).then((_) {
        setState(() {
          _isImagePickerActive = false;
        });
      });
    } catch (e) {
      setState(() {
        _isImagePickerActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing camera or gallery: $e')),
      );
    }
  }

  // Crop the selected image
 Future<void> _cropImage(File imageFile) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: imageFile.path,
    aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0), // Forces square crop
    compressQuality: 100, // 100% quality
    compressFormat: ImageCompressFormat.jpg,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Your Profile Picture',
        toolbarColor: constants.kPrimaryColor,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
        showCropGrid: true,
      ),
      IOSUiSettings(
        title: 'Crop Your Profile Picture',
        aspectRatioLockEnabled: true,
        minimumAspectRatio: 1.0,
      ),
    ],
  );

  if (croppedFile != null) {
    setState(() {
      _profileImage = File(croppedFile.path);
    });
  }
}

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _firstNameController.text.trim().isNotEmpty &&
               _lastNameController.text.trim().isNotEmpty &&
               _emailController.text.trim().isNotEmpty &&
               RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim());
      case 1: // Major & Pronouns
        if (_selectedMajor == null) return false;
        if (_selectedMajor == 'Major Not Listed' && _customMajorController.text.trim().isEmpty) return false;
        return true; // Pronouns are optional
      case 2: // Interests
        return _selectedInterests.length == _requiredInterests; // Changed to require exactly 5 interests
      case 3: // Bio
        return _selectedPrompt != null && _promptAnswerController.text.trim().isNotEmpty;
      case 4: // Privacy Policy
        return _privacyPolicyChecked && _contactInfoPolicyChecked;
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (!_validateCurrentStep()) {
      // Show appropriate error message
      String errorMessage;
      switch (_currentStep) {
        case 0:
          errorMessage = 'Please fill in all required fields with valid information.';
          break;
        case 1:
          errorMessage = 'Please select your major.';
          break;
        case 2:
          errorMessage = 'Please select exactly $_requiredInterests interests.'; // Updated message
          break;
        case 3:
          errorMessage = 'Please complete the bio prompt.';
          break;
        case 4:
          errorMessage = 'Please agree to both policies.';
          break;
        default:
          errorMessage = 'Please complete all required fields.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }
    
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitProfile();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate() &&
        _privacyPolicyChecked &&
        _contactInfoPolicyChecked) {
      
      // Validate interests count
      if (_selectedInterests.length != _requiredInterests) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select exactly $_requiredInterests interests')),
        );
        // Go back to interests step
        setState(() {
          _currentStep = 2;
        });
        return;
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Determine major
      String major = _selectedMajor == 'Major Not Listed'
          ? _customMajorController.text.trim()
          : _selectedMajor ?? 'Major Not Listed/Undecided';

      // Get first and last name
      final String firstName = _firstNameController.text.trim();
      final String lastName = _lastNameController.text.trim();
      final String fullName = '$firstName $lastName';

      // Format the bio to include the prompt
      String bioPrompt = _selectedPrompt ?? '';
      String bioAnswer = _promptAnswerController.text.trim();
      String formattedBio = bioPrompt.replaceAll('___', bioAnswer);

      // Build profile data map with all required fields
      final profileData = {
        'firstName': firstName,
        'lastName': lastName,
        'name': fullName,
        'email': _emailController.text.trim(),
        'major': major,
        'pronouns': _selectedPronoun ?? '', // Default to empty string if null
        'interests': _selectedInterests.toList(), // Converting Set to List
        'bio': formattedBio,
        'bioPrompt': bioPrompt,
        'bioAnswer': bioAnswer,
        'profile_picture': _profileImage?.path ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      };

      final String email = profileData['email'] as String;
      const String password = 'dummyPassword123!';

      try {
        // Register the user with Firebase Auth
        User? user = await _authService.registerUser(
          email, 
          password, 
          firstName, 
          lastName, 
          profileData,
        );

        // Close the loading dialog
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        if (user != null) {
          // Double check that document was created with all fields
          DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
          
          if (doc.exists) {
            Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
            
            // Check for missing fields and update if needed
            Map<String, dynamic> updates = {};
            if (!userData.containsKey('interests')) updates['interests'] = _selectedInterests.toList();
            if (!userData.containsKey('bio')) updates['bio'] = formattedBio;
            if (!userData.containsKey('major')) updates['major'] = major;
            if (!userData.containsKey('pronouns')) updates['pronouns'] = _selectedPronoun ?? '';
            if (!userData.containsKey('bioPrompt')) updates['bioPrompt'] = bioPrompt;
            if (!userData.containsKey('bioAnswer')) updates['bioAnswer'] = bioAnswer;
            
            // Apply any missing fields
            if (updates.isNotEmpty) {
              await _firestore.collection('users').doc(user.uid).update(updates);
            }
          }

          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigator(email: email),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile Created Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // User creation failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Close the loading dialog if it's still open
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        
        // If the email is already in use, sign them in instead of failing
        if (e.code == 'email-already-in-use') {
          try {
            // Show sign-in loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            
            // Sign in with the same dummy password
            User? existingUser = await _authService.signInUser(email, password);

            // Close the loading dialog
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }

            if (existingUser != null) {
              final String uid = existingUser.uid;

              // Check if the document exists
              final docRef = _firestore.collection('users').doc(uid);
              final docSnap = await docRef.get();

              if (!docSnap.exists) {
                // Create the doc if it doesn't exist
                await docRef.set(profileData);
              }

              // Navigate to HomeScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainNavigator(email: email),
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, $firstName!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sign-in failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (signInError) {
            // Close the loading dialog if it's still open
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sign-in failed: $signInError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Handle other FirebaseAuth exceptions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (generalError) {
        // Close the loading dialog if it's still open
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        
        // Any non-FirebaseAuthException
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $generalError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_privacyPolicyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Privacy Policy')),
      );
    } else if (!_contactInfoPolicyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the Disclosure of Student Contact Information')),
      );
    }
  }

  // Open privacy policy
  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.vcu.edu/privacy-statement/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  // Open contact info policy
  Future<void> _openContactInfoPolicy() async {
    final Uri url = Uri.parse(
        'https://registrar.vcu.edu/records/family-educational-rights-and-privacy-act/student-contact-information/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return "Basic Information";
      case 1:
        return "Academic Details";
      case 2:
        return "Your Interests";
      case 3:
        return "About You";
      case 4:
        return "Privacy & Policies";
      default:
        return "Create Profile";
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          bool isActive = index == _currentStep;
          bool isCompleted = index < _currentStep;
          
          return Row(
            children: [
              // Step indicator
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive 
                      ? constants.kPrimaryColor
                      : isCompleted 
                          ? Colors.green
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted 
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              // Connector line
              if (index < _totalSteps - 1)
                Container(
                  width: 20,
                  height: 2,
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile Picture
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300], // Updated to match editor
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null, // Only use image when it exists
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: constants.kPrimaryColor,
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24.0),

        // First Name Field
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            labelStyle: TextStyle(color: constants.kPrimaryColor),
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter your first name' : null,
        ),
        const SizedBox(height: 16.0),

        // Last Name Field
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            labelStyle: TextStyle(color: constants.kPrimaryColor),
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter your last name' : null,
        ),
        const SizedBox(height: 16.0),

        // Email Field
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: constants.kPrimaryColor),
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter your email';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAcademicDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Major Dropdown
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Major',
              labelStyle: TextStyle(color: constants.kPrimaryColor),
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
            value: _selectedMajor,
            isExpanded: true,
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
        const SizedBox(height: 16.0),

        // Custom Major
        if (_selectedMajor == 'Major Not Listed') ...[
          TextFormField(
            controller: _customMajorController,
            decoration: const InputDecoration(
              labelText: 'Enter Your Major',
              prefixIcon: Icon(Icons.edit),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your major'
                : null,
          ),
          const SizedBox(height: 16.0),
        ],

        // Pronouns
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Pronouns',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          value: _selectedPronoun,
          hint: const Text('Select your pronouns (optional)'),
          isExpanded: true,
          items: _pronouns
              .map((pronoun) => DropdownMenuItem(
                    value: pronoun,
                    child: Text(pronoun),
                  ))
              .toList(), onChanged: (value) {
            setState(() {
              _selectedPronoun = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Interests header with counter - updated to match editor
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: _selectedInterests.length == _requiredInterests
                ? Colors.green.withOpacity(0.1)
                : constants.kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(
                _selectedInterests.length == _requiredInterests 
                    ? Icons.check_circle 
                    : Icons.favorite,
                color: _selectedInterests.length == _requiredInterests 
                    ? Colors.green 
                    : constants.kPrimaryColor,
                size: 20,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Required: ${_selectedInterests.length}/$_requiredInterests interests selected',
                style: TextStyle(
                  color: _selectedInterests.length == _requiredInterests 
                      ? Colors.green 
                      : constants.kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // Interest grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 2.5,
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
                    if (_selectedInterests.length < _requiredInterests) {
                      _selectedInterests.add(interest);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You must select exactly $_requiredInterests interests. Remove one to add another.',
                          ),
                        ),
                      );
                    }
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? constants.kPrimaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: constants.kPrimaryColor.withOpacity(0.3),
                            offset: const Offset(0, 3),
                            blurRadius: 4.0,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      interest,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16.0),

        // Custom Interest
        TextField(
          controller: _customInterestController,
          maxLength: _customInterestCharLimit,
          decoration: InputDecoration(
            labelText: 'Add Custom Interest',
            hintText: 'Enter your interest (max $_customInterestCharLimit chars)',
            prefixIcon: const Icon(Icons.add),
            border: const OutlineInputBorder(),
            counterText: '',
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: (_selectedInterests.length < _requiredInterests && _customInterestsCount < _maxCustomInterests)
                  ? () {
                      final customInterest = _customInterestController.text.trim();
                      if (customInterest.isNotEmpty) {
                        if (customInterest.length > _customInterestCharLimit) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Interest must be less than $_customInterestCharLimit characters',
                              ),
                            ),
                          );
                          return;
                        }
                        if (_selectedInterests.contains(customInterest) ||
                            _availableInterests.contains(customInterest)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Interest already added'),
                            ),
                          );
                        } else if (_selectedInterests.length < _requiredInterests) {
                          setState(() {
                            _selectedInterests.add(customInterest);
                            _customInterestsCount++;
                            _customInterestController.clear();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You must select exactly $_requiredInterests interests. Remove one to add another.',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Selected interests chips
        if (_selectedInterests.isNotEmpty) ...[
          const Text(
            'Your Selected Interests:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _selectedInterests.map((interest) {
              final isCustomInterest = !_availableInterests.contains(interest);
              return Chip(
                label: Text(interest),
                backgroundColor: isCustomInterest 
                    ? Colors.orangeAccent 
                    : constants.kPrimaryColor.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isCustomInterest 
                      ? Colors.white 
                      : constants.kPrimaryColor,
                ),
                deleteIconColor: isCustomInterest 
                    ? Colors.white 
                    : constants.kPrimaryColor,
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
        ],
      ],
    );
  }

  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt
        const Text(
          'Tell Us About Yourself',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        const Text(
          'Select a prompt below and complete it. This helps other students get to know you better!',
          style: TextStyle(fontSize: 14.0),
        ),
        const SizedBox(height: 16.0),
        
        // Prompt selection
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Select a Prompt',
            labelStyle: TextStyle(color: constants.kPrimaryColor),
            prefixIcon: Icon(Icons.format_quote),
            border: OutlineInputBorder(),
          ),
          value: _selectedPrompt,
          isExpanded: true,
          items: _bioPrompts.map((prompt) {
            return DropdownMenuItem(
              value: prompt,
              child: Text(
                prompt.replaceAll('___', '...'),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPrompt = value;
              _promptAnswerController.clear();
            });
          },
          validator: (value) =>
              value == null ? 'Please select a prompt' : null,
        ),
        const SizedBox(height: 16.0),
        
        // Prompt answer
        if (_selectedPrompt != null) ...[
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPrompt!.replaceAll('___', '...'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _promptAnswerController,
                  decoration: const InputDecoration(
                    hintText: 'Your answer...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16.0),
                  ),
                  maxLength: 150,
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please complete the prompt'
                      : null,
                  onChanged: (_) => setState(() {}), // Update preview on change
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Preview:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    _promptAnswerController.text.isEmpty
                        ? 'Your answer will appear here...'
                        : _selectedPrompt!.replaceAll(
                            '___', 
                            _promptAnswerController.text
                          ),
                    style: TextStyle(
                      fontStyle: _promptAnswerController.text.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: _promptAnswerController.text.isEmpty
                          ? Colors.grey[500]
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Privacy & Policies',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Please review and agree to the following policies before creating your profile.',
          style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24.0),
        
        // Privacy Policy
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'VCU Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Please review how VCU handles your personal data',
                ),
                trailing: OutlinedButton(
                  onPressed: _openPrivacyPolicy,
                  child: const Text('Read Policy'),
                ),
              ),
              CheckboxListTile(
                value: _privacyPolicyChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _privacyPolicyChecked = value ?? false;
                  });
                },
                title: const Text(
                  'I have read and agree to the Privacy Policy'
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: constants.kPrimaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        
        // Contact Info
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'Student Contact Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Review the guidelines for student contact information',
                ),
                trailing: OutlinedButton(
                  onPressed: _openContactInfoPolicy,
                  child: const Text('Read Policy'),
                ),
              ),
              CheckboxListTile(
                value: _contactInfoPolicyChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _contactInfoPolicyChecked = value ?? false;
                  });
                },
                title: const Text(
                  'I agree to the Disclosure of Student Contact Information'
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: constants.kPrimaryColor,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24.0),
        
        Text(
          'By creating your profile, you agree to use this app responsibly and in accordance with VCU\'s policies and student code of conduct.',
          style: TextStyle(
            fontSize: 13.0,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildAcademicDetailsStep();
      case 2:
        return _buildInterestsStep();
      case 3:
        return _buildBioStep();
      case 4:
        return _buildPrivacyStep();
      default:
        return Container();
    }
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _goToPreviousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          else
            const SizedBox(width: 100), // Empty space to maintain alignment
          
          // Next/Submit button
          ElevatedButton.icon(
            onPressed: _goToNextStep,
            icon: Icon(
              _currentStep < _totalSteps - 1 ? Icons.arrow_forward : Icons.check,
            ),
            label: Text(
              _currentStep < _totalSteps - 1 ? 'Next' : 'Create Profile',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: constants.kVCUGold, // Updated to match VCU branding
              foregroundColor: constants.kPrimaryColor, // Updated for better contrast
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              _buildStepIndicator(),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCurrentStep(),
                ),
              ),
              
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildNavigationButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}