import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/repositories/member_repository.dart';
import '../../domain/models/member.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const LoginScreen({super.key, required this.memberRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final member = await widget.memberRepository.login(
        _usernameController.text.trim(),
        _phoneController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (member != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${member.fullName}'),
            backgroundColor: const Color(0xFF455A64),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Athlete not found.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
            child: Image.asset(
              'assets/images/athlete_hero.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),
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
                    const SizedBox(height: 60),
                    // Header Section
                    Text(
                      'Move With\nMeaning',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Push limits. Learn. Adapt.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Athlete Username',
                                    hintText: 'e.g. panther_01',
                                  ),
                                  validator: (value) => (value == null || value.isEmpty) ? '' : null,
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: 'e.g. 0600000000',
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) => (value == null || value.isEmpty) ? '' : null,
                                ),
                                const SizedBox(height: 48),
                                _isLoading
                                    ? const CircularProgressIndicator(strokeWidth: 2)
                                    : ElevatedButton(
                                        onPressed: _handleLogin,
                                        child: const Text('ENTER THE CLUB'),
                                      ),
                              ],
                            ),
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
          
          // Small Logo Fix: Removed opacity color filter
          Positioned(
            top: 24,
            left: 24,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/logo_splash.png',
                height: 32,
                errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
