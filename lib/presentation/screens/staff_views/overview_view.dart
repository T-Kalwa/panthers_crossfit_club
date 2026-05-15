import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/member_account.dart';
import '../../../data/services/hive_service.dart';

class OverviewView extends StatelessWidget {
  final MemberAccount staffMember;
  const OverviewView({super.key, required this.staffMember});

  @override
  Widget build(BuildContext context) {
    // We need to access the repository. Since it's not passed to OverviewView directly, 
    // we'll use a hack or better, I should have passed it.
    // Wait, OverviewView is inside StaffDashboardScreen which has the repository.
    // I'll check how OverviewView is instantiated.
    return StreamBuilder<List<MemberAccount>>(
      stream: FirebaseFirestore.instance.collection('members').snapshots().map(
        (s) => s.docs.map((d) => MemberAccount.fromJson(d.data())).toList()
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        final members = snapshot.data ?? [];
        final total = members.length;
        final active = members.where((m) => !m.isExpired).length;
        final expired = total - active;
        final revenue = members.fold<double>(0, (sum, m) => sum + m.montantPaye);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 2.0,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    children: [
                      _buildStatCard('TOTAL MEMBRES', total.toString(), Icons.group_rounded, Colors.white),
                      _buildStatCard('MEMBRES ACTIFS', active.toString(), Icons.check_circle_rounded, Colors.greenAccent),
                      _buildStatCard('ABONNEMENTS EXPIRÉS', expired.toString(), Icons.error_rounded, Colors.redAccent),
                      _buildStatCard('REVENU TOTAL', '${revenue.toStringAsFixed(0)}\$', Icons.payments_rounded, Colors.orangeAccent),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              _buildRecentActivity(members),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1),
                ),
              ),
              Icon(icon, color: color.withOpacity(0.5), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<MemberAccount> members) {
    // Sort by dateDebut descending (most recent first)
    final recent = List<MemberAccount>.from(members)
      ..sort((a, b) => b.dateDebut.compareTo(a.dateDebut));
    final limit = recent.take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INSCRIPTIONS RÉCENTES',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
        ),
        const SizedBox(height: 24),
        if (recent.isEmpty)
          Text('Aucune activité récente', style: GoogleFonts.outfit(color: Colors.white24))
        else
          ...limit.map((m) => _buildActivityItem(m)).toList(),
      ],
    );
  }

  Widget _buildActivityItem(MemberAccount member) {
    final isSuperAdmin = staffMember.role == 'superAdmin' || staffMember.role == 'admin';
    final staffRef = member.inscritPar ?? 'Système';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add_rounded, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.noms,
                  style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                if (isSuperAdmin) 
                  Text(
                    'PAR : $staffRef',
                    style: GoogleFonts.outfit(color: Colors.orangeAccent.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            member.activite.toUpperCase(),
            style: GoogleFonts.outfit(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
