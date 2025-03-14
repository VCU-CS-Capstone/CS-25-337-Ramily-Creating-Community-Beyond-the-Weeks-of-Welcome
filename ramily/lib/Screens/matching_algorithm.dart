import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String major;
  final List<String> interests;

  User({required this.id, required this.major, required this.interests});
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
    List<String> interests = List<String>.from(doc['interests']);
    users.add(User(id: id, major: major, interests: interests));
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

