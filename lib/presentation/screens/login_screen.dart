import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/member_account.dart';
import '../../data/repositories/member_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'member_dashboard_screen.dart';
import 'admin_hub_page.dart';

class LoginScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const LoginScreen({super.key, required this.memberRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final matricule = _matriculeController.text.trim().toUpperCase();
    final phone = _phoneController.text.trim();
    
    if (matricule.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final member = await widget.memberRepository.loginByMatriculeAndPhone(matricule, phone);
      if (member != null) {
        if (!mounted) return;
        
        // Routing logic based on ROLE (not activite)
        if (member.role == 'staff' || member.role == 'superAdmin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AdminHubPage(
                staffMember: member,
                memberRepository: widget.memberRepository,
              ),
            ),
          );
        } else if (!member.isActive) {
          if (!mounted) return;
          _showRevokedDialog(context);
        } else {
          // It's a member
          final fullAccount = await widget.memberRepository.getMemberAccountByMatricule(member.matricule);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MemberDashboardScreen(member: fullAccount ?? member),
            ),
          );
        }
      } else {
        if (!mounted) return;
        final hasCache = await widget.memberRepository.getMemberAccountByMatricule(matricule) != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasCache 
              ? 'Matricule invalide' 
              : 'Impossible de se connecter. Vérifiez votre connexion internet pour votre première connexion.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur réseau. Reconnectez-vous pour synchroniser votre profil.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRevokedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.block_flipped, color: Colors.redAccent, size: 60),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                  const SizedBox(height: 24),
                  Text(
                    'ACCÈS RÉVOQUÉ',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Votre accès a été suspendu ou révoqué par l\'administration du Panthers Club.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Fermer le message d'erreur
                        _showContactAdminSolutions(context); // Ouvrir les solutions
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'CONTACTER L\'ADMINISTRATION',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  void _showContactAdminSolutions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 50),
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Icon(Icons.support_agent_rounded, size: 64, color: Colors.white.withOpacity(0.8)),
            const SizedBox(height: 16),
            Text(
              'RÉTABLIR VOTRE ACCÈS',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Comment souhaitez-vous procéder au règlement ou à la levée de suspension de votre compte ?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // OPTION 1 : RÉCEPTION
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white),
                ),
                title: Text(
                  'ALLER À LA RÉCEPTION',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  'Réglez directement en espèces ou par carte avec un membre du Staff.',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ).animate().slideY(begin: 0.2, end: 0, delay: 200.ms),
            
            const SizedBox(height: 16),

            // OPTION 2 : MOBILE MONEY
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white54,
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_android_rounded, color: Colors.orangeAccent),
                  ),
                  title: Text(
                    'PAIEMENT MOBILE MONEY',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Réglez via Airtel, Orange, M-Pesa ou Afrimoney',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                  ),
                  children: [
                    _buildPaymentMethodRow('Airtel Money', '0990000000', Colors.red),
                    _buildPaymentMethodRow('Orange Money', '0890000000', Colors.orange),
                    _buildPaymentMethodRow('M-Pesa', '0810000000', Colors.green),
                    _buildPaymentMethodRow('Afrimoney', '0850000000', Colors.purple),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.2, end: 0, delay: 300.ms),
            
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ANNULER',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(String name, String number, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(name, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(number, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Future<void> _showDiagnosticDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: Text(
          'DIAGNOSTIC SYSTÈME',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DiagnosticItem(
              title: 'Connexion Firestore',
              future: FirebaseFirestore.instance.collection('test_connection').limit(1).get(),
            ),
            const SizedBox(height: 16),
            _DiagnosticItem(
              title: 'Persistance Hive',
              status: widget.memberRepository.hasSavedMembers() ? 'OK' : 'VIDE',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminHubPage(
                    staffMember: MemberAccount(
                      matricule: 'ADMIN',
                      noms: 'Super Admin',
                      role: 'superAdmin',
                      telephone: '000',
                      activite: 'ADMINISTRATION',
                      dureeForfait: 'ANNUEL',
                      montantPaye: 0,
                      dateDebut: DateTime.now(),
                      dateFin: DateTime.now().add(const Duration(days: 365)),
                      avecCoach: false,
                    ),
                    memberRepository: widget.memberRepository,
                  ),
                ),
              );
            },
            child: Text('OUVRIR ADMIN HUB', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('FERMER', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
        ],
      ),
    );
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
                      Colors.black.withValues(alpha: 0.1), // Lightened
                      Colors.black.withValues(alpha: 0.3), // Lightened
                      Colors.black.withValues(alpha: 0.7), // Keeping bottom readable
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
                    GestureDetector(
                      onLongPress: () => _showDiagnosticDialog(),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.05),
                              blurRadius: 40,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 32),
                    Text(
                      'PANTHERS CLUB',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 60),

                    // Login Box
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                                TextField(
                                  controller: _matriculeController,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: "Matricule (ex: P001)",
                                    prefixIcon: const Icon(
                                      Icons.badge_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _phoneController,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    hintText: "Numéro de téléphone",
                                    prefixIcon: const Icon(
                                      Icons.phone_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
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
                                              letterSpacing: 2,
                                              color: Colors.black,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
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

class _DiagnosticItem extends StatelessWidget {
  final String title;
  final Future? future;
  final String? status;

  const _DiagnosticItem({required this.title, this.future, this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(color: Colors.white70)),
        if (status != null)
          Text(status!, style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold))
        else
          FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
              }
              if (snapshot.hasError) {
                return const Icon(Icons.error, color: Colors.redAccent, size: 16);
              }
              return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16);
            },
          ),
      ],
    );
  }
}
