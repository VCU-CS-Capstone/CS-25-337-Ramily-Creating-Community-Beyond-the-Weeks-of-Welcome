import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class User {
  final String id;
  final String major;
  final String pronouns;
  final List<String> interests;
  final String bio;

  User({required this.id, required this.major, required this.pronouns, required this.interests, required this.bio});
}

double majorMultiplier = .5;

// Fetch users from Firestore
Future<List<User>> fetchUsersFromFirestore() async {
  final userCollection = FirebaseFirestore.instance.collection('users');
  final snapshot = await userCollection.get();

  List<User> users = [];
  for (var doc in snapshot.docs) {
    String id = doc.id;
    String major = doc['major'];
    String pronouns = doc['pronouns'];
    List<String> interests = List<String>.from(doc['interests']);
    String bio = doc['bio'];
    users.add(User(id: id, major: major, pronouns: pronouns, interests: interests, bio: bio));
  }
  return users;
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
      'Gender, Sexuality and Women’s Studies',
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


class _MatchingScreenState extends State<MatchingScreen> {
  List<User> matchedUsers = [];
  bool isLoading = true; // To track the loading state

  // Fetching user's own major and interests from Firestore or any other source
  // This should be replaced with actual user info in your app, for example:
  final String referenceMajor = 'Computer Science'; // Example major
  final List<String> referenceInterests = [
    'Technology', 'Gaming', 'Sports', 'Music'
  ]; // Example interests

  // New variables for load more functionality
  List<User> _shuffledUsers = [];
  int _currentIndex = 0;
  final int _batchSize = 5;

  @override
  void initState() {
    super.initState();
    _initializeUserList();
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

  double countMatchingInterests(List<String> interests1, List<String> interests2) {
    double commonInterests = 0;
    for (String interest in interests1) {
      if (interests2.contains(interest)) {
        commonInterests++;
      }
    }
    return commonInterests / (interests1.length);
  }

  Future<List<User>> calculateScoresForUsers(String referenceMajor, List<String> referenceInterests) async {
    // Fetch users from Firestore
    List<User> users = await fetchUsersFromFirestore();

    // List to store users and their scores
    List<Map<String, dynamic>> userScores = [];

    // Compute scores for each user
    for (var user in users) {
      double proximityScore = calculateProximityPoints(referenceMajor, user.major);
      double interestScore = countMatchingInterests(referenceInterests, user.interests);
      double totalScore = (proximityScore * majorMultiplier) + (interestScore * (1 - majorMultiplier));

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

  // Initialize the user list by fetching data and sorting by score
  Future<void> _initializeUserList() async {
    List<User> sortedUsers = await calculateScoresForUsers(
        referenceMajor, referenceInterests
    );

    setState(() {
      matchedUsers = sortedUsers;
      isLoading = false; // Set loading state to false when data is fetched
    });
  }

  void _loadMoreUsers() {
    final int endIndex = (_currentIndex + _batchSize) > matchedUsers.length
        ? matchedUsers.length
        : _currentIndex + _batchSize;

    setState(() {
      _shuffledUsers.addAll(matchedUsers.sublist(_currentIndex, endIndex));
      _currentIndex = endIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading state
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You’ve matched with 100 other RAMS!\nHere are your top matches with a 99% overlap in interests.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: _shuffledUsers.map((user) {
                return _buildUserCard(
                  context,
                  name: user.id, // Use actual user name
                  major: user.major,
                  pronouns: user.pronouns, // You can add pronouns to the User model
                  interests: user.interests.join(', '),
                  bio: user.bio, // Add bio to User model as well
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _currentIndex < matchedUsers.length
                ? ElevatedButton(
              onPressed: _loadMoreUsers,
              child: const Text('Load More'),
            )
                : const Text('No more users'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
      BuildContext context, {
        required String name,
        required String major,
        required String pronouns,
        required String interests,
        required String bio,
      }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Placeholder
            Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
              alignment: Alignment.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Name: $name',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Major: $major'),
            const SizedBox(height: 4),
            Text('Pronouns: $pronouns'),
            const SizedBox(height: 4),
            Text('Interests: $interests'),
            const SizedBox(height: 8),
            Text(
              'Bio: $bio',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contacting $name...')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                ),
                child: const Text('Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
