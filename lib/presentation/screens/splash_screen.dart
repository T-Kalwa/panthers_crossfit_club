import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/services/hive_service.dart';

class SplashScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const SplashScreen({super.key, required this.memberRepository});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  final List<String> _motivationalPhrases = [
    "Préparez votre esprit...",
    "Repoussez vos limites.",
    "La force est en vous.",
    "L'excellence est une habitude.",
    "Entrez dans l'arène.",
  ];
  int _currentPhraseIndex = 0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textAnimation = CurvedAnimation(parent: _textController, curve: Curves.easeInOut);

    _fadeController.forward();
    _textController.forward();

    // Rotate phrases
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentPhraseIndex = (_currentPhraseIndex + 1) % _motivationalPhrases.length;
          _textController.reset();
          _textController.forward();
        });
      }
    });

    // Auto-navigation
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        final hiveService = HiveService();
        final hasSeenOnboarding = hiveService.hasSeenOnboarding;
        
        final Widget nextScreen = hasSeenOnboarding 
          ? LoginScreen(memberRepository: widget.memberRepository)
          : const OnboardingScreen();

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textController.dispose();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/images/logo_splash.png',
                height: 120,
              ),
              const SizedBox(height: 32),
              // App Title
              Text(
                'PANTHERS',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 100),
              
              // Motivational Text
              SizedBox(
                height: 40,
                child: FadeTransition(
                  opacity: _textAnimation,
                  child: Text(
                    _motivationalPhrases[_currentPhraseIndex].toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),
              // Subtle Loading indicator
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
