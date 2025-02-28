import 'package:flutter/material.dart';
import 'dart:math';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  List<Map<String, String>> matchedUsers = [];

  final List<Map<String, String>> allUsers = [
    {'name': 'DaJuan Hackett', 'major': 'Computer Science', 'pronouns': 'He/Him', 'interests': 'Technology, Sports, Gaming, Music', 'bio': 'I chose VCU because of the diversity.'},
    {'name': 'Ethan Lucas', 'major': 'Environmental Studies', 'pronouns': 'He/Him', 'interests': 'Travel, Movies, Music, Literature', 'bio': 'I chose VCU because of the integration with the city.'},
    {'name': 'Jak Saunders', 'major': 'Design', 'pronouns': 'They/Them', 'interests': 'Art, Music, Movies', 'bio': 'I chose VCU because it’s a creative and innovative environment.'},
    {'name': 'Alex Martinez', 'major': 'Psychology', 'pronouns': 'He/Him', 'interests': 'Travel, Photography, Reading', 'bio': 'I chose VCU for its diverse student body and academic rigor.'},
    {'name': 'Jamie Lee', 'major': 'Electrical Engineering', 'pronouns': 'She/Her', 'interests': 'Coding, Hiking, Music', 'bio': 'I chose VCU because of the excellent engineering program.'},
    // Add more users as needed...
  ];

  @override
  void initState() {
    super.initState();
    _reloadUserList();
  }

  void _reloadUserList() {
    final random = Random();
    final shuffledList = List<Map<String, String>>.from(allUsers)..shuffle(random); // Shuffle the list with a random seed
    setState(() {
      matchedUsers = shuffledList.take(5).toList(); // Take the first 5 users from the shuffled list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching'),
      ),
      body: SingleChildScrollView(
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
              children: matchedUsers.map((user) {
                return _buildUserCard(
                  context,
                  name: user['name']!,
                  major: user['major']!,
                  pronouns: user['pronouns']!,
                  interests: user['interests']!,
                  bio: user['bio']!,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _reloadUserList,
              child: const Text('Reload List'),
            ),
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
            // Name
            Text(
              'Name: $name',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Major
            Text('Major: $major'),
            const SizedBox(height: 4),

            // Pronouns
            Text('Pronouns: $pronouns'),
            const SizedBox(height: 4),

            // Interests
            Text('Interests: $interests'),
            const SizedBox(height: 8),

            // Bio (static prompt + user-specific bio)
            Text(
              'Bio: $bio',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Contact Button
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
