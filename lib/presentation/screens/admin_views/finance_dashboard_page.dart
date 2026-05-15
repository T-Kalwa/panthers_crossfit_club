import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/models/member_account.dart';
import '../../../domain/logic/panthers_pricing.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/repositories/member_repository.dart';

class FinanceDashboardPage extends StatefulWidget {
  final MemberRepository memberRepository;

  const FinanceDashboardPage({
    super.key,
    required this.memberRepository,
  });

  @override
  State<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends State<FinanceDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          'FINANCES & TARIFS',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1),
          unselectedLabelColor: Colors.white24,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'REVENUS'),
            Tab(text: 'TARIFICATIONS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRevenueTab(),
          _buildTariffsTab(),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<MemberAccount>(HiveService.accountsBoxName).listenable(),
      builder: (context, Box<MemberAccount> box, _) {
        final revenue = box.values.fold<double>(0, (sum, m) => sum + m.montantPaye);
        final activeRevenue = box.values
            .where((m) => !m.isExpired)
            .fold<double>(0, (sum, m) => sum + m.montantPaye);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBigStatCard('REVENU TOTAL BRUT', '${revenue.toStringAsFixed(0)}\$', Icons.payments_rounded, Colors.orangeAccent),
              const SizedBox(height: 16),
              _buildBigStatCard('REVENU ACTIF', '${activeRevenue.toStringAsFixed(0)}\$', Icons.check_circle_rounded, Colors.greenAccent),
              const SizedBox(height: 32),
              Text(
                'RÉPARTITION PAR ACTIVITÉ',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              _buildActivityRevenueList(box),
              const SizedBox(height: 32),
              Text(
                'RÉPARTITION PAR PAIEMENT',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              _buildPaymentRevenueList(box),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentRevenueList(Box<MemberAccount> box) {
    final Map<String, double> totals = {};
    for (var m in box.values) {
      if (m.montantPaye <= 0) continue;
      final method = m.methodePaiement ?? 'Non spécifié';
      totals[method] = (totals[method] ?? 0) + m.montantPaye;
    }

    final sortedItems = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedItems.map((e) => _buildPaymentItem(e.key, e.value)).toList(),
    );
  }

  Widget _buildPaymentItem(String method, double amount) {
    IconData icon = Icons.payments_rounded;
    Color color = Colors.white54;

    if (method.contains('Airtel')) {
      icon = Icons.smartphone_rounded;
      color = Colors.redAccent;
    } else if (method.contains('Orange')) {
      icon = Icons.smartphone_rounded;
      color = Colors.orange;
    } else if (method.contains('Espèces')) {
      icon = Icons.money_rounded;
      color = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(method.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          Text(
            '${amount.toStringAsFixed(0)}\$',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRevenueList(Box<MemberAccount> box) {
    final Map<String, double> totals = {};
    for (var m in box.values) {
      final act = m.activite.toUpperCase();
      totals[act] = (totals[act] ?? 0) + m.montantPaye;
    }

    final sortedItems = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedItems.map((e) => _buildActivityItem(e.key, e.value)).toList(),
    );
  }

  Widget _buildActivityItem(String activity, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Text(activity, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          Text(
            '${amount.toStringAsFixed(0)}\$',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPricingSection('CROSSFIT', [
            '1 séance', '10 jours', '1 mois', '3 mois', '6 mois', 'annuel'
          ]),
          const SizedBox(height: 32),
          _buildPricingSection('BOXE', [
            '1 séance', '1 mois', '3 mois', '6 mois'
          ]),
          const SizedBox(height: 32),
          _buildPricingSection('ZUMBA', [
            '1 séance', '1 mois'
          ]),
        ],
      ),
    );
  }

  Widget _buildPricingSection(String activity, List<String> durations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
        ),
        const SizedBox(height: 16),
        ...durations.expand((dur) => [
          _buildPricingRow(activity, dur, false),
          if (activity == 'CROSSFIT' && (dur == '10 jours' || dur == '1 mois' || dur == '3 mois' || dur == '6 mois' || dur == 'annuel'))
             _buildPricingRow(activity, dur, true),
        ]).toList(),
      ],
    );
  }

  Widget _buildPricingRow(String activity, String duration, bool avecCoach) {
    final details = PanthersPricing.getPlanDetails(activity, duration, avecCoach);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duration.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                if (avecCoach)
                  Text(
                    'AVEC COACH',
                    style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.orangeAccent),
                  ),
              ],
            ),
          ),
          Text(
            '${details.price.toStringAsFixed(0)}\$',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
