import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'matching_screen.dart';
import 'constants.dart' as constants;

class MatchingOnboardingScreen extends StatefulWidget {
  final bool fromInfoButton;
  
  const MatchingOnboardingScreen({
    Key? key, 
    this.fromInfoButton = false
  }) : super(key: key);

  @override
  State<MatchingOnboardingScreen> createState() => _MatchingOnboardingScreenState();
}

class _MatchingOnboardingScreenState extends State<MatchingOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Mark the onboarding as completed in Firestore
  Future<void> _completeOnboarding() async {
    // Only update Firestore if this isn't accessed from the info button
    if (!widget.fromInfoButton) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      try {
        // Update user document in Firestore to mark onboarding as completed
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'matchingOnboardingCompleted': true,
        });
      } catch (e) {
        print('Error updating onboarding status: $e');
        // If update fails, try to set the document instead
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'matchingOnboardingCompleted': true,
          }, SetOptions(merge: true));
        } catch (innerError) {
          print('Error setting onboarding status: $innerError');
        }
      }
    }
    
    if (!mounted) return;
    
    // If accessed from the info button, just go back
    if (widget.fromInfoButton) {
      Navigator.pop(context);
    } else {
      // Otherwise, navigate to the matching screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MatchingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: constants.kVCUBlack),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              widget.fromInfoButton ? 'Close' : 'Skip',
              style: const TextStyle(
                color: constants.kVCUBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Find Your Perfect Match',
                    description: 'Connect with fellow VCU students who share your academic interests and personal passions.',
                    image: Icons.people_outline,
                    imageColor: const Color(0xFF8D5E8B), // _kPrimaryColor from matching_screen
                    backgroundColor: const Color(0xFF8D5E8B).withOpacity(0.1),
                  ),
                  _buildPage(
                    title: 'How It Works',
                    description: 'Our smart matching algorithm considers your major, interests, and preferences to suggest compatible connections.',
                    image: Icons.lightbulb_outline,
                    imageColor: constants.kVCUGold,
                    backgroundColor: constants.kVCUGold.withOpacity(0.1),
                  ),
                  _buildPage(
                    title: 'Get Started',
                    description: 'Adjust the slider to prioritize academic matches or shared interests, then connect with your top matches!',
                    image: Icons.handshake_outlined,
                    imageColor: constants.kVCUGreen,
                    backgroundColor: constants.kVCUGreen.withOpacity(0.1),
                  ),
                ],
              ),
            ),
            
            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _numPages,
                    effect: WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      spacing: 16,
                      radius: 10,
                      dotColor: Colors.grey[300]!,
                      activeDotColor: constants.kVCUGold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (hidden on first page)
                  _currentPage > 0
                      ? TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              color: constants.kVCUBlack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const SizedBox(width: 60),
                  
                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _numPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: constants.kVCUGold,
                      foregroundColor: constants.kVCUBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentPage < _numPages - 1 
                          ? 'Next' 
                          : widget.fromInfoButton ? 'Done' : 'Get Started',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData image,
    required Color imageColor,
    required Color backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with background
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              image,
              size: 80,
              color: imageColor,
            ),
          ),
          const SizedBox(height: 40),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: constants.kVCUBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}