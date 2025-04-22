import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:math' as math;
import 'constants.dart' as constants;

class TraditionsScreen extends StatefulWidget {
  const TraditionsScreen({super.key});

  @override
  _TraditionsScreenState createState() => _TraditionsScreenState();
}

class _TraditionsScreenState extends State<TraditionsScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _traditions = [];
  Map<String, bool> _completedTraditions = {};
  late AnimationController _animationController;
  final bool _showPrizeModal = false;
  bool _isShowingModal = false;

  // Create a list of traditions with descriptions and locations
  final List<Map<String, dynamic>> _traditionsList = [
    {
      'id': 'compass',
      'name': 'The Compass',
      'description': 'Visit the iconic Compass, the heart of VCU\'s Monroe Park Campus.',
      'points': 10,
      'location': 'Outside of Hibbs Hall',
      'coordinates': {'lat': 37.5491, 'lng': -77.4512},
      'image': 'assets/traditions/compass.jpg', // Using PNG extension
    },
    {
      'id': 'cabell_library',
      'name': 'Cabell Library',
      'description': 'Explore VCU\'s award-winning Cabell Library, a central hub for studying and research.',
      'points': 10,
      'location': '901 Park Ave, Richmond, VA 23284',
      'coordinates': {'lat': 37.5482, 'lng': -77.4520},
      'image': 'assets/traditions/cabell_library.jpg',
    },
    {
      'id': 'the_ram_horns',
      'name': 'The Ram Horns',
      'description': 'Take a photo with the Ram Horns statue outside the Student Commons.',
      'points': 15,
      'location': 'University Student Commons',
      'coordinates': {'lat': 37.5497, 'lng': -77.4509},
      'image': 'assets/traditions/ram_horns.jpg', // Using an existing logo image as placeholder
    },
    {
      'id': 'shafer_court',
      'name': 'Shafer Court',
      'description': 'Enjoy the vibrant atmosphere of Shafer Court, a popular outdoor dining area.',
      'points': 10,
      'location': 'Between Shafer St and Franklin St',
      'coordinates': {'lat': 37.5488, 'lng': -77.4526},
      'image': 'assets/traditions/shafer_court.jpg', // Using a placeholder
    },
    {
      'id': 'siegel_center',
      'name': 'Stuart C. Siegel Center',
      'description': 'Experience the energy of VCU Basketball at the Siegel Center, home of the Rams.',
      'points': 20,
      'location': '1200 W Broad St, Richmond, VA 23284',
      'coordinates': {'lat': 37.5560, 'lng': -77.4536},
      'image': 'assets/traditions/siegel_center.jpg', // Using a placeholder
    },
    {
      'id': 'cary_street_gym',
      'name': 'Cary Street Gym',
      'description': 'Visit the state-of-the-art recreation facility with climbing walls and indoor pool.',
      'points': 10,
      'location': '101 S Linden St, Richmond, VA 23220',
      'coordinates': {'lat': 37.5420, 'lng': -77.4512},
      'image': 'assets/traditions/cary_street_gym.jpg', // Using a placeholder
    },
    {
      'id': 'spring_fest',
      'name': 'Spring Fest',
      'description': 'Participate in the annual Spring Fest celebration with music, food, and activities.',
      'points': 25,
      'location': 'Monroe Park',
      'coordinates': {'lat': 37.5465, 'lng': -77.4520},
      'image': 'assets/traditions/spring_fest.jpg', // Using a placeholder
      'seasonal': true,
      'season': 'Spring',
    },
    {
      'id': 'monroe_park',
      'name': 'Monroe Park',
      'description': 'Relax in the historic Monroe Park, the oldest park in Richmond.',
      'points': 10,
      'location': 'Between Main, Belvidere, Franklin, and Laurel Streets',
      'coordinates': {'lat': 37.5465, 'lng': -77.4520},
      'image': 'assets/traditions/monroe_park.jpg', // Using a placeholder
    },
    {
      'id': 'peppas_birthday',
      'name': 'Rodney the Ram\'s Birthday',
      'description': 'Celebrate the birthday of VCU\'s beloved mascot, Rodney the Ram.',
      'points': 30,
      'location': 'Commons Plaza',
      'coordinates': {'lat': 37.5497, 'lng': -77.4509},
      'image': 'assets/traditions/rodney.jpg', // Using a placeholder
      'seasonal': true,
      'season': 'Fall',
    },
    {
      'id': 'snead_hall',
      'name': 'Snead Hall',
      'description': 'Visit the home of the VCU School of Business with its impressive architecture.',
      'points': 10,
      'location': '301 W Main St, Richmond, VA 23284',
      'coordinates': {'lat': 37.5460, 'lng': -77.4556},
      'image': 'assets/traditions/snead_hall.jpg', // Using a placeholder
    }
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadTraditions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to check if an image exists
  bool _imageExists(String path) {
    try {
      return true;
    } catch (_) {
      return false;
    }
  }

  // Load traditions and completion status from Firestore
  Future<void> _loadTraditions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      // Get user's completed traditions from Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('completedTraditions')) {
          final completedData = userData['completedTraditions'] as Map<String, dynamic>;
          _completedTraditions = Map<String, bool>.from(
            completedData.map((key, value) => MapEntry(key, value as bool))
          );
        }
      } else {
        // Create a user traditions document if it doesn't exist
        await _firestore.collection('users').doc(currentUser.uid).set({
          'completedTraditions': {},
        }, SetOptions(merge: true));
      }

      // Create a copy of the traditions list for state
      setState(() {
        _traditions = List<Map<String, dynamic>>.from(_traditionsList);
        _isLoading = false;
      });
      
      // Check for prize after loading (with a slight delay to allow UI to render)
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkForPrize();
      });
      
    } catch (e) {
      print('Error loading traditions: $e');
      setState(() {
        _isLoading = false;
        _traditions = List<Map<String, dynamic>>.from(_traditionsList);
      });
    }
  }

  // Check if all traditions are completed to show the prize modal
  void _checkForPrize() {
    // Filter out seasonal traditions when checking for completion
    final requiredTraditions = _traditions.where((tradition) => 
      !(tradition['seasonal'] == true)).toList();
      
    bool allCompleted = requiredTraditions.every(
      (tradition) => _completedTraditions[tradition['id']] == true
    );
    
    if (allCompleted && requiredTraditions.isNotEmpty && !_isShowingModal) {
      // Use post-frame callback to avoid build issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isShowingModal && mounted) {
          _displayPrizeRedemptionModal();
        }
      });
    }
  }

  // Toggle the completion status of a tradition
  Future<void> _toggleTraditionStatus(String traditionId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      // Update local state first for responsive UI
      setState(() {
        _completedTraditions[traditionId] = !(_completedTraditions[traditionId] ?? false);
      });

      // Play animation
      _animationController.reset();
      _animationController.forward();

      // Update in Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'completedTraditions.$traditionId': _completedTraditions[traditionId],
      });

      // Check if all traditions are completed after toggling
      _checkForPrize();
      
    } catch (e) {
      print('Error toggling tradition status: $e');
      // Revert state if update failed
      setState(() {
        _completedTraditions[traditionId] = !(_completedTraditions[traditionId] ?? false);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating tradition status: $e'))
      );
    }
  }

  // Calculate the total progress percentage
  double _calculateProgress() {
    if (_traditions.isEmpty) return 0.0;
    
    int completed = 0;
    int total = 0;
    
    // Only count non-seasonal traditions for the progress calculation
    for (var tradition in _traditions) {
      if (tradition['seasonal'] == true) continue;
      
      total++;
      if (_completedTraditions[tradition['id']] == true) {
        completed++;
      }
    }
    
    return total > 0 ? completed / total : 0.0;
  }

  // Calculate total points earned
  int _calculatePoints() {
    int totalPoints = 0;
    for (var tradition in _traditions) {
      if (_completedTraditions[tradition['id']] == true) {
        totalPoints += tradition['points'] as int;
      }
    }
    return totalPoints;
  }

  // Show the tradition detail modal
  void _showTraditionDetail(BuildContext context, Map<String, dynamic> tradition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                // Image header with stamp overlay if completed
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Placeholder for tradition image
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        image: _imageExists(tradition['image']) 
                            ? DecorationImage(
                                image: AssetImage(tradition['image']),
                                fit: BoxFit.cover,
                                colorFilter: _completedTraditions[tradition['id']] == true
                                    ? ColorFilter.mode(
                                        Colors.black.withOpacity(0.2),
                                        BlendMode.darken,
                                      )
                                    : null,
                              )
                            : null,
                      ),
                    ),
                    
                    // Stamp overlay if completed
                    if (_completedTraditions[tradition['id']] == true)
                      Transform.rotate(
                        angle: -math.pi / 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: constants.kVCUGold,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: constants.kVCUGold,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Title and points
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tradition['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: constants.kVCUBlack,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: constants.kVCUGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            color: constants.kVCUBlack,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${tradition['points']} pts',
                            style: const TextStyle(
                              color: constants.kVCUBlack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Season badge if seasonal
                if (tradition['seasonal'] == true)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: constants.kVCURed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: constants.kVCURed,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event,
                          color: constants.kVCURed,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Seasonal: ${tradition['season']} Event",
                          style: const TextStyle(
                            color: constants.kVCURed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Description
                Text(
                  tradition['description'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Location
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on,
                    color: constants.kVCUBlue,
                  ),
                  title: const Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: constants.kVCUBlack,
                    ),
                  ),
                  subtitle: Text(
                    tradition['location'],
                    style: const TextStyle(
                      color: constants.kVCULightText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // GPS verification section instead of QR
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'GPS Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: constants.kVCUBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: constants.kVCULightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.location_searching,
                              size: 48,
                              color: constants.kVCUBlue,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Visit this location and use the button below to verify your visit using GPS.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: constants.kVCULightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Complete/Uncomplete button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleTraditionStatus(tradition['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _completedTraditions[tradition['id']] == true
                        ? Colors.red[100]
                        : constants.kVCUGold,
                    foregroundColor: _completedTraditions[tradition['id']] == true
                        ? Colors.red[800]
                        : constants.kVCUBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _completedTraditions[tradition['id']] == true
                        ? 'Mark as Incomplete'
                        : 'Mark as Complete',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Show the prize redemption modal

void _displayPrizeRedemptionModal() {
  // Set flag to prevent multiple modals
  _isShowingModal = true;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8, // Control the height as a fraction of screen height
      child: SingleChildScrollView( // Make the content scrollable to avoid overflow
        child: Container(
          padding: const EdgeInsets.all(20), // Reduced padding
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use minimum height needed
            children: [
              // Trophy icon
              Container(
                height: 80, // Smaller size
                width: 80,
                decoration: BoxDecoration(
                  color: constants.kVCUGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 50, // Smaller icon
                  color: constants.kVCUGold,
                ),
              ),
              const SizedBox(height: 16), // Smaller spacing
              
              // Congratulations text
              const Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  fontSize: 24, // Slightly smaller font
                  fontWeight: FontWeight.bold,
                  color: constants.kVCUBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // Smaller spacing
              Text(
                'You\'ve completed all required VCU Traditions!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16), // Smaller spacing
              
              // Prize image
              Container(
                height: 120, // Smaller size
                width: 120,
                decoration: BoxDecoration(
                  color: constants.kVCUGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: constants.kVCUGold,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.card_giftcard,
                    size: 60, // Smaller icon
                    color: constants.kVCUGold,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Smaller spacing
              
              // Prize description
              const Text(
                'You\'ve earned a special VCU Gift Pack!',
                style: TextStyle(
                  fontSize: 18, // Slightly smaller font
                  fontWeight: FontWeight.bold,
                  color: constants.kVCUBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // Smaller spacing
              Text(
                'Visit the Student Commons Information Desk to claim your prize.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Close button
              ElevatedButton(
                onPressed: () {
                  _isShowingModal = false; // Reset flag when closing
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: constants.kVCUGold,
                  foregroundColor: constants.kVCUBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Got it!'),
              ),
              const SizedBox(height: 16), // Add bottom padding to ensure button isn't cut off
            ],
          ),
        ),
      ),
    ),
  ).then((_) {
    // Reset flag when modal is closed
    _isShowingModal = false;
  });
}

  @override
  Widget build(BuildContext context) {
    // Calculate progress
    final double progress = _calculateProgress();
    final int totalPoints = _calculatePoints();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'VCU Traditions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About VCU Traditions'),
                  content: const Text(
                    'Visit iconic locations around campus to complete your VCU Traditions card! '
                    'Verify your location using GPS when you arrive at each destination. '
                    'Complete all traditions to earn a special VCU prize!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress indicator section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      // Circular progress indicator
                      CircularPercentIndicator(
                        radius: 60.0,
                        lineWidth: 12.0,
                        percent: progress,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: constants.kVCUBlack,
                              ),
                            ),
                            const Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 12,
                                color: constants.kVCULightText,
                              ),
                            ),
                          ],
                        ),
                        progressColor: constants.kVCUGold,
                        backgroundColor: constants.kVCULightGrey,
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animationDuration: 1200,
                      ),
                      const SizedBox(width: 20),
                      
                      // Points and completed count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Points earned - Fixed to prevent overflow
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: constants.kVCUGold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: constants.kVCUGold.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: constants.kVCUGold,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$totalPoints Points',
                                      style: const TextStyle(
                                        color: constants.kVCUBlack,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Traditions completed count
                            Text(
                              '${_completedTraditions.values.where((v) => v).length} of ${_traditions.where((t) => t['seasonal'] != true).length} Traditions Completed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            
                            // Complete all to earn prize text - Fixed to prevent overflow
                            if (progress < 1.0) ...[
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: constants.kVCURed,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Complete all for a prize!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: constants.kVCURed,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: _isShowingModal ? null : _displayPrizeRedemptionModal,
                                icon: const Icon(
                                  Icons.card_giftcard,
                                  color: constants.kVCUGold,
                                ),
                                label: const Text(
                                  'Claim Your Prize!',
                                  style: TextStyle(
                                    color: constants.kVCUGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  backgroundColor: constants.kVCUGold.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                const Divider(height: 1),
                
                // Traditions list section
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    children: [
                      // Section headers
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Campus Traditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: constants.kVCUBlack,
                          ),
                        ),
                      ),
                      
                      // Regular traditions
                      ...(_traditions.where((t) => t['seasonal'] != true).toList()
                        ..sort((a, b) {
                          // Show completed traditions at the bottom
                          bool aCompleted = _completedTraditions[a['id']] ?? false;
                          bool bCompleted = _completedTraditions[b['id']] ?? false;
                          
                          if (aCompleted && !bCompleted) return 1;
                          if (!aCompleted && bCompleted) return -1;
                          
                          // Otherwise sort by name
                          return a['name'].compareTo(b['name']);
                        }))
                        .map((tradition) => _buildTraditionCard(tradition))
                        ,
                      
                      // Seasonal events header
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 20,
                              color: constants.kVCURed,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Seasonal Events',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: constants.kVCUBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Seasonal traditions
                      ...(_traditions.where((t) => t['seasonal'] == true).toList()
                        ..sort((a, b) {
                          // Sort by completion status, then by name
                          bool aCompleted = _completedTraditions[a['id']] ?? false;
                          bool bCompleted = _completedTraditions[b['id']] ?? false;
                          
                          if (aCompleted && !bCompleted) return 1;
                          if (!aCompleted && bCompleted) return -1;
                          
                          return a['name'].compareTo(b['name']);
                        }))
                        .map((tradition) => _buildTraditionCard(tradition, isSeasonalEvent: true))
                        ,
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Build tradition card widget
  Widget _buildTraditionCard(Map<String, dynamic> tradition, {bool isSeasonalEvent = false}) {
    // Check if the tradition is completed
    final bool isCompleted = _completedTraditions[tradition['id']] ?? false;
    
    return GestureDetector(
      onTap: () => _showTraditionDetail(context, tradition),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? constants.kVCUGold : Colors.grey[300]!,
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side with image and completion stamp
            Stack(
              alignment: Alignment.center,
              children: [
                // Tradition image (with fallback for missing images)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    image: _imageExists(tradition['image']) ? DecorationImage(
                      image: AssetImage(tradition['image']),
                      fit: BoxFit.cover,
                      colorFilter: isCompleted
                          ? ColorFilter.mode(
                              Colors.black.withOpacity(0.2),
                              BlendMode.darken,
                            )
                          : null,
                    ) : null,
                  ),
                  // If no image, show a placeholder icon
                  child: _imageExists(tradition['image']) ? null : Icon(
                    Icons.location_on,
                    color: Colors.grey[500],
                    size: 40,
                  ),
                ),
                
                // Completion stamp overlay
                if (isCompleted)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: constants.kVCUGold,
                        size: 40,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Right side with tradition details
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tradition name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tradition['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? constants.kVCUGold : constants.kVCUBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Points badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: constants.kVCUGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars,
                                color: constants.kVCUGold,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${tradition['points']}',
                                style: const TextStyle(
                                  color: constants.kVCUGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Seasonal event badge for seasonal items
                    if (isSeasonalEvent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: constants.kVCURed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tradition['season'],
                          style: const TextStyle(
                            color: constants.kVCURed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    // Description
                    Text(
                      tradition['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Location with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: constants.kVCUBlue,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tradition['location'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: constants.kVCULightText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}