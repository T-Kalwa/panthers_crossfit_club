import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'legal_screen.dart';

import '../widgets/payment_bottom_sheet.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  // Opening Hours Logic
  bool get isOpen {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final currentTime = hour + (minute / 60.0);
    final weekday = now.weekday;

    if (weekday >= 1 && weekday <= 5) { // Mon-Fri
      return currentTime >= 6.0 && currentTime < 22.0;
    } else if (weekday == 6) { // Sat
      return currentTime >= 7.0 && currentTime < 21.5;
    } else if (weekday == 7) { // Sun
      return currentTime >= 7.0 && currentTime < 12.0;
    }
    return false;
  }

  String get nextStatusMessage {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final currentTime = hour + (minute / 60.0);
    final weekday = now.weekday;

    if (isOpen) {
      if (weekday >= 1 && weekday <= 5) return "Fermeture à 22:00";
      if (weekday == 6) return "Fermeture à 21:30";
      return "Fermeture à 12:00";
    } else {
      if (weekday >= 1 && weekday <= 4) return "Réouverture demain à 06:00";
      if (weekday == 5) return "Réouverture demain à 07:00";
      if (weekday == 6) return "Réouverture demain à 07:00";
      if (weekday == 7 && currentTime < 7) return "Réouverture à 07:00";
      return "Réouverture lundi à 06:00";
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PaymentBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background Image with Blur
          Positioned.fill(
            child: Image.asset(
              'assets/images/int_3.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.85)),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'NOTRE CLUB',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 18,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatusBadge().animate().fadeIn().scale(curve: Curves.easeOutBack),
                    const SizedBox(height: 40),
                    ...[
                      _buildSectionTitle('L\'ESPACE PANTHERS'),
                      _buildScheduleTable(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('TARIFS SESSIONS'),
                      _buildPricingSection(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('RESTEZ CONNECTÉ'),
                      _buildContactSection(),
                      const SizedBox(height: 40),
                    ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = isOpen ? const Color(0xFF39FF14) : Colors.redAccent;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            isOpen ? 'CLUB OUVERT' : 'CLUB FERMÉ',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          nextStatusMessage.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable() {
    final schedule = [
      {'days': 'Lundi - Vendredi', 'hours': '06:00 - 22:00'},
      {'days': 'Samedi', 'hours': '07:00 - 21:30'},
      {'days': 'Dimanche', 'hours': '07:00 - 12:00'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: schedule.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['days']!,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
                ),
                Text(
                  item['hours']!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Column(
      children: [
        _buildPricingCard(
          'CROSSFIT',
          Icons.bolt_rounded,
          [
            '1 mois: 130\$ / 160\$',
            '10 jours: 50\$ / 60\$',
            'Annuel: 1400\$ / 1760\$',
          ],
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          'BOXE',
          Icons.sports_mma_rounded,
          [
            '1 mois: 90\$',
            '3 mois: 250\$',
            '6 mois: 500\$',
          ],
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          'ZUMBA / AÉRO',
          Icons.favorite_rounded,
          [
            '1 mois: 100\$',
            '1 séance: 15\$',
          ],
        ),
      ],
    );
  }

  Widget _buildPricingCard(String title, IconData icon, List<String> prices) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ...prices.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        p,
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        _buildContactButton(
          'APPELER LE CLUB',
          Icons.phone_rounded,
          () => _launchUrl('tel:+243962909624'),
          const Color(0xFFFF8C00),
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          'WHATSAPP US',
          Icons.chat_bubble_rounded,
          () => _launchUrl('https://wa.me/243962909624?text=Hello Panthers Club !'),
          const Color(0xFF25D366),
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          'PAIEMENT MOBILE',
          Icons.account_balance_wallet_rounded,
          () => _showPaymentModal(),
          const Color(0xFFFFB347),
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          'CONDITIONS D\'UTILISATION',
          Icons.gavel_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LegalScreen(),
              fullscreenDialog: true,
            ),
          ),
          Colors.white54,
        ),
      ],
    );
  }

  Widget _buildContactButton(String title, IconData icon, VoidCallback onTap, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.04),
          foregroundColor: Colors.white,
          side: BorderSide(color: color.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

