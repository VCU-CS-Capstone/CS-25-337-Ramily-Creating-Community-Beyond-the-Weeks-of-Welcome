import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart' as constants;

class ProfileEditorScreen extends StatefulWidget {
  final String email;

  const ProfileEditorScreen({super.key, required this.email});

  @override
  _ProfileEditorScreenState createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _userData = {};
  String? _userId;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customMajorController = TextEditingController();
  final TextEditingController _promptAnswerController = TextEditingController();
  final TextEditingController _customInterestController = TextEditingController();

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
  final int _requiredInterests = 5; // Changed variable name to indicate required interests

  // Bio prompts
  final List<String> _bioPrompts = [
    'What I\'m most excited for at VCU is ___',
    'I chose VCU because ___',
    'One thing I hope to accomplish during my time at VCU is ___',
    'My favorite spot on campus is ___ because ___',
    'Something most people don\'t know about me is ___',
    'When I\'m not studying, you can find me ___',
    'My favorite class so far has been ___ because ___',
    'I\'m passionate about ___',
    'My dream career is ___',
    'My favorite thing about Richmond is ___',
  ];
  String? _selectedPrompt;
  
  // Section expansion states
  bool _basicInfoExpanded = true;
  bool _majorExpanded = false;
  bool _pronounsExpanded = false;
  bool _interestsExpanded = false;
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current authenticated user
      final authUser = _auth.currentUser;
      if (authUser == null) {
        Navigator.pop(context);
        return;
      }
      
      _userId = authUser.uid;
      
      // Fetch user data from Firestore
      final docSnapshot = await _firestore.collection('users').doc(_userId).get();
      
      if (docSnapshot.exists) {
        _userData = docSnapshot.data() as Map<String, dynamic>;
        
        // Set controllers and selection values
        _nameController.text = _userData['name'] ?? '';
        
        // Set major
        _selectedMajor = _userData['major'];
        if (_selectedMajor == 'Major Not Listed') {
          _customMajorController.text = _userData['customMajor'] ?? '';
        }
        
        // Set pronouns
        _selectedPronoun = _userData['pronouns'];
        
        // Set interests
        _selectedInterests.clear();
        List<dynamic>? interests = _userData['interests'];
        if (interests != null) {
          for (var interest in interests) {
            _selectedInterests.add(interest.toString());
          }
          
          // Count custom interests
          _customInterestsCount = _selectedInterests.where((i) => !_availableInterests.contains(i)).length;
        }
        
        // Set bio prompt and answer
        _selectedPrompt = _userData['bioPrompt'];
        _promptAnswerController.text = _userData['bioAnswer'] ?? '';
        
        // Set profile picture
        if (_userData['profile_picture'] != null && _userData['profile_picture'].toString().isNotEmpty) {
          _profileImage = File(_userData['profile_picture']);
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    }
  }

  // Pick image with cropping
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

