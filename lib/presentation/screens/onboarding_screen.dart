import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../data/services/hive_service.dart';
import 'login_screen.dart';
import '../../data/repositories/member_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isContractAccepted = false;
  final HiveService _hiveService = HiveService();

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Track real\nprogress",
      description: "See your journey unfold with powerful insights and analytics.",
      image: "assets/images/Int_1.jpg", 
      color: Colors.white,
    ),
    OnboardingData(
      title: "Welcome To Our\nEasy Workout",
      description: "Designing A Fitness And Gym Application Involves Creating A Comprehensive Digital Platform.",
      image: "assets/images/Int_2.jpg",
      color: Colors.white,
    ),
    OnboardingData(
      title: "Join the\nPanthers Club",
      description: "Accept our terms to start your premium fitness journey with us.",
      image: "assets/images/int_3.jpg",
      color: Colors.white,
      isFinal: true,
    ),
  ];

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else if (_isContractAccepted) {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await _hiveService.setHasSeenOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen(memberRepository: MemberRepository())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _pages[index].image,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                          Colors.black,
                        ],
                        stops: const [0, 0.4, 0.9],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Content Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Indicator
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 4,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index 
                              ? Colors.white
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Text Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      key: ValueKey(_currentIndex),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pages[_currentIndex].title.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[_currentIndex].description,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.white60,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Contract Checkbox (Only on last page)
                  if (_pages[_currentIndex].isFinal) ...[
                    GestureDetector(
                      onTap: () => setState(() => _isContractAccepted = !_isContractAccepted),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isContractAccepted ? Colors.white : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                                color: _isContractAccepted ? Colors.white : Colors.transparent,
                              ),
                              child: _isContractAccepted 
                                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "I agree to the terms of service and membership rules.",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (_pages[_currentIndex].isFinal && !_isContractAccepted) 
                          ? null 
                          : _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _pages[_currentIndex].isFinal ? "GET STARTED" : "NEXT",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Skip Button
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                "Skip",
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final Color color;
  final bool isFinal;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    this.isFinal = false,
  });
}
