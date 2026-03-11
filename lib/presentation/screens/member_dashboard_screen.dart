import 'package:flutter/material.dart';
import 'dart:ui';
import '../../domain/models/member.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MemberDashboardScreen extends StatelessWidget {
  final Member member;

  const MemberDashboardScreen({super.key, required this.member});

  static const Color neonGreen = Color(0xFF39FF14);
  static const Color background = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonGreen.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTopNav(context),
                  const SizedBox(height: 40),
                  _buildProgressCircle(),
                  const SizedBox(height: 40),
                  _buildMemberInfo(context),
                  const SizedBox(height: 32),
                  _buildQuickAction(context),
                  const SizedBox(height: 32),
                  _buildDetailCards(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PANTHERS',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            Text(
              'CROSSFIT CLUB',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
                color: neonGreen,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.1),
          backgroundImage: member.profileImageUrl != null ? NetworkImage(member.profileImageUrl!) : null,
          child: member.profileImageUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
        ),
      ],
    );
  }

  Widget _buildProgressCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: member.expiryProgress,
            strokeWidth: 12,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: neonGreen,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          children: [
            Text(
              '${member.daysRemaining}',
              style: GoogleFonts.outfit(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                height: 1,
                color: Colors.white,
              ),
            ),
            Text(
              'JOURS RESTANTS',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberInfo(BuildContext context) {
    return Column(
      children: [
        Text(
          member.nomComplet.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: member.isExpired ? Colors.red.withOpacity(0.1) : neonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: member.isExpired ? Colors.red.withOpacity(0.3) : neonGreen.withOpacity(0.3),
            ),
          ),
          child: Text(
            member.isExpired ? 'EXPIRÉ' : 'ACTIVE',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: member.isExpired ? Colors.redAccent : neonGreen,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context) {
    return InkWell(
      onTap: member.isExpired ? null : () => _showQrModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        decoration: BoxDecoration(
          color: member.isExpired ? Colors.white.withOpacity(0.05) : neonGreen,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            if (!member.isExpired)
              BoxShadow(
                color: neonGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              member.isExpired ? Icons.lock_outline : Icons.qr_code_2,
              color: member.isExpired ? Colors.white24 : Colors.black,
            ),
            const SizedBox(width: 12),
            Text(
              member.isExpired ? 'ACCÈS BLOQUÉ' : 'SHOW QR CODE',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: member.isExpired ? Colors.white24 : Colors.black,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildGlassCard(
              'Activité',
              member.activite,
              Icons.fitness_center_outlined,
            ),
            const SizedBox(width: 16),
            _buildGlassCard(
              'Coaching',
              member.avecCoach ? 'Inclus' : 'Standard',
              Icons.person_pin_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGlassCardFull(
          'Abonnement jusqu\'au',
          _formatDate(member.dateFin),
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Widget _buildGlassCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: neonGreen, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCardFull(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: neonGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: neonGreen, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 500,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'YOUR ACCESS PASS',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: QrImageView(
                  data: member.matricule,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                member.matricule,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CLOSE',
                  style: GoogleFonts.outfit(color: neonGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
