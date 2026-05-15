import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/services/hive_service.dart';
import 'member_dashboard_screen.dart';
import 'admin_hub_page.dart';

class SplashScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const SplashScreen({super.key, required this.memberRepository});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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

    // Rotate phrases
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentPhraseIndex =
              (_currentPhraseIndex + 1) % _motivationalPhrases.length;
        });
      }
    });

    // Auto-navigation (Reduced to 2s for better UX)
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        final hiveService = HiveService();
        final hasSeenOnboarding = hiveService.hasSeenOnboarding;
        final hasAcceptedCGU = hiveService.hasAcceptedCGU;
        final isLoggedIn = hiveService.isLoggedIn();

        Widget nextScreen;
        
        if (!hasSeenOnboarding || !hasAcceptedCGU) {
          nextScreen = const OnboardingScreen();
        } else if (isLoggedIn) {
          final account = hiveService.getMemberAccount();
          // Vérification CRITIQUE : Seul un compte ACTIF peut persister et passer au Dashboard
          if (account != null && account.isActive) {
            // Lancement d'une mise à jour silencieuse en arrière-plan
            widget.memberRepository.loginByMatriculeAndPhone(account.matricule, account.telephone);
            
            // Détermination de l'écran suivant par rôle
            if (account.role == 'staff' || account.role == 'superAdmin' || account.role == 'admin') {
              nextScreen = AdminHubPage(
                staffMember: account,
                memberRepository: widget.memberRepository,
              );
            } else {
              nextScreen = MemberDashboardScreen(member: account);
            }
          } else {
            // Si le compte enregistré est révoqué, on force la suppression de la session persistante
            hiveService.clear();
            nextScreen = LoginScreen(memberRepository: widget.memberRepository);
          }
        } else {
          nextScreen = LoginScreen(memberRepository: widget.memberRepository);
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                   return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Premium Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/int_3.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark Overlay for Contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1), // Much lighter top
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.9), // Darker bottom for contrast with text
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Animated Logo
                Center(
                  child:
                      Image.asset('assets/images/logo_splash.png', height: 180)
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.05, 1.05),
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          )
                          .shimmer(
                            duration: 2500.ms,
                            color: Colors.white.withOpacity(0.2),
                          ),
                ),

                const SizedBox(height: 40),

                // Animated Title
                Text(
                      'PANTHERS',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 15,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: 0.2, end: 0)
                    .custom(
                      duration: 800.ms,
                      builder: (context, value, child) {
                        return Text(
                          'PANTHERS',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 15 + (1 - value) * 10,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),

                Text(
                  'CROSSFIT CLUB',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                    color: Colors.white54,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 800.ms),

                const Spacer(),

                // Motivational Text with AnimatedSwitcher
                SizedBox(
                  height: 60,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      _motivationalPhrases[_currentPhraseIndex],
                      key: ValueKey<int>(_currentPhraseIndex),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Animated Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Column(
                    children: [
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child:
                              Container(
                                width: 0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ).animate().custom(
                                duration: 3000.ms,
                                builder: (context, value, child) =>
                                    FractionallySizedBox(
                                      widthFactor: value,
                                      child: child,
                                    ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CHARGEMENT DU DASHBOARD...',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
