import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/repositories/member_repository.dart';
import 'demo_scan_screen.dart';
import 'demo_add_member_view.dart';
import 'demo_members_list_view.dart';

class DemoHomeScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const DemoHomeScreen({super.key, required this.memberRepository});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  bool _isClearing = false;

  Future<void> _confirmAndClearDb() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'VIDER LA BASE DE DONNÉES',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent),
        ),
        content: Text(
          'Tous les membres inscrits seront supprimés de Hive et de Firestore.\n\nCette action est irréversible.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ANNULER', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('CONFIRMER', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isClearing = true);
    try {
      await widget.memberRepository.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Base de données vidée avec succès.', style: GoogleFonts.outfit()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberRepository = widget.memberRepository;
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
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PANTHERS',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          'VERSION DÉMO (STAFF)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Scanner Button
                _buildMainAction(
                  context,
                  title: 'SCANNER UN PASS',
                  subtitle: 'Vérifier l\'accès à la salle',
                  icon: Icons.qr_code_scanner_rounded,
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DemoScanScreen(memberRepository: memberRepository),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(),

                const SizedBox(height: 20),

                // Register Button
                _buildMainAction(
                  context,
                  title: 'NOUVEAU MEMBRE',
                  subtitle: 'Inscrire et générer le pass',
                  icon: Icons.person_add_alt_1_rounded,
                  color: Colors.greenAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DemoAddMemberView(memberRepository: memberRepository),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(),

                const SizedBox(height: 20),

                // List Button
                _buildMainAction(
                  context,
                  title: 'LISTE DES MEMBRES',
                  subtitle: 'Gérer et partager les accès',
                  icon: Icons.people_alt_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DemoMembersListView(memberRepository: memberRepository),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideX(),
                
                const SizedBox(height: 20),

                // Club Info Button
                _buildMainAction(
                  context,
                  title: 'INFOS CLUB',
                  subtitle: 'Horaires, tarifs et contacts',
                  icon: Icons.info_outline_rounded,
                  color: Colors.purpleAccent,
                  onTap: () => _showClubInfo(context),
                ).animate().fadeIn(delay: 800.ms).slideX(),
                
                const Spacer(),
                // Reset DB Button
                GestureDetector(
                  onTap: _isClearing ? null : _confirmAndClearDb,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
                    ),
                    child: Center(
                      child: _isClearing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2))
                          : Text(
                              '⚠  VIDER LA BASE DE DONNÉES',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.redAccent.withOpacity(0.7),
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '© 2026 PANTHERS CROSSFIT CLUB',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.white12,
                      letterSpacing: 2,
                    ),
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'HORAIRES D\'OUVERTURE',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.purpleAccent,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Lundi - Vendredi', '6h00 - 22h00'),
            _buildInfoRow('Samedi', '7h00 - 21h30'),
            _buildInfoRow('Dimanche', '7h00 - 12h00'),
            _buildInfoRow('Jours fériers', '7h00 - 12h00'),
            
            const SizedBox(height: 40),
            Text(
              'CONTACTS & PAIEMENTS',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.purpleAccent,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Airtel Money', '+243 962 909 624'),
            _buildInfoRow('Orange Money', '+243 859 439 292'),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
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

  Widget _buildMainAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 16),
          ],
        ),
      ),
    );
  }
}
