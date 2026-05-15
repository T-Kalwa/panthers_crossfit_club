import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/models/member_account.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/services/hive_service.dart';

class MembersListView extends StatefulWidget {
  final MemberAccount staffMember;
  final MemberRepository memberRepository;
  final Function(MemberAccount) onEdit;

  const MembersListView({
    super.key,
    required this.staffMember,
    required this.memberRepository,
    required this.onEdit,
  });

  @override
  State<MembersListView> createState() => _MembersListViewState();
}

class _MembersListViewState extends State<MembersListView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(MemberAccount member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: Text('SUPPRESSION', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        content: Text('Voulez-vous vraiment supprimer ${member.noms} ?', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ANNULER', style: GoogleFonts.outfit(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('SUPPRIMER', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.memberRepository.deleteMember(member.matricule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre supprimé')));
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      await widget.memberRepository.refreshMembersCache();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;
        return Column(
          children: [
            _buildSearchHeader(isSmall),
            Expanded(child: _buildList(isSmall)),
          ],
        );
      },
    );
  }

  Widget _buildSearchHeader(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 32, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou matricule...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.02),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _isRefreshing ? null : _handleRefresh,
            icon: _isRefreshing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sync_rounded, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isSmall) {
    return StreamBuilder<List<MemberAccount>>(
      stream: widget.memberRepository.getMembersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final membersData = snapshot.data ?? [];
        
        if (membersData.isEmpty) {
          return Center(
            child: Text(
              'Aucun membre enregistré',
              style: GoogleFonts.outfit(color: Colors.white24),
            ),
          );
        }

        var members = membersData.reversed.toList();
        
        if (_searchQuery.isNotEmpty) {
          members = members.where((m) => 
            m.noms.toLowerCase().contains(_searchQuery) || 
            m.matricule.toLowerCase().contains(_searchQuery)
          ).toList();
        }

        if (members.isEmpty) {
          return Center(child: Text('Aucun résultat', style: GoogleFonts.outfit(color: Colors.white24)));
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 32, vertical: 10),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return _buildMemberTile(member, isSmall);
          },
        );
      },
    );
  }

  Widget _buildMemberTile(MemberAccount member, bool isSmall) {
    final isExpired = member.isExpired;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isSmall ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(isSmall ? 20 : 32),
        border: Border.all(color: isExpired ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildAvatar(member, isSmall),
          SizedBox(width: isSmall ? 16 : 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.noms,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${member.matricule} • ${member.activite.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatus(member, isSmall),
          SizedBox(width: isSmall ? 12 : 16),
          _buildActionButtons(member, isSmall),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MemberAccount member, bool isSmall) {
    final bool isSuperAdmin = widget.staffMember.role == 'superAdmin';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEditButton(member, isSmall),
        if (isSuperAdmin) ...[
          const SizedBox(width: 8),
          _buildDeleteButton(member, isSmall),
        ],
      ],
    );
  }

  Widget _buildDeleteButton(MemberAccount member, bool isSmall) {
    return InkWell(
      onTap: () => _handleDelete(member),
      borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: isSmall ? 18 : 20),
      ),
    );
  }

  Widget _buildAvatar(MemberAccount member, bool isSmall) {
    return Container(
      width: isSmall ? 44 : 56,
      height: isSmall ? 44 : 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isSmall ? 14 : 20),
      ),
      child: Center(
        child: Text(
          member.noms[0],
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildStatus(MemberAccount member, bool isSmall) {
    final isExpired = member.isExpired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${member.montantPaye}\$',
          style: GoogleFonts.outfit(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isExpired ? Colors.red : Colors.green).withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            isExpired ? 'EXPIRÉ' : 'ACTIF',
            style: GoogleFonts.outfit(
              fontSize: isSmall ? 8 : 10,
              fontWeight: FontWeight.w900,
              color: isExpired ? Colors.redAccent : Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(MemberAccount member, bool isSmall) {
    return InkWell(
      onTap: () => widget.onEdit(member),
      borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        ),
        child: Icon(Icons.edit_rounded, color: Colors.black, size: isSmall ? 18 : 20),
      ),
    );
  }
}
