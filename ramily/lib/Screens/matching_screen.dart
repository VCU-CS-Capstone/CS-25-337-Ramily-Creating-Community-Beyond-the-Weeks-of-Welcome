import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'matching_onboarding_screen.dart';

// Color constants defined locally to avoid import conflicts
const Color _kPrimaryColor = Color(0xFF8D5E8B);    // Lighter Purple
const Color _kAccentColor = Color(0xFFF37D7F);     // Softer Red
const Color _kSecondaryColor = Color(0xFFFCD16F);  // Lighter Gold
const Color _kTraditionsColor = Color.fromARGB(255, 137, 200, 192); // Turquoise
const Color _kBackgroundColor = Color(0xFFF8F8F8); // Almost White
const Color _kDarkText = Color(0xFF333333);        // Softer Black

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class User {
  final String id;
  final String name; // Non-nullable but will use id as fallback
  final String major;
  final String pronouns;
  final List<String> interests;
  final String bio;
  final String profilePicture;

  User({
    required this.id, 
    required this.major, 
    required this.pronouns, 
    required this.interests, 
    required this.bio,
    String? name, // Accept nullable name
    this.profilePicture = '',
  }) : name = name ?? id; // Use id as fallback if name is null
}

// Global variable for major multiplier
double majorMultiplier = 0.5;

