import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/services/demo_auth_service.dart';
import 'demo_scan_screen.dart';
import 'demo_add_member_view.dart';
import 'demo_members_list_view.dart';
import 'demo_login_screen.dart';

class DemoStaffHome extends StatefulWidget {
  final MemberRepository memberRepository;
  final DemoAuthUser currentUser;

  const DemoStaffHome({super.key, required this.memberRepository, required this.currentUser});

  @override
  State<DemoStaffHome> createState() => _DemoStaffHomeState();
}

class _DemoStaffHomeState extends State<DemoStaffHome> {

  Future<void> _logout() async {
    await DemoAuthService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DemoLoginScreen(memberRepository: widget.memberRepository)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A0A),
              Colors.blueGrey.withOpacity(0.05),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PANTHERS',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          'STAFF — ${widget.currentUser.nom.toUpperCase()}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.blueAccent.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.white38),
                      tooltip: 'Déconnexion',
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _buildMainAction(
                  context,
                  title: 'SCANNER UN PASS',
                  subtitle: 'Vérifier l\'accès à la salle',
                  icon: Icons.qr_code_scanner_rounded,
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DemoScanScreen(memberRepository: widget.memberRepository),
                  )),
                ).animate().fadeIn(delay: 100.ms).slideX(),

                const SizedBox(height: 16),

                _buildMainAction(
                  context,
                  title: 'NOUVEAU MEMBRE',
                  subtitle: 'Inscrire et générer le pass',
                  icon: Icons.person_add_alt_1_rounded,
                  color: Colors.greenAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DemoAddMemberView(
                      memberRepository: widget.memberRepository,
                      inscritPar: widget.currentUser.matricule,
                    ),
                  )),
                ).animate().fadeIn(delay: 200.ms).slideX(),

                const SizedBox(height: 16),

                _buildMainAction(
                  context,
                  title: 'LISTE DES MEMBRES',
                  subtitle: 'Gérer et partager les accès',
                  icon: Icons.people_alt_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DemoMembersListView(memberRepository: widget.memberRepository),
                  )),
                ).animate().fadeIn(delay: 300.ms).slideX(),

                const SizedBox(height: 16),

                _buildMainAction(
                  context,
                  title: 'INFOS CLUB',
                  subtitle: 'Horaires, tarifs et contacts',
                  icon: Icons.info_outline_rounded,
                  color: Colors.purpleAccent,
                  onTap: () => _showClubInfo(context),
                ).animate().fadeIn(delay: 400.ms).slideX(),

                const Spacer(),
                Center(
                  child: Text(
                    '© 2026 PANTHERS CROSSFIT CLUB',
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.white12, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClubInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 32),
            Text('HORAIRES D\'OUVERTURE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.purpleAccent, letterSpacing: 2)),
            const SizedBox(height: 20),
            _buildInfoRow('Lundi - Vendredi', '6h00 - 22h00'),
            _buildInfoRow('Samedi', '7h00 - 21h30'),
            _buildInfoRow('Dimanche', '7h00 - 12h00'),
            _buildInfoRow('Jours fériés', '7h00 - 12h00'),
            const SizedBox(height: 40),
            Text('CONTACTS & PAIEMENTS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.purpleAccent, letterSpacing: 2)),
            const SizedBox(height: 20),
            _buildInfoRow('Airtel Money', '+243 962 909 624'),
            _buildInfoRow('Orange Money', '+243 859 439 292'),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), foregroundColor: Colors.white, elevation: 0),
                onPressed: () => Navigator.pop(context),
                child: const Text('FERMER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMainAction(BuildContext context, {
    required String title, required String subtitle,
    required IconData icon, required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }
}
