import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/repositories/member_repository.dart';
import '../../domain/models/member.dart';
import 'package:google_fonts/google_fonts.dart';
import 'member_dashboard_screen.dart';
import 'qr_scanner_screen.dart';

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

  Future<void> _handleQrScan() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null) {
      _matriculeController.text = result;
      _handleLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Dark Sombre Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4), // Reduced from 0.6
                    Colors.black.withOpacity(0.2), // Reduced from 0.3
                    const Color(0xFF0A0A0A).withOpacity(0.8),
                    const Color(0xFF0A0A0A),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Modern Branding Logo
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white10, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'PANTHERS CLUB',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 40,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PUSH LIMITS • GAIN RESULTS',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Minimalist Transparency Box
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Matricule Input
                              TextField(
                                controller: _matriculeController,
                                style: GoogleFonts.outfit(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  hintText: "Matricule (ex: P009)",
                                  hintStyle: GoogleFonts.outfit(color: Colors.white24),
                                  prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white24),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF39FF14),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.black)
                                      : Text(
                                          "SE CONNECTER",
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // QR Scan Option
                              TextButton.icon(
                                onPressed: _isLoading ? null : _handleQrScan,
                                icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF39FF14)),
                                label: Text(
                                  "SCAN QR PASS",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF39FF14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
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
