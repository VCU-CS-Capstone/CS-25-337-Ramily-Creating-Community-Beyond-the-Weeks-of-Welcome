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
    {'name': 'DaJuan Hackett', 'major': 'Computer Science', 'pronouns': 'He/Him', 'interests': 'Technology, Sports, Gaming, Music', 'bio': 'What I’m most excited for at VCU is joining the computer science club and learning about artificial intelligence.'},
    {'name': 'Ethan Lucas', 'major': 'Environmental Studies', 'pronouns': 'He/Him', 'interests': 'Travel, Movies, Music, Literature', 'bio': 'I chose VCU because of the integration with the city and the focus on environmental research.'},
    {'name': 'Scott Grant', 'major': 'Design', 'pronouns': 'They/Them', 'interests': 'Art, Music, Movies, Fashion', 'bio': 'What I’m most excited for at VCU is collaborating on design projects and using creative software.'},
    {'name': 'Felix Webb', 'major': 'Psychology', 'pronouns': 'He/Him', 'interests': 'Travel, Photography, Reading, Fitness', 'bio': 'I chose VCU because of the diverse student body and its excellent psychology program.'},
    {'name': 'Vanessa Page', 'major': 'Electrical Engineering', 'pronouns': 'She/Her', 'interests': 'Coding, Hiking, Music, Photography', 'bio': 'What I’m most excited for at VCU is building and testing circuits as part of my engineering coursework.'},
    {'name': 'Sophia Davis', 'major': 'Nursing', 'pronouns': 'She/Her', 'interests': 'Fitness, Cooking, Reading, Hiking', 'bio': 'What I’m most excited for at VCU is gaining hands-on experience in the clinical setting.'},
    {'name': 'Michael Johnson', 'major': 'Finance', 'pronouns': 'He/Him', 'interests': 'Reading, Sports, Travel, Cooking', 'bio': 'I chose VCU because of its strong finance program and the internship opportunities available in Richmond.'},
    {'name': 'Ava Taylor', 'major': 'Biology', 'pronouns': 'She/Her', 'interests': 'Science, Music, Cooking, Hiking', 'bio': 'I chose VCU because of its cutting-edge research in genetics and the opportunity to work with faculty on lab projects.'},
    {'name': 'Liam Roberts', 'major': 'History', 'pronouns': 'He/Him', 'interests': 'Reading, Travel, Writing, Photography', 'bio': 'What I’m most excited for at VCU is learning about world history from different cultural perspectives.'},
    {'name': 'Mia Brown', 'major': 'Computer Engineering', 'pronouns': 'She/Her', 'interests': 'Technology, Gaming, Photography, Music', 'bio': 'What I’m most excited for at VCU is working on projects that blend technology and design.'},
    {'name': 'Benjamin Green', 'major': 'Political Science', 'pronouns': 'He/Him', 'interests': 'Movies, Reading, Travel, Photography', 'bio': 'I chose VCU because it offers a strong political science program with an emphasis on public policy.'},
    {'name': 'Lucas White', 'major': 'Mathematical Sciences', 'pronouns': 'He/Him', 'interests': 'Science, Technology, Gaming, Photography', 'bio': 'What I’m most excited for at VCU is solving real-world problems using mathematical modeling.'},
    {'name': 'Olivia Adams', 'major': 'Art History', 'pronouns': 'She/Her', 'interests': 'Art, Travel, Photography, Fashion', 'bio': 'I chose VCU because of its strong art history program and the opportunity to study abroad.'},
    {'name': 'William Harris', 'major': 'Chemistry', 'pronouns': 'He/Him', 'interests': 'Science, Fitness, Music, Travel', 'bio': 'I chose VCU because of the chemistry department’s focus on hands-on experiments and research.'},
    {'name': 'Emma Walker', 'major': 'Dance and Choreography', 'pronouns': 'She/Her', 'interests': 'Dance, Music, Fitness, Photography', 'bio': 'What I’m most excited for at VCU is performing in the spring dance showcase and collaborating with other artists.'},
    {'name': 'James Lee', 'major': 'Sociology', 'pronouns': 'He/Him', 'interests': 'Reading, Writing, Politics, Music', 'bio': 'What I’m most excited for at VCU is engaging in research projects about social issues and inequalities.'},
    {'name': 'Zoe Young', 'major': 'Psychology', 'pronouns': 'She/Her', 'interests': 'Travel, Writing, Movies, Art', 'bio': 'I chose VCU because it has a renowned psychology program with plenty of opportunities for internships.'},
    {'name': 'Ella Scott', 'major': 'Philosophy', 'pronouns': 'She/Her', 'interests': 'Reading, Writing, Philosophy, Music', 'bio': 'What I’m most excited for at VCU is exploring existentialism and applying philosophical concepts to everyday life.'},
    {'name': 'Jackson King', 'major': 'Mechanical Engineering', 'pronouns': 'He/Him', 'interests': 'Technology, Sports, Movies, Music', 'bio': 'What I’m most excited for at VCU is designing prototypes for engineering solutions and applying them to real-world problems.'},
    {'name': 'Aiden Carter', 'major': 'Finance', 'pronouns': 'He/Him', 'interests': 'Music, Reading, Gaming, Fitness', 'bio': 'I chose VCU because of its practical approach to finance education and career readiness.'},
    {'name': 'Sophia Hall', 'major': 'Marketing', 'pronouns': 'She/Her', 'interests': 'Fashion, Photography, Writing, Music', 'bio': 'What I’m most excited for at VCU is learning the latest marketing strategies and how to apply them in business.'},
    {'name': 'Mason King', 'major': 'Health Services', 'pronouns': 'He/Him', 'interests': 'Sports, Fitness, Cooking, Hiking', 'bio': 'What I’m most excited for at VCU is gaining real-world experience working in health administration.'},
    {'name': 'Isabella Baker', 'major': 'Mechanical Engineering', 'pronouns': 'She/Her', 'interests': 'Science, Technology, Hiking, Photography', 'bio': 'I chose VCU because of its comprehensive engineering program and its focus on sustainability.'},
    {'name': 'Liam Allen', 'major': 'Biomedical Engineering', 'pronouns': 'He/Him', 'interests': 'Technology, Science, Fitness, Hiking', 'bio': 'What I’m most excited for at VCU is developing innovative solutions for the healthcare industry.'},
    {'name': 'Madison Nelson', 'major': 'Communication Arts', 'pronouns': 'She/Her', 'interests': 'Art, Travel, Photography, Fashion', 'bio': 'What I’m most excited for at VCU is improving my creative skills and building a portfolio for future opportunities.'},
    {'name': 'Jacob Martinez', 'major': 'Political Science', 'pronouns': 'He/Him', 'interests': 'Reading, Sports, Politics, Movies', 'bio': 'What I’m most excited for at VCU is engaging in discussions about the future of global politics and social change.'},
    {'name': 'Lily Carter', 'major': 'Art History', 'pronouns': 'She/Her', 'interests': 'Art, Travel, Photography, Literature', 'bio': 'I chose VCU because of its strong focus on contemporary art and global art history.'},
    {'name': 'Daniel Evans', 'major': 'History', 'pronouns': 'He/Him', 'interests': 'Travel, Literature, Reading, Politics', 'bio': 'What I’m most excited for at VCU is exploring the connections between historical events and contemporary culture.'},
    // Additional users could be added here...
  ];

  // New variables for load more functionality
  List<Map<String, String>> _shuffledUsers = [];
  int _currentIndex = 0;
  final int _batchSize = 5;

  @override
  void initState() {
    super.initState();
    _initializeUserList();
  }

  void _initializeUserList() {
    final random = Random();
    _shuffledUsers = List<Map<String, String>>.from(allUsers)..shuffle(random);
    _currentIndex = 0;
    matchedUsers = [];
    _loadMoreUsers();
  }

  void _loadMoreUsers() {
    final int endIndex = (_currentIndex + _batchSize) > _shuffledUsers.length
        ? _shuffledUsers.length
        : _currentIndex + _batchSize;
    setState(() {
      matchedUsers.addAll(_shuffledUsers.sublist(_currentIndex, endIndex));
      _currentIndex = endIndex;
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
            _currentIndex < _shuffledUsers.length
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