// Fetch users from Firestore
Future<List<User>> fetchUsersFromFirestore() async {
  try {
    final userCollection = FirebaseFirestore.instance.collection('users');
    final snapshot = await userCollection.get();

    List<User> users = [];
    for (var doc in snapshot.docs) {
      String id = doc.id;
      
      // Get user data with proper fallbacks for null values
      Map<String, dynamic> data = doc.data();
      
      // Handle name fields carefully with null checks
      String? userName;
      if (data.containsKey('name') && data['name'] != null) {
        userName = data['name'];
      } else if (data.containsKey('firstName') && data['firstName'] != null) {
        userName = data['firstName'];
        // Add last name if available
        if (data.containsKey('lastName') && data['lastName'] != null) {
userName = "$userName ${data['lastName']}";        }
      }
      // No need to set a fallback here, we'll use id in the User constructor
      
      String major = data.containsKey('major') ? data['major'] ?? '' : '';
      String pronouns = data.containsKey('pronouns') ? data['pronouns'] ?? '' : '';
      
      // Safely handle interests list
      List<String> interests = [];
      if (data.containsKey('interests') && data['interests'] != null) {
        interests = List<String>.from(data['interests']);
      }
      
      String bio = data.containsKey('bio') ? data['bio'] ?? '' : '';
      String profilePicture = data.containsKey('profile_picture') ? data['profile_picture'] ?? '' : '';
      
      users.add(User(
        id: id, 
        name: userName, // This might be null, but the User constructor will handle it
        major: major, 
        pronouns: pronouns, 
        interests: interests, 
        bio: bio,
        profilePicture: profilePicture,
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
        profilePicture: '',
      ),
      User(
        id: 'emilywilson',
        name: 'Emily Wilson',
        major: 'Psychology',
        pronouns: 'She/Her',
        interests: ['Reading', 'Music', 'Photography', 'Psychology'],
        bio: 'Psychology student interested in cognitive science and music therapy.',
        profilePicture: '',
      ),
      User(
        id: 'michaeljones',
        name: 'Michael Jones',
        major: 'Business',
        pronouns: 'He/Him',
        interests: ['Finance', 'Sports', 'Travel'],
        bio: 'Business student with a passion for finance and investments.',
        profilePicture: '',
      ),
      User(
        id: 'sophiadavis',
        name: 'Sophia Davis',
        major: 'Biology',
        pronouns: 'She/Her',
        interests: ['Science', 'Reading', 'Hiking', 'Technology'],
        bio: 'Future doctor studying Biology with a focus on genetics research.',
        profilePicture: '',
      ),
      User(
        id: 'jameswilliams',
        name: 'James Williams',
        major: 'Art History',
        pronouns: 'They/Them',
        interests: ['Art', 'Museums', 'Photography', 'Travel'],
        bio: 'Art history enthusiast exploring the intersections of modern and classical art.',
        profilePicture: '',
      ),
    ];
  }
}

// Define the categories and sub-categories as a nested map
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
  bool isLoading = true; // To track the loading state
  
  // Use late for controllers
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // Fetching user's own major and interests from Firestore or any other source
  // This should be replaced with actual user info in your app
  final String referenceMajor = 'Computer Science'; // Example major
  final List<String> referenceInterests = [
    'Technology', 'Gaming', 'Sports', 'Music'
  ]; // Example interests

  // Variables for load more functionality
  List<User> _displayedUsers = [];
  int _currentIndex = 0;
  final int _batchSize = 5;
  
  // Cache to store calculated scores
  final Map<String, double> _scoreCache = {};
  
  // Filter value for adjusting major vs interests weight
  double _filterValue = 0.5; // Default weight

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller with correct vsync
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Add scroll listener
    _scrollController.addListener(_scrollListener);
    
    // Initialize user list
    _initializeUserList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Show the onboarding screen when the info button is tapped
  void _showOnboardingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchingOnboardingScreen(fromInfoButton: true)),
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreUsers();
    }
  }

  // Helper function to find the category and sub-category of a major
  List<String>? getMajorCategoryAndSubcategory(String major) {
    for (var categoryEntry in categories.entries) {
      for (var subcategoryEntry in categoryEntry.value.entries) {
        if (subcategoryEntry.value.contains(major)) {
          return [categoryEntry.key, subcategoryEntry.key];
        }
      }
    }
    return null; // If major is not found
  }

  // Function to calculate proximity points
  double calculateProximityPoints(String major1, String major2) {
    // If both majors are the same
    if (major1 == major2) {
      return 3/3;
    }

    // Get categories and sub-categories of both majors
    List<String>? major1Details = getMajorCategoryAndSubcategory(major1);
    List<String>? major2Details = getMajorCategoryAndSubcategory(major2);

    if (major1Details == null || major2Details == null) {
      return 0/3; // If either major is not found
    }

    String category1 = major1Details[0];
    String subcategory1 = major1Details[1];
    String category2 = major2Details[0];
    String subcategory2 = major2Details[1];

    // If both majors are in the same subcategory
    if (category1 == category2 && subcategory1 == subcategory2) {
      return 2/3;
    }

    // If both majors are in the same category but different subcategories
    if (category1 == category2) {
      return 1/3;
    }

    // If majors are in different categories
    return 0/3;
  }

  // Optimized matching calculation function
  double calculateOptimizedScore(User user1, User user2) {
    // --- Major proximity calculation (Academic match) ---
    double majorProximity = calculateProximityPoints(user1.major, user2.major);
    
    // --- Interest overlap calculation (Social match) ---
    double interestOverlap = 0.0;
    if (user1.interests.isNotEmpty && user2.interests.isNotEmpty) {
      // Count matching interests
      int matchCount = 0;
      for (String interest in user1.interests) {
        if (user2.interests.contains(interest)) {
          matchCount++;
        }
      }
      
      // Calculate the overlap ratio - divided by the smaller list's size for better accuracy
      int smallerSize = min(user1.interests.length, user2.interests.length);
      if (smallerSize > 0) {
        interestOverlap = matchCount / smallerSize;
        
        // Apply a bonus for having multiple interests in common
        // This creates a non-linear curve where more matches are better
        if (matchCount > 1) {
          interestOverlap = interestOverlap * (1.0 + (0.1 * (matchCount - 1)));
        }
        
        // Cap at 1.0 maximum
        interestOverlap = min(interestOverlap, 1.0);
      }
    }
    
    // --- Bio keywords analysis ---
    // Find complementary keywords in bios for more nuanced matching
    double bioCompatibility = 0.0;
    if (user1.bio.isNotEmpty && user2.bio.isNotEmpty) {
      // Simple implementation - check for keyword overlap
      List<String> keywords = [
        'study', 'learning', 'friends', 'social', 'activities', 
        'sports', 'music', 'art', 'science', 'engineering', 
        'business', 'research', 'volunteer', 'clubs', 
        'freshman', 'transfer', 'new', 'roommate'
      ];
      
      Set<String> user1Keywords = {};
      Set<String> user2Keywords = {};
      
      // Extract keywords from bios
      for (String keyword in keywords) {
        if (user1.bio.toLowerCase().contains(keyword)) {
          user1Keywords.add(keyword);
        }
        if (user2.bio.toLowerCase().contains(keyword)) {
          user2Keywords.add(keyword);
        }
      }
      
      // Calculate overlap
      if (user1Keywords.isNotEmpty && user2Keywords.isNotEmpty) {
        Set<String> commonKeywords = user1Keywords.intersection(user2Keywords);
        int minSize = min(user1Keywords.length, user2Keywords.length);
        if (minSize > 0) {
          bioCompatibility = commonKeywords.length / minSize.toDouble();
          
          // Cap at 0.5 to avoid over-weighting this factor
          bioCompatibility = min(bioCompatibility, 0.5);
        }
      }
    }
    
    // --- Pronouns compatibility ---
    // Optional: add a small bonus for compatible pronouns if that's relevant to the matching
    double pronounsCompat = 0.0;
    if (user1.pronouns.isNotEmpty && user2.pronouns.isNotEmpty) {
      if (user1.pronouns == user2.pronouns || 
          user1.pronouns == 'All Pronouns' || 
          user2.pronouns == 'All Pronouns') {
        pronounsCompat = 0.1;  // Small bonus
      }
    }
    
    // --- Calculate weighted final score ---
    // Apply the user's prioritization preference via majorMultiplier
    double majorWeight = majorMultiplier;
    double interestWeight = 1.0 - majorMultiplier;
    
    // Add small weights to secondary factors
    double bioWeight = 0.15;
    double pronounsWeight = 0.05;
    
    // Normalize weights to sum to 1.0
    double totalWeight = majorWeight + interestWeight + bioWeight + pronounsWeight;
    majorWeight /= totalWeight;
    interestWeight /= totalWeight;
    bioWeight /= totalWeight;
    pronounsWeight /= totalWeight;
    
    // Calculate final score (0.0 to 1.0 range)
    double finalScore = (majorProximity * majorWeight) +
                       (interestOverlap * interestWeight) +
                       (bioCompatibility * bioWeight) +
                       (pronounsCompat * pronounsWeight);
    
    // Apply a curve for better spread of results (optional)
    // This will make high matches stand out more and low matches less relevant
    double curvedScore = pow(finalScore, 1.2).toDouble();
    
    return curvedScore;
  }

  double countMatchingInterests(List<String> interests1, List<String> interests2) {
    if (interests1.isEmpty) return 0;
    
    double commonInterests = 0;
    for (String interest in interests1) {
      if (interests2.contains(interest)) {
        commonInterests++;
      }
    }
    return interests1.isNotEmpty ? commonInterests / interests1.length : 0;
  }

  // Helper function to get color based on match percentage
  Color getMatchColor(int percentage) {
    if (percentage > 90) return Color(0xFF8BC34A); // Light green
    if (percentage > 80) return _kTraditionsColor;
    if (percentage > 70) return  _kSecondaryColor;
    return Color(0xFF9E9E9E); // Grey
  }

  // Modified calculation function with caching
  Future<List<User>> calculateScoresForUsers(String referenceMajor, List<String> referenceInterests) async {
    // Fetch users from Firestore
    List<User> users = await fetchUsersFromFirestore();

    // List to store users and their scores
    List<Map<String, dynamic>> userScores = [];

    // Compute scores for each user
    for (var user in users) {
      // Create a cache key based on user ID, reference major, and interests
      String cacheKey = '${user.id}_${referenceMajor}_${referenceInterests.join('_')}_$majorMultiplier';
      
      // Check if score is already cached
      if (_scoreCache.containsKey(cacheKey)) {
        userScores.add({
          'user': user,
          'score': _scoreCache[cacheKey]!,
        });
        continue;
      }
      
      // Calculate score using the optimized algorithm
      double totalScore = calculateOptimizedScore(
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
      
      // Cache the score
      _scoreCache[cacheKey] = totalScore;

      // Add user and score to the list
      userScores.add({
        'user': user,
        'score': totalScore,
      });
    }

    // Sort users by score in descending order
    userScores.sort((a, b) => b['score'].compareTo(a['score']));

    // Create a sorted list of users based on their scores
    List<User> sortedUsers = userScores.map((entry) => entry['user'] as User).toList();

    // Return the sorted list of users
    return sortedUsers;
  }

  // Clear cache when needed (e.g., when filter values change)
  void _clearScoreCache() {
    _scoreCache.clear();
  }

  // Initialize the user list by fetching data and sorting by score
  Future<void> _initializeUserList() async {
    List<User> sortedUsers = await calculateScoresForUsers(
        referenceMajor, referenceInterests
    );

    if (mounted) {
      setState(() {
        matchedUsers = sortedUsers;
        isLoading = false; // Set loading state to false when data is fetched
        _displayedUsers = []; // Clear displayed users
        _currentIndex = 0;
        _loadMoreUsers(); // Load initial batch of users
      });
    }
  }

  void _loadMoreUsers() {
    if (_currentIndex >= matchedUsers.length) return;
    
    final int endIndex = (_currentIndex + _batchSize) > matchedUsers.length
        ? matchedUsers.length
        : _currentIndex + _batchSize;

    if (mounted) {
      setState(() {
        _displayedUsers.addAll(matchedUsers.sublist(_currentIndex, endIndex));
        _currentIndex = endIndex;
      });
    }
  }

  int simplifiedMatchPercentage(User user){
    double proximityScore = calculateProximityPoints(referenceMajor, user.major);
    double interestScore = countMatchingInterests(referenceInterests, user.interests);
    double totalScore = (proximityScore * majorMultiplier) + (interestScore * (1 - majorMultiplier));

    return((totalScore * 100).round());
  }

  // Match explanation modal
  void _showMatchExplanation(BuildContext context, User user, int matchPercentage) {
    // Calculate actual scores for explanation
    double proximityScore = calculateProximityPoints(referenceMajor, user.major);
    double interestScore = countMatchingInterests(referenceInterests, user.interests);

    // Format scores as percentages
    int majorPercentage = (proximityScore * 100).round();
    int interestsPercentage = (interestScore * 100).round();
    int actualMatchPercentage = simplifiedMatchPercentage(user);
    
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
              const Text(
                'How We Matched You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Major match
              Row(
                children: [
                  const Icon(Icons.school, color: _kPrimaryColor, size: 20),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryColor,
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
                  const Icon(Icons.favorite, color: _kAccentColor, size: 20),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kAccentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Show common interests
              Wrap(
                spacing: 8,
                children: user.interests.map((interest) {
                  bool isCommon = referenceInterests.contains(interest);
                  return Chip(
                    label: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCommon ? _kPrimaryColor : Colors.grey[700],
                      ),
                    ),
                    backgroundColor: isCommon 
                        ? _kPrimaryColor.withOpacity(0.15)
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
                      color: getMatchColor(actualMatchPercentage),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$actualMatchPercentage%',
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
                    backgroundColor: _kPrimaryColor,
                    foregroundColor: Colors.white,
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

  // Filter widget with horizontal slider
  Widget _buildFilterWidget() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title at the top
        const Text(
          'Matching Priority:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kDarkText,
          ),
        ),
        const SizedBox(height: 12),
        
        // Slider with labels on sides
        Row(
          children: [
            // Left label (Interests)
            Text(
              'Interests',
              style: TextStyle(
                fontSize: 12,
                color: _filterValue < 0.5 ? _kPrimaryColor : Colors.grey[600],
                fontWeight: _filterValue < 0.5 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            
            // Slider (expanded to take available space)
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _kPrimaryColor,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: _kPrimaryColor,
                  overlayColor: _kPrimaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: _filterValue,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) {
                    setState(() {
                      _filterValue = value;
                      majorMultiplier = min(value, .99);
                      // Reset and reload matches with new weights
                      _clearScoreCache();
                      _displayedUsers = [];
                      _currentIndex = 0;
                      _initializeUserList();
                    });
                  },
                ),
              ),
            ),
            
            // Right label (Major)
            Text(
              'Major',
              style: TextStyle(
                fontSize: 12,
                color: _filterValue > 0.5 ? _kPrimaryColor : Colors.grey[600],
                fontWeight: _filterValue > 0.5 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find Your Match',
          style: TextStyle(
            color: _kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDarkText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add info button to reopen the onboarding
          IconButton(
            icon: const Icon(Icons.info_outline, color: _kPrimaryColor),
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
        children: const [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: _kPrimaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Finding your matches...',
            style: TextStyle(
              fontSize: 18,
              color: _kPrimaryColor,
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You\'ve Matched!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kDarkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ve found ${matchedUsers.length} RAMs that match your interests and academic focus.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Add filter widget
        SliverToBoxAdapter(
          child: _buildFilterWidget(),
        ),
        
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = _displayedUsers[index];
              
              // Calculate actual match percentage based on optimized score
              double score = calculateOptimizedScore(
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical:16),
            child: _currentIndex < matchedUsers.length
                ? Center(
                    child: CircularProgressIndicator(
                      color: _kPrimaryColor.withOpacity(0.5),
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

  // Improved user card for the matching screen
  Widget _buildUserCard(
    BuildContext context, {
    required User user,
    required int matchPercentage,
    required int index,
  }) {
    int simpleMatchPercentage = simplifiedMatchPercentage(user);
    // Handle profile picture or generate avatar
    Widget avatarWidget = _buildLetterAvatar(user.name);
    
    if (user.profilePicture.isNotEmpty) {
      try {
        // Try to display profile picture if it exists
        avatarWidget = Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            image: DecorationImage(
              image: FileImage(File(user.profilePicture)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        // Leave the default letter avatar if image loading fails
        print("Error loading profile image: $e");
      }
    }
    
    // Find common interests
    List<String> commonInterests = [];
    for (String interest in user.interests) {
      if (referenceInterests.contains(interest)) {
        commonInterests.add(interest);
      }
    }

    // Get color based on match percentage
    Color matchColor = getMatchColor(simpleMatchPercentage);
    
    // Improve bio preview - truncate if needed
    String bioPreview = user.bio;
    if (bioPreview.length > 120) {
      bioPreview = '${bioPreview.substring(0, 117)}...';
    }

    // Truncate name if too long
    final String displayName = user.name.length > 20 
        ? '${user.name.substring(0, 18)}...' 
        : user.name;

    return Card(
      elevation: 3, // Slightly more elevation for better shadow
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: matchPercentage > 80 ? matchColor.withOpacity(0.3) : Colors.transparent, 
          width: 1.5
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with avatar, name, and match percentage
            Row(
              children: [
                // Avatar with improved styling
                avatarWidget,
                const SizedBox(width: 16),
                
                // Name, major and pronouns with better styling
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kDarkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.school, size: 14, color: _kPrimaryColor.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.major,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _kPrimaryColor.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            user.pronouns,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Match percentage with improved visual
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: matchColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: matchColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$simpleMatchPercentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Info button
                    GestureDetector(
                      onTap: () => _showMatchExplanation(context, user, matchPercentage),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            'Match Details',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            
            // About section - with icon and better formatting
            if (user.bio.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_outlined, size: 16, color: _kPrimaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _kPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bioPreview,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Common Interests section with improved visuals
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite_outline, size: 16, color: _kAccentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Common Interests',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _kAccentColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (commonInterests.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kAccentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${commonInterests.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _kAccentColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Interest tags with improved style
                      SizedBox(
                        height: 32,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: user.interests.length,
                          itemBuilder: (context, index) {
                            final interest = user.interests[index];
                            final bool isCommon = commonInterests.contains(interest);
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCommon 
                                    ? _kPrimaryColor.withOpacity(0.15)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                border: isCommon 
                                    ? Border.all(color: _kPrimaryColor.withOpacity(0.3))
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCommon) ...[
                                    Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: _kPrimaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    interest,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCommon ? _kPrimaryColor : Colors.grey[700],
                                      fontWeight: isCommon ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons with improved styling
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Show full profile
                    _showDetailedProfile(context, user, matchPercentage);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: _kPrimaryColor.withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      const Text('View Profile', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Connecting with $displayName...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.connect_without_contact, size: 16),
                      const SizedBox(width: 4),
                      const Text('Connect', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create letter avatar
  Widget _buildLetterAvatar(String name) {
    final Random random = Random(name.hashCode);
    final Color avatarColor = Color.fromARGB(
      255,
      150 + random.nextInt(80),
      150 + random.nextInt(80),
      150 + random.nextInt(80),
    );
    
    // Extract first letter for avatar
    final String firstLetter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
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
          firstLetter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // New method to show detailed profile
  void _showDetailedProfile(BuildContext context, User user, int matchPercentage) {

    int simpleMatchPercentage = simplifiedMatchPercentage(user);
    // Handle profile picture for detailed view
    Widget avatarWidget = _buildBigLetterAvatar(user.name);
    
    if (user.profilePicture.isNotEmpty) {
      try {
        // Try to display profile picture if it exists
        avatarWidget = Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            image: DecorationImage(
              image: FileImage(File(user.profilePicture)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        // Leave the default letter avatar if image loading fails
        print("Error loading profile image for details view: $e");
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Make it expandable
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
                        color: _kDarkText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getMatchColor(simpleMatchPercentage),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$simpleMatchPercentage% Match',
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
                
                // Profile picture centered
                Center(child: avatarWidget),
                
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
                                iconColor: _kPrimaryColor,
                              ),
                              const SizedBox(height: 16),
                              
                              // Pronouns
                              _buildProfileField(
                                icon: Icons.person,
                                title: 'Pronouns',
                                value: user.pronouns,
                                iconColor: Colors.grey[700]!,
                              ),
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
                          color: _kPrimaryColor,
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
                          color: _kPrimaryColor,
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
                                  ? _kPrimaryColor.withOpacity(0.15)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: isCommon 
                                  ? Border.all(color: _kPrimaryColor.withOpacity(0.3))
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCommon) ...[
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: _kPrimaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  interest,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isCommon ? _kPrimaryColor : Colors.grey[700],
                                    fontWeight: isCommon ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      
                      // Connect button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Connecting with ${user.name}...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Connect',
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
  
  // Helper for larger letter avatar in details view
  Widget _buildBigLetterAvatar(String name) {
    final Random random = Random(name.hashCode);
    final Color avatarColor = Color.fromARGB(
      255,
      150 + random.nextInt(80),
      150 + random.nextInt(80),
      150 + random.nextInt(80),
    );
    
    // Extract first letter for avatar
    final String firstLetter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
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
          firstLetter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper for building profile fields
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
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _kDarkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}