import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'matching_onboarding_screen.dart';
import 'chat_detail_screen.dart';
import 'constants.dart' as constants;
import 'package:firebase_auth/firebase_auth.dart' as auth;

// Use the color constants for consistency
const Color kPrimaryColor = constants.kPrimaryColor;
const Color kVCUBlack = constants.kVCUBlack;
const Color kVCUGold = constants.kVCUGold;
const Color kVCUWhite = constants.kVCUWhite;
const Color kVCUPurple = constants.kVCUPurple;
const Color kVCUBlue = constants.kVCUBlue;
const Color kVCUGreen = constants.kVCUGreen;
const Color kVCURed = constants.kVCURed;
const Color kDarkText = constants.kDarkText;
const Color kBackgroundColor = constants.kBackgroundColor;

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

// User class with improved avatar handling
class User {
  final String id;
  final String name;
  final String major;
  final String pronouns;
  final List<String> interests;
  final String bio;
  final String profilePicture;
  final Color avatarColor;
  final String gender;  // Added gender field

  User({
    required this.id, 
    required this.major, 
    required this.pronouns, 
    required this.interests, 
    required this.bio,
    String? name,
    this.profilePicture = '',
    this.gender = '',  // Default value for gender
  }) : 
    name = (name != null && name.isNotEmpty) ? name : id,
    avatarColor = _generateAvatarColor((name != null && name.isNotEmpty) ? name : id);
  
  // Generate consistent color based on user name or ID
  static Color _generateAvatarColor(String seed) {
    // Use consistent hash code to ensure same color for same user
    final random = Random(seed.hashCode);
    
    // VCU brand color palette
    final List<Color> vcuColorPalette = [
      kVCUPurple,
      kVCUBlue,
      Color(0xFF8D5E8B), // Lavender from matching colors
      kVCUBlue.withOpacity(0.85),
      kVCUPurple.withOpacity(0.85),
      Color(0xFF614A76), // Deep purple (VCU adjacent)
      Color(0xFF007DB5), // Medium blue
    ];
    
    return vcuColorPalette[random.nextInt(vcuColorPalette.length)];
  }
  
  // First letter getter for avatar display
  String get firstLetter => name.isNotEmpty ? name[0].toUpperCase() : '';
}

// Global major weight variable (slider value)
double majorMultiplier = 0.5;

// Define the categories and sub-categories for major matching
final Map<String, Map<String, List<String>>> categories = {
  'Arts and Humanities': {
    'A&H Majors': [
      'Arts',
      'Art History',
      'Cinema',
      'Communication Arts',
      'Craft and Material Studies',
      'Dance and Choreography',
      'English',
      'Foreign Language',
      'Graphic Design',
      'Interior Design',
      'Kinetic Imaging',
      'Music',
      'Painting and Printmaking',
      'Philosophy',
      'Photography and Film',
      'Theatre',
      'Fashion'
    ]
  },

  'STEM': {
    'Social Sciences': [
      'African American Studies',
      'Anthropology',
      'Criminal Justice',
      'Gender, Sexuality and Womens Studies',
      'History',
      'Human and Organizational Development',
      'International Studies',
      'Political Science',
      'Psychology',
      'Sociology',
      'Social Work',
      'Urban and Regional Studies'
    ],

    'Natural Sciences': [
      'Bioinformatics',
      'Biology',
      'Chemistry',
      'Environmental Studies',
      'Physics',
      'Science'
    ],

    'Engineering and Technology': [
      'Biomedical Engineering',
      'Chemical and Life Science Engineering',
      'Computer Engineering',
      'Computer Science',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Information Systems'
    ],
  },

  'Business and Economics': {
    'B&E Majors':[
      'Accounting',
      'Business',
      'Economics',
      'Finance',
      'Financial Technology',
      'Marketing',
      'Real Estate',
      'Supply Chain Management'
    ]
  },

  'Health and Medicine': {
    'H&M Majors': [
      'Clinical Radiation Sciences',
      'Dental Hygiene',
      'Health Services',
      'Health, Physical Education and Exercise Science',
      'Medical Laboratory Sciences',
      'Nursing',
      'Pharmaceutical Sciences'
    ]
  },

  'Other': {
    'O Majors': [
      'Interdisciplinary Studies',
      'Major Not Listed/Undecided'
    ]
  }
};

