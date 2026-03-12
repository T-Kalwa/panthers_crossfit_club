import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/repositories/member_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'member_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const LoginScreen({super.key, required this.memberRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _matriculeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final matricule = _matriculeController.text.trim().toUpperCase();
    if (matricule.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final member = await widget.memberRepository.loginByQrData(matricule);
      if (member != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MemberDashboardScreen(member: member),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matricule invalide'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Dark Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/int_3.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.black);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branding Logo / Icon
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white10, width: 1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'PANTHERS CLUB',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Login Box
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _matriculeController,
                                style: GoogleFonts.outfit(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  hintText: "Matricule (ex: P009)",
                                  hintStyle: GoogleFonts.outfit(
                                    color: Colors.white24,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: Colors.white24,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.black,
                                        )
                                      : Text(
                                          "SE CONNECTER",
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
