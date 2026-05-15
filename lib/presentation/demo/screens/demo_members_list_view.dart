import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/member_account.dart';
import '../../../data/repositories/member_repository.dart';
import '../widgets/member_pass_card.dart';
import '../utils/demo_utils.dart';
import 'demo_renew_member_view.dart';

class DemoMembersListView extends StatelessWidget {
  final MemberRepository memberRepository;

  const DemoMembersListView({super.key, required this.memberRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MEMBRES INSCRITS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('members').where('role', isEqualTo: 'membre').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Aucun membre inscrit.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final member = MemberAccount.fromJson(docs[index].data() as Map<String, dynamic>);
              return _buildMemberTile(context, member);
            },
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, MemberAccount member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        title: Text(member.noms, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${member.matricule} • ${member.activite}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.greenAccent),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DemoRenewMemberView(memberRepository: memberRepository, member: member),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded, color: Colors.blueAccent),
              onPressed: () => _showPassPreview(context, member),
            ),
          ],
        ),
      ),
    );
  }

  void _showPassPreview(BuildContext context, MemberAccount member) {
    final GlobalKey passKey = GlobalKey();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: passKey,
              child: MemberPassCard(member: member),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionIcon(
                  icon: Icons.share_rounded,
                  color: Colors.blueAccent,
                  onTap: () => DemoUtils.shareWidgetAsImage(passKey, 'pass_${member.matricule}'),
                ),
                const SizedBox(width: 32),
                _buildActionIcon(
                  icon: Icons.download_rounded,
                  color: Colors.greenAccent,
                  onTap: () => DemoUtils.saveToGallery(passKey, 'pass_${member.matricule}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