class _MatchingScreenState extends State<MatchingScreen> with SingleTickerProviderStateMixin {
  List<User> matchedUsers = [];
  bool isLoading = true;
  
  // Controllers
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // Current user info for matching
  late String referenceMajor = 'Computer Science'; // Default
  late List<String> referenceInterests = ['Technology', 'Gaming', 'Sports', 'Music']; // Default
  
  // Pagination variables
  List<User> _displayedUsers = [];
  int _currentIndex = 0;
  final int _batchSize = 5;
  
  // Cache for match scores
  final Map<String, double> _scoreCache = {};
  
  // Filter value
  double _filterValue = 0.5;
  
  // Filter state variables
  bool _showFilterModal = false;
  String? _selectedGenderFilter;
  String? _selectedMajorFilter;
  List<String> _allMajors = []; // Will be populated from categories
  
  // Gender options
 final List<String> _genderOptions = [
  'All',
  'He/Him',
  'She/Her',
  'They/Them',
  'He/They',
  'She/They',
  'All Pronouns'
];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scrollController.addListener(_scrollListener);
    _initializeFilterOptions();
    _loadCurrentUserInfo();
  }
  
  void _initializeFilterOptions() {
    // Extract all majors from categories
    Set<String> majors = {};
    for (var categoryEntry in categories.entries) {
      for (var subcategoryEntry in categoryEntry.value.entries) {
        majors.addAll(subcategoryEntry.value);
      }
    }
    
    _allMajors = ['All Majors', ...majors.toList()..sort()];
  }

  // Load current user data 
  Future<void> _loadCurrentUserInfo() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Get major with fallback
          String userMajor = 'Computer Science';
          if (data.containsKey('major') && data['major'] != null && data['major'].toString().isNotEmpty) {
            userMajor = data['major'].toString();
          }
          
          // Get interests with fallback
          List<String> userInterests = ['Technology', 'Gaming', 'Sports', 'Music'];
          if (data.containsKey('interests') && data['interests'] != null && data['interests'] is List) {
            userInterests = List<String>.from(
                data['interests'].map((i) => i.toString())
            );
          }
          
          setState(() {
            referenceMajor = userMajor;
            referenceInterests = userInterests;
          });
        }
      }
    } catch (e) {
      print('Error loading current user data: $e');
      // Continue with defaults
    } finally {
      _initializeUserList();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Uniform avatar builder 
  Widget buildUserAvatar(User user, {double size = 50, bool showBorder = true}) {
    // Try to use actual profile picture if available
    if (user.profilePicture.isNotEmpty) {
      try {
        final File profileFile = File(user.profilePicture);
        if (profileFile.existsSync()) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: FileImage(profileFile),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error loading profile image: $e');
        // Fall through to default avatar
      }
    }
    
    // Fallback to letter-based avatar
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user.avatarColor,
        border: showBorder ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          user.firstLetter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4, // Scale font with avatar size
          ),
        ),
      ),
    );
  }

  // Show the onboarding screen when info button is tapped
  void _showOnboardingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchingOnboardingScreen(fromInfoButton: true)),
    );
  }

  // Load more users when scrolling to bottom
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreUsers();
    }
  }

  // Helper function to find major categories
  List<String>? getMajorCategoryAndSubcategory(String major) {
    for (var categoryEntry in categories.entries) {
      for (var subcategoryEntry in categoryEntry.value.entries) {
        if (subcategoryEntry.value.contains(major)) {
          return [categoryEntry.key, subcategoryEntry.key];
        }
      }
    }
    return null;
  }

  // Calculate major proximity score (0 to 1)
  double calculateProximityPoints(String major1, String major2) {
    // Same major = perfect match
    if (major1 == major2) {
      return 1.0;
    }

    // Get categories for both majors
    List<String>? major1Details = getMajorCategoryAndSubcategory(major1);
    List<String>? major2Details = getMajorCategoryAndSubcategory(major2);

    if (major1Details == null || major2Details == null) {
      return 0.0;
    }

    String category1 = major1Details[0];
    String subcategory1 = major1Details[1];
    String category2 = major2Details[0];
    String subcategory2 = major2Details[1];

    // Same subcategory = high match
    if (category1 == category2 && subcategory1 == subcategory2) {
      return 0.67; // 2/3
    }

    // Same category = medium match
    if (category1 == category2) {
      return 0.33; // 1/3
    }

    // Different categories = no match
    return 0.0;
  }

  // Calculate match score between two users
  double calculateMatchScore(User user1, User user2) {
    // Major proximity (academic match)
    double majorProximity = calculateProximityPoints(user1.major, user2.major);
    
    // Interest overlap (social match)
    double interestOverlap = 0.0;
    if (user1.interests.isNotEmpty && user2.interests.isNotEmpty) {
      int matchCount = 0;
      for (String interest in user1.interests) {
        if (user2.interests.contains(interest)) {
          matchCount++;
        }
      }
      
      int smallerSize = min(user1.interests.length, user2.interests.length);
      if (smallerSize > 0) {
        interestOverlap = matchCount / smallerSize;
        
        // Bonus for multiple shared interests
        if (matchCount > 1) {
          interestOverlap = interestOverlap * (1.0 + (0.1 * (matchCount - 1)));
        }
        
        interestOverlap = min(interestOverlap, 1.0);
      }
    }
    
    // Bio keyword compatibility
    double bioCompatibility = 0.0;
    if (user1.bio.isNotEmpty && user2.bio.isNotEmpty) {
      List<String> keywords = [
        'study', 'learning', 'friends', 'social', 'activities', 
        'sports', 'music', 'art', 'science', 'engineering', 
        'business', 'research', 'volunteer', 'clubs', 
        'freshman', 'transfer', 'new', 'roommate'
      ];
      
      Set<String> user1Keywords = {};
      Set<String> user2Keywords = {};
      
      for (String keyword in keywords) {
        if (user1.bio.toLowerCase().contains(keyword)) {
          user1Keywords.add(keyword);
        }
        if (user2.bio.toLowerCase().contains(keyword)) {
          user2Keywords.add(keyword);
        }
      }
      
      if (user1Keywords.isNotEmpty && user2Keywords.isNotEmpty) {
        Set<String> commonKeywords = user1Keywords.intersection(user2Keywords);
        int minSize = min(user1Keywords.length, user2Keywords.length);
        if (minSize > 0) {
          bioCompatibility = commonKeywords.length / minSize.toDouble();
          bioCompatibility = min(bioCompatibility, 0.5);
        }
      }
    }
    
    // Small bonus for compatible pronouns
    double pronounsCompat = 0.0;
    if (user1.pronouns.isNotEmpty && user2.pronouns.isNotEmpty) {
      if (user1.pronouns == user2.pronouns || 
          user1.pronouns == 'All Pronouns' || 
          user2.pronouns == 'All Pronouns') {
        pronounsCompat = 0.1;
      }
    }
    
    // Apply user's prioritization preferences
    double majorWeight = majorMultiplier;
    double interestWeight = 1.0 - majorMultiplier;
    double bioWeight = 0.15;
    double pronounsWeight = 0.05;
    
    // Normalize weights to sum to 1.0
    double totalWeight = majorWeight + interestWeight + bioWeight + pronounsWeight;
    majorWeight /= totalWeight;
    interestWeight /= totalWeight;
    bioWeight /= totalWeight;
    pronounsWeight /= totalWeight;
    
    // Calculate final weighted score
    double finalScore = (majorProximity * majorWeight) +
                       (interestOverlap * interestWeight) +
                       (bioCompatibility * bioWeight) +
                       (pronounsCompat * pronounsWeight);
    
    // Apply curve for better distribution
    double curvedScore = pow(finalScore, 1.2).toDouble();
    
    return curvedScore;
  }

  // Calculate percentage of matching interests
  double countMatchingInterests(List<String> interests1, List<String> interests2) {
    if (interests1.isEmpty) return 0;
    
    int commonCount = 0;
    for (String interest in interests1) {
      if (interests2.contains(interest)) {
        commonCount++;
      }
    }
    return interests1.isNotEmpty ? commonCount / interests1.length : 0;
  }

  // Get color for match percentage display
  Color getMatchColor(int percentage) {
    if (percentage > 90) return kVCURed;
    if (percentage > 80) return kVCUGold;
    if (percentage > 70) return kVCUGreen;
    return Colors.grey[600]!;
  }

  // Fetch users from Firestore
  Future<List<User>> fetchUsersFromFirestore() async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('users');
