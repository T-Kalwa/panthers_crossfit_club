import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

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
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.8)),
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
                  'ABOUT US',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 18,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatusBadge(),
                    const SizedBox(height: 30),
                    _buildSectionTitle('HORAIRES'),
                    _buildScheduleTable(),
                    const SizedBox(height: 30),
                    _buildSectionTitle('NOS TARIFS'),
                    _buildPricingSection(),
                    const SizedBox(height: 30),
                    _buildSectionTitle('NOUS CONTACTER'),
                    _buildContactSection(),
                    const SizedBox(height: 40),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOpen ? const Color(0xFF39FF14).withOpacity(0.3) : Colors.red.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              if (isOpen)
                BoxShadow(
                  color: const Color(0xFF39FF14).withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Text(
            isOpen ? 'OUVERT' : 'FERMÉ',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isOpen ? const Color(0xFF39FF14) : Colors.redAccent,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          nextStatusMessage.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
            letterSpacing: 1.5,
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
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 2,
            color: Colors.white24,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: schedule.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['days']!,
                  style: GoogleFonts.outfit(color: Colors.white70),
                ),
                Text(
                  item['hours']!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
          Icons.fitness_center,
          [
            '1 mois: 130\$ / 160\$',
            '10 jours: 50\$ / 60\$',
            'Annuel: 1400\$ / 1760\$',
          ],
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          'BOXE',
          Icons.sports_mma,
          [
            '1 mois: 90\$',
            '3 mois: 250\$',
            '6 mois: 500\$',
          ],
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          'ZUMBA / AÉRO',
          Icons.directions_run,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...prices.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    p,
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
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
          Icons.phone,
          'tel:+243962909624',
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          'WHATSAPP US',
          Icons.chat,
          'https://wa.me/243962909624?text=Hello Panthers Club !',
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          'PAIEMENT MOBILE',
          Icons.account_balance_wallet,
          'tel:+243859439292',
        ),
      ],
    );
  }

  Widget _buildContactButton(String title, IconData icon, String url) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => _launchUrl(url),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.05),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
