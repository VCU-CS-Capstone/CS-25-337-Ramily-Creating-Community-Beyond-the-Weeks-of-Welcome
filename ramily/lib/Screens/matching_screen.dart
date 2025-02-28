import 'package:flutter/material.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy matched users
    final List<Map<String, String>> matchedUsers = [
      {
        'name': 'Libbie Curtis',
        'description':
            'I craft delicious meals, conquer virtual races, and stay active by hitting the pavement.',
      },
      {
        'name': 'Howard Bradford',
        'description':
            'On a mission to savor every bite, conquer every level, and explore the great outdoors.',
      },
      {
        'name': 'Jak Saunders',
        'description':
            'Finding joy in exploring the world through flavors, pixels, and active pursuits.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Congratulations Heading
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Sub-heading / Explanation
            const Text(
              'You’ve matched with 100 other RAMS!\nHere are your top 3 matches with a 99% overlap in interests.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // List of matched users
            Column(
              children: matchedUsers.map((user) {
                return _buildUserCard(
                  context,
                  name: user['name']!,
                  description: user['description']!,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a user card
  Widget _buildUserCard(
    BuildContext context, {
    required String name,
    required String description,
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
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Contact Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Example: show a snackbar or open a chat
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