  Future<void> _saveProfile() async {
    // Check for exactly 5 interests before proceeding
    if (_selectedInterests.length != _requiredInterests) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select exactly $_requiredInterests interests')),
      );
      // Expand the interests section automatically to draw attention to it
      setState(() {
        _interestsExpanded = true;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form')),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Gather updated profile data
      Map<String, dynamic> updates = {};
      
      // Name
      if (_nameController.text.trim().isNotEmpty) {
        updates['name'] = _nameController.text.trim();
      }
      
      // Major
      if (_selectedMajor != null) {
        updates['major'] = _selectedMajor;
        if (_selectedMajor == 'Major Not Listed' && _customMajorController.text.trim().isNotEmpty) {
          updates['customMajor'] = _customMajorController.text.trim();
        }
      }
      
      // Pronouns
      if (_selectedPronoun != null) {
        updates['pronouns'] = _selectedPronoun;
      }
      
      // Interests
      if (_selectedInterests.isNotEmpty) {
        updates['interests'] = _selectedInterests.toList();
      }
      
      // Bio
      if (_selectedPrompt != null && _promptAnswerController.text.trim().isNotEmpty) {
        updates['bioPrompt'] = _selectedPrompt;
        updates['bioAnswer'] = _promptAnswerController.text.trim();
        updates['bio'] = _selectedPrompt!.replaceAll('___', _promptAnswerController.text.trim());
      }
      
      // Profile picture - only update if user has selected an image
      if (_profileImage != null) {
        updates['profile_picture'] = _profileImage!.path;
      } else if (_userData.containsKey('profile_picture') && _userData['profile_picture'] != null && _userData['profile_picture'] != '' && _profileImage == null) {
        // If user explicitly removed the profile picture but had one before
        updates['profile_picture'] = '';
      }
      
      // Only proceed if we have updates
      if (updates.isNotEmpty) {
        // Add timestamp
        updates['updated_at'] = FieldValue.serverTimestamp();
        
        // Save to Firestore
        await _firestore.collection('users').doc(_userId).update(updates);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Go back to previous screen
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes were made')),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      print('Error updating profile: $e');
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        actions: [
          _isSaving 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture (always visible at the top)
                    Center(
                      child: Stack(
                        children: [
                          // Profile image with grey background and person icon when no image
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300], // Slightly darker grey for better visibility
                            // Only use backgroundImage when a profile image exists
                            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                            // Only show person icon when no profile image exists
                            child: _profileImage == null 
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          // Camera button
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
                    
                    // Expandable sections
                    _buildExpandableSection(
                      title: 'Basic Information',
                      isExpanded: _basicInfoExpanded,
                      onToggle: () => setState(() => _basicInfoExpanded = !_basicInfoExpanded),
                      content: _buildBasicInfoSection(),
                    ),
                    
                    _buildExpandableSection(
                      title: 'Major',
                      isExpanded: _majorExpanded,
                      onToggle: () => setState(() => _majorExpanded = !_majorExpanded),
                      content: _buildMajorSection(),
                    ),
                    
                    _buildExpandableSection(
                      title: 'Pronouns',
                      isExpanded: _pronounsExpanded,
                      onToggle: () => setState(() => _pronounsExpanded = !_pronounsExpanded),
                      content: _buildPronounsSection(),
                    ),
                    
                    _buildExpandableSection(
                      title: 'Interests',
                      isExpanded: _interestsExpanded,
                      onToggle: () => setState(() => _interestsExpanded = !_interestsExpanded),
                      content: _buildInterestsSection(),
                    ),
                    
                    _buildExpandableSection(
                      title: 'Bio',
                      isExpanded: _bioExpanded,
                      onToggle: () => setState(() => _bioExpanded = !_bioExpanded),
                      content: _buildBioSection(),
                    ),
                    
                    const SizedBox(height: 24.0),
                    
                    // Save button at bottom too for easier access
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: constants.kVCUGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Column(
        children: [
          // Expandable header
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: constants.kPrimaryColor,
            ),
            onTap: onToggle,
          ),
          
          // Expandable content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }
  
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full name field
        TextFormField(
          controller: _nameController,
          enabled: false, // This makes it uneditable
          decoration: const InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(color: constants.kDarkText), // Light grey text to indicate it's disabled
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
            fillColor: Color(0xFFEEEEEE), // Light grey background to indicate it's disabled
            filled: true,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Email field (disabled, just for display)
        TextFormField(
          initialValue: widget.email,
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color:constants.kPrimaryColor),
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
            fillColor: Color(0xFFEEEEEE),
            filled: true,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMajorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Major dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Major',
            labelStyle: TextStyle(color: constants.kDarkText),
            prefixIcon: Icon(Icons.school),
            border: OutlineInputBorder(),
          ),
          value: _selectedMajor,
          isExpanded: true,
          hint: const Text('Select your major'),
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
        ),
        
        // Custom major field if "Major Not Listed" is selected
        if (_selectedMajor == 'Major Not Listed') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customMajorController,
            decoration: const InputDecoration(
              labelText: 'Enter Your Major',
              prefixIcon: Icon(Icons.edit),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_selectedMajor == 'Major Not Listed' && (value == null || value.isEmpty)) {
                return 'Please enter your major';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildPronounsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pronouns dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Pronouns',
            labelStyle: TextStyle(color: constants.kDarkText),
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
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedPronoun = value;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Interests header with counter - updated to show required count
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
  
  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show current bio if it exists
        if (_userData.containsKey('bio') && _userData['bio'] != null && _userData['bio'].toString().isNotEmpty) ...[
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
                const Text(
                  'Current Bio:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: constants.kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  _userData['bio'],
                  style: const TextStyle(
                    fontSize: 15.0,
                    color: constants.kDarkText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          const Divider(),
          const SizedBox(height: 16.0),
        ],
        
        // Prompt selection
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Select a Prompt',
            prefixIcon: Icon(Icons.format_quote),
            border: OutlineInputBorder(),
          ),
          value: _selectedPrompt,
          isExpanded: true,
          hint: const Text('Choose a prompt to answer'),
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
                  validator: (value) {
                    if (_selectedPrompt != null && (value == null || value.isEmpty)) {
                      return 'Please complete the prompt';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
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
  
  @override
  void dispose() {
    _nameController.dispose();
    _customMajorController.dispose();
    _promptAnswerController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }
}