Query query = userCollection;  // Define as Query type

if (_selectedGenderFilter != null) {
  query = query.where('pronouns', isEqualTo: _selectedGenderFilter);
}

// Execute the query
final snapshot = await query.get();

      List<User> users = [];
      for (var doc in snapshot.docs) {
        String id = doc.id;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Skip current user
        auth.User? currentAuthUser = auth.FirebaseAuth.instance.currentUser;
        if (currentAuthUser != null && id == currentAuthUser.uid) {
          continue;
        }
        
        // Apply major filter if selected
        if (_selectedMajorFilter != null) {
          String userMajor = data['major'] ?? '';
          if (_selectedMajorFilter != userMajor) {
            continue; // Skip this user if major doesn't match
          }
        }
        
        // Handle name data safely
        String? userName;
        if (data.containsKey('name') && data['name'] != null) {
          userName = data['name'];
        } else if (data.containsKey('firstName') && data['firstName'] != null) {
          userName = data['firstName'];
          if (data.containsKey('lastName') && data['lastName'] != null) {
            userName = "$userName ${data['lastName']}";
          }
        }
        
        // Handle other fields with fallbacks
        String major = data['major'] ?? '';
        String pronouns = data['pronouns'] ?? '';
        String gender = data['gender'] ?? '';
        
        // Safely handle interests list
        List<String> interests = [];
        if (data.containsKey('interests') && data['interests'] != null) {
          if (data['interests'] is List) {
            interests = List<String>.from(data['interests'].map((i) => i.toString()));
          }
        }
        
        String bio = data['bio'] ?? '';
        String profilePicture = data['profile_picture'] ?? '';
        
        users.add(User(
          id: id, 
          name: userName, 
          major: major, 
          pronouns: pronouns, 
          interests: interests, 
          bio: bio,
          profilePicture: profilePicture,
          gender: gender,
        ));
      }
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      // Return sample data if Firestore fails
      return [
        User(
          id: 'johnsmith',
          name: 'John Smith',
          major: 'Computer Science',
          pronouns: 'He/Him',
          interests: ['Technology', 'Gaming', 'Music'],
          bio: 'A passionate computer science student who loves coding and gaming.',
          gender: 'Male',
        ),
        User(
          id: 'emilywilson',
          name: 'Emily Wilson',
          major: 'Psychology',
          pronouns: 'She/Her',
          interests: ['Reading', 'Music', 'Photography', 'Psychology'],
          bio: 'Psychology student interested in cognitive science and music therapy.',
          gender: 'Female',
        ),
        User(
          id: 'michaeljones',
          name: 'Michael Jones',
          major: 'Business',
          pronouns: 'He/Him',
          interests: ['Finance', 'Sports', 'Travel'],
          bio: 'Business student with a passion for finance and investments.',
          gender: 'Male',
        ),
        User(
          id: 'sophiadavis',
          name: 'Sophia Davis',
          major: 'Biology',
          pronouns: 'She/Her',
          interests: ['Science', 'Reading', 'Hiking', 'Technology'],
          bio: 'Future doctor studying Biology with a focus on genetics research.',
          gender: 'Female',
        ),
        User(
          id: 'jameswilliams',
          name: 'James Williams',
          major: 'Art History',
          pronouns: 'They/Them',
          interests: ['Art', 'Museums', 'Photography', 'Travel'],
          bio: 'Art history enthusiast exploring the intersections of modern and classical art.',
          gender: 'Non-binary',
        ),
      ];
    }
  }

  // Calculate scores for all users and sort by match quality
  Future<List<User>> calculateAndSortUsers() async {
    List<User> users = await fetchUsersFromFirestore();
    List<Map<String, dynamic>> userScores = [];

    // Reference user for comparison
    User referenceUser = User(
      id: 'reference',
      name: 'You',
      major: referenceMajor,
      pronouns: '',
      interests: referenceInterests,
      bio: '',
    );

    // Calculate scores for each user
    for (var user in users) {
      String cacheKey = '${user.id}_${referenceMajor}_${referenceInterests.join('_')}_$majorMultiplier';
      
      // Use cached score if available
      if (_scoreCache.containsKey(cacheKey)) {
        userScores.add({
          'user': user,
          'score': _scoreCache[cacheKey]!,
        });
        continue;
      }
      
      // Calculate new score
      double score = calculateMatchScore(referenceUser, user);
      _scoreCache[cacheKey] = score;
      
      userScores.add({
        'user': user,
        'score': score,
      });
    }

    // Sort by score (highest first)
    userScores.sort((a, b) => b['score'].compareTo(a['score']));
    
    // Extract sorted users
    return userScores.map((entry) => entry['user'] as User).toList();
  }

  // Clear cache (when filter changes)
  void _clearScoreCache() {
    _scoreCache.clear();
  }

  // Initialize user list with sorted matches
  Future<void> _initializeUserList() async {
    try {
      List<User> sortedUsers = await calculateAndSortUsers();

      if (mounted) {
        setState(() {
          matchedUsers = sortedUsers;
          isLoading = false;
          _displayedUsers = [];
          _currentIndex = 0;
          _loadMoreUsers();
        });
      }
    } catch (e) {
      print('Error initializing user list: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          matchedUsers = [];
        });
      }
    }
  }

  // Load next batch of users
  void _loadMoreUsers() {
    if (_currentIndex >= matchedUsers.length) return;
    
    final int endIndex = min(_currentIndex + _batchSize, matchedUsers.length);

    if (mounted) {
      setState(() {
        _displayedUsers.addAll(matchedUsers.sublist(_currentIndex, endIndex));
        _currentIndex = endIndex;
      });
    }
  }

  // Apply filters and refresh user list
  void _applyFilters() {
    // Clear cached results to force recalculation with filters
    _clearScoreCache();
    
    // Reset the displayed users
    setState(() {
      _displayedUsers = [];
      _currentIndex = 0;
      isLoading = true;
    });
    
    // Re-initialize user list with filters
    _initializeUserList();
  }
  
  // Show filter dialog
  void _showFilterDialog() {
  setState(() {
    _showFilterModal = false; // Reset the flag
  });
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Filter Matches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kVCUBlack,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Gender filter section
                  const Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kDarkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _genderOptions.map((gender) {
                      final isSelected = _selectedGenderFilter == gender || 
                                        (gender == 'All' && _selectedGenderFilter == null);
                      return ChoiceChip(
                        label: Text(gender),
                        selected: isSelected,
                        selectedColor: kVCUGold,
                        labelStyle: TextStyle(
                          color: isSelected ? kVCUBlack : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedGenderFilter = selected ? 
                                                (gender == 'All' ? null : gender) : 
                                                null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Major filter section
                  const Text(
                    'Major',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kDarkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMajorFilter ?? 'All Majors',
                        isExpanded: true,
                        hint: const Text('Select a major'),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: _allMajors.map((major) {
                          return DropdownMenuItem(
                            value: major,
                            child: Text(
                              major,
                              style: TextStyle(
                                color: major == _selectedMajorFilter ? kVCUGold : kDarkText,
                                fontWeight: major == _selectedMajorFilter ? 
                                          FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            if (value == 'All Majors') {
                              _selectedMajorFilter = null;
                            } else {
                              _selectedMajorFilter = value;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Apply and Reset buttons
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedGenderFilter = null;
                            _selectedMajorFilter = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Reset Filters'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kVCUGold,
                            foregroundColor: kVCUBlack,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Add some padding for bottom safe area
                  // Add some padding for bottom safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Match explanation modal
  void _showMatchExplanation(BuildContext context, User user, int matchPercentage) {
    // Calculate individual scores for explanation
    double majorScore = calculateProximityPoints(referenceMajor, user.major);
    double interestScore = countMatchingInterests(referenceInterests, user.interests);
    
    int majorPercentage = (majorScore * 100).round();
    int interestsPercentage = (interestScore * 100).round();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How We Matched You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kVCUBlack,
                ),
              ),
              const SizedBox(height: 16),
              
              // Major match
              Row(
                children: [
                  Icon(Icons.school, color: kVCUGold, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Academic Match:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$majorPercentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kVCUGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your major: $referenceMajor\nTheir major: ${user.major}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              
              // Interest match
              Row(
                children: [
                  Icon(Icons.favorite, color: kVCURed, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Interest Match:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$interestsPercentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kVCURed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Common interests
              Wrap(
                spacing: 8,
                children: user.interests.map((interest) {
                  bool isCommon = referenceInterests.contains(interest);
                  return Chip(
                    label: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCommon ? kVCUBlack : Colors.grey[700],
                      ),
                    ),
                    backgroundColor: isCommon  
                        ? kVCUGold.withOpacity(0.15)
                        : Colors.grey[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              const Divider(),
              const SizedBox(height: 16),
              
              // Overall match
              Row(
                children: [
                  const Text(
                    'Overall Match:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: getMatchColor(matchPercentage),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$matchPercentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Close button
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVCUGold,
                    foregroundColor: kVCUBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to establish a connection and send a message
  Future<void> _connectWithUser(User matchedUser) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecting with ${matchedUser.name}...')),
      );

      // Get current user from Firebase
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to connect')),
        );
        return;
      }

      // Get current user data from Firestore
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your profile data is not available')),
        );
        return;
      }

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentUserName = currentUserData['name'] ?? 'VCU Student';

      // Check if there's an existing chat between these users
      // We'll create a unique chat ID by combining both user IDs alphabetically
      final List<String> userIds = [currentUser.uid, matchedUser.id];
      userIds.sort(); // Sort to ensure same ID regardless of who initiates
      final String chatId = userIds.join('_');

      // Check if a chat document already exists
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      final timestamp = FieldValue.serverTimestamp();
      
      if (!chatDoc.exists) {
        // Create a new chat document with pending request status
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'participants': userIds,
          'participantNames': {
            currentUser.uid: currentUserName,
            matchedUser.id: matchedUser.name,
          },
          'createdAt': timestamp,
          'lastMessage': 'Hi, I found you through VCU Connect!',
          'lastMessageTime': timestamp,
          'lastMessageSender': currentUser.uid,
          'unreadCount': {
            currentUser.uid: 0,
            matchedUser.id: 1, // One unread message for the recipient
          },
          'status': {
            currentUser.uid: 'accepted', // Sender automatically accepts
            matchedUser.id: 'pending', // Recipient needs to accept
          },
        });
      }

      // Add the initial message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': currentUserName,
        'text': 'Hi, I found you through VCU Connect!',
        'timestamp': timestamp,
        'isRead': false,
      });
      
      // For current user - add to active chats
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_chats')
          .doc(chatId)
          .set({
        'chatId': chatId,
        'otherUserId': matchedUser.id,
        'otherUserName': matchedUser.name,
        'lastMessage': 'Hi, I found you through VCU Connect!',
        'lastMessageTime': timestamp,
        'unreadCount': 0, // Current user has read all messages
        'updatedAt': timestamp,
        'status': 'accepted', // Sender automatically accepts
      });

      // For matched user - add to message requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(matchedUser.id)
          .collection('message_requests')
          .doc(chatId)
          .set({
        'chatId': chatId,
        'otherUserId': currentUser.uid,
        'otherUserName': currentUserName,
        'lastMessage': 'Hi, I found you through VCU Connect!',
        'lastMessageTime': timestamp,
        'unreadCount': 1, // Matched user has one unread message
        'updatedAt': timestamp,
        'status': 'pending', // Recipient needs to accept
      });

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection request sent to ${matchedUser.name}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to chat detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            name: matchedUser.name,
            message: 'Hi, I found you through VCU Connect!',
            chatId: chatId,
            otherUserId: matchedUser.id,
            status: 'accepted', // For sender, status is accepted
          ),
        ),
      );
    } catch (e) {
      // Error handling
      print('Error connecting with user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetailedProfile(BuildContext context, User user, int matchPercentage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with match percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kVCUBlack,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getMatchColor(matchPercentage),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$matchPercentage% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Profile picture
                Center(
                  child: buildUserAvatar(user, size: 120, showBorder: true),
                ),
                
                const SizedBox(height: 24),
                
                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Profile info card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Major
                              _buildProfileField(
                                icon: Icons.school,
                                title: 'Major',
                                value: user.major,
                                iconColor: kVCUGold,
                              ),
                              const SizedBox(height: 16),
                              
                              // Pronouns
                              _buildProfileField(
                                icon: Icons.person,
                                title: 'Pronouns',
                                value: user.pronouns,
                                iconColor: kVCUPurple,
                              ),
                              
                              // Show gender if available
                              if (user.gender.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildProfileField(
                                  icon: Icons.people,
                                  title: 'Gender',
                                  value: user.gender,
                                  iconColor: kVCUBlue,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Bio section
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kVCUBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          user.bio,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Interests section
                      const Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kVCUBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.interests.map((interest) {
                          final bool isCommon = referenceInterests.contains(interest);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCommon 
                                  ? kVCUGold.withOpacity(0.15) 
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: isCommon 
                                  ? Border.all(color: kVCUGold) 
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCommon) ...[
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: kVCUGold,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  interest,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isCommon ? kVCUGold : Colors.grey[700],
                                    fontWeight: isCommon ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      
                      // Connect button with updated request message
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the profile modal
                          _connectWithUser(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kVCUGold,
                          foregroundColor: kVCUBlack,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Send Connection Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper for profile field display
  Widget _buildProfileField({
    required IconData icon, 
    required String title, 
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'Not specified',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kVCUBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Find Your Match',
          style: TextStyle(
            color: kVCUBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kVCUBlack),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add filter button
          IconButton(
  icon: const Icon(Icons.filter_list, color: kVCUBlack),
  onPressed: () {
    setState(() {
      _showFilterModal = true;
    });
    // Add this line to immediately show the dialog rather than waiting for rebuild
    _showFilterDialog();
  },
  tooltip: 'Filter matches',
),
          IconButton(
            icon: const Icon(Icons.info_outline, color: kVCUBlack),
            onPressed: _showOnboardingScreen,
            tooltip: 'Learn about matching',
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              color: kVCUGold,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Finding your matches...',
            style: TextStyle(
              fontSize: 18,
              color: kVCUBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You\'ve Matched!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kVCUBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ve found ${matchedUsers.length} RAMs that match your interests and academic focus.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Filter widget
        SliverToBoxAdapter(
          child: _buildFilterWidget(),
        ),
        
        // User list
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = _displayedUsers[index];
                
                // Get match score for this user
                double score = calculateMatchScore(
                  User(
                    id: 'reference',
                    name: 'You',
                    major: referenceMajor,
                    pronouns: '',
                    interests: referenceInterests,
                    bio: '',
                  ),
                  user
                );
                int matchPercentage = (score * 100).round();
                
                return _buildUserCard(
                  context,
                  user: user,
                  matchPercentage: matchPercentage,
                  index: index,
                );
              },
              childCount: _displayedUsers.length,
            ),
          ),
        ),
        
        // Loading or end indicator
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _currentIndex < matchedUsers.length
                ? Center(
                    child: CircularProgressIndicator(
                      color: kVCUGold,
                      strokeWidth: 2,
                    ),
                  )
                : Center(
                    child: Text(
                      'That\'s all for now!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Updated filter widget
  Widget _buildFilterWidget() {
    // Add filter status indicators
    final bool hasActiveFilters = _selectedGenderFilter != null || _selectedMajorFilter != null;
    
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Matching Priority',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kVCUBlack,
                  ),
                ),
                const Spacer(),
                // Show active filter indicators if any
                if (hasActiveFilters) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kVCUPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 14,
                          color: kVCUPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filters active',
                          style: TextStyle(
                            fontSize: 12,
                            color: kVCUPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Text(
                  'Interests',
                  style: TextStyle(
                    fontSize: 12,
                    color: _filterValue < 0.5 ? kVCUGold : Colors.grey[600],
                    fontWeight: _filterValue < 0.5 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: kVCUGold,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: kVCUGold,
                      overlayColor: kVCUGold.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _filterValue,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          _filterValue = value;
                          majorMultiplier = value;
                          _clearScoreCache();
                          _displayedUsers = [];
                          _currentIndex = 0;
                          _initializeUserList();
                        });
                      },
                    ),
                  ),
                ),
                
                Text(
                  'Major',
                  style: TextStyle(
                    fontSize: 12,
                    color: _filterValue > 0.5 ? kVCUGold : Colors.grey[600],
                    fontWeight: _filterValue > 0.5 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            
            // Active filter chips
            if (hasActiveFilters) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (_selectedGenderFilter != null)
                    Chip(
                      label: Text(_selectedGenderFilter!),
                      backgroundColor: kVCUGold.withOpacity(0.1),
                      deleteIconColor: kVCUGold,
                      labelStyle: const TextStyle(color: kVCUGold, fontSize: 12),
                      onDeleted: () {
                        setState(() {
                          _selectedGenderFilter = null;
                          _applyFilters();
                        });
                      },
                    ),
                  if (_selectedMajorFilter != null)
                    Chip(
                      label: Text(
                        _selectedMajorFilter!.length > 20 
                            ? '${_selectedMajorFilter!.substring(0, 18)}...' 
                            : _selectedMajorFilter!,
                      ),
                      backgroundColor: kVCUGold.withOpacity(0.1),
                      deleteIconColor: kVCUGold,
                      labelStyle: const TextStyle(color: kVCUGold, fontSize: 12),
                      onDeleted: () {
                        setState(() {
                          _selectedMajorFilter = null;
                          _applyFilters();
                        });
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // User card with clean profile picture handling
  Widget _buildUserCard(
    BuildContext context, {
    required User user,
    required int matchPercentage,
    required int index,
  }) {
    // Find common interests
    List<String> commonInterests = [];
    for (String interest in user.interests) {
      if (referenceInterests.contains(interest)) {
        commonInterests.add(interest);
      }
    }

    // Get color based on match percentage
    Color matchColor = getMatchColor(matchPercentage);
    
    // Truncate name if too long
    final String displayName = user.name.length > 20 
        ? '${user.name.substring(0, 18)}...' 
        : user.name;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: matchPercentage > 80 ? matchColor.withOpacity(0.3) : Colors.transparent, 
          width: 1.0
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with avatar, name, and match percentage
            Row(
              children: [
                // Unified avatar display
                buildUserAvatar(user, size: 50),
                const SizedBox(width: 12),
                
                // Name, major and pronouns
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kVCUBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.school, size: 12, color: kVCUGold),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.major,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: kVCUBlack.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (user.pronouns.isNotEmpty || user.gender.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.pronouns.isNotEmpty ? user.pronouns : user.gender,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Match percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: matchColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$matchPercentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Bio preview if available
            if (user.bio.isNotEmpty) ...[
              Text(
                user.bio.length > 80 ? '${user.bio.substring(0, 77)}...' : user.bio,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
            
            // Interests section
            if (user.interests.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'Interests: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kVCUBlack,
                    ),
                  ),
                  // Common interests badge
                  if (commonInterests.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: kVCUGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${commonInterests.length} in common',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kVCUGold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              
              // Scrollable interest tags
              SizedBox(
                height: 26,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: user.interests.length,
                  itemBuilder: (context, index) {
                    final interest = user.interests[index];
                    final bool isCommon = commonInterests.contains(interest);
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCommon 
                            ? kVCUGold.withOpacity(0.15)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: isCommon 
                            ? Border.all(color: kVCUGold.withOpacity(0.5))
                            : null,
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 10,
                          color: isCommon ? kVCUGold : Colors.grey[700],
                          fontWeight: isCommon ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 10),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Match Details button
                TextButton(
                  onPressed: () => _showMatchExplanation(context, user, matchPercentage),
                  style: TextButton.styleFrom(
                    foregroundColor: kVCUBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Match Details',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 4),
                // View Profile button
                OutlinedButton(
                  onPressed: () => _showDetailedProfile(context, user, matchPercentage),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kVCUPurple,
                    side: BorderSide(color: kVCUPurple.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Profile', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 4),
                // Connect button - updated to show it sends a request
                ElevatedButton(
                  onPressed: () => _connectWithUser(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVCUGold,
                    foregroundColor: kVCUBlack,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Show filter modal if needed
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showFilterModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFilterDialog();
      });
    }
  }
}