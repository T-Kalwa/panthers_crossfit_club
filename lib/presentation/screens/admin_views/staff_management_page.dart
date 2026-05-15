import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/member_account.dart';
import '../staff_views/add_member_view.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/repositories/member_repository.dart';

class StaffManagementPage extends StatefulWidget {
  final MemberRepository memberRepository;

  const StaffManagementPage({
    super.key,
    required this.memberRepository,
  });

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  bool _isSyncing = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _syncFromFirestore(); // sync en arrière-plan, ne bloque pas l'UI
  }

  // ────────────────────────────────────────────────────
  // HIVE-FIRST : filtre les staff/superAdmin du cache local
  // ────────────────────────────────────────────────────
  List<MemberAccount> _getStaffFromHive(Box<MemberAccount> box) {
    final members = box.values
        .where((m) => m.role == 'staff' || m.role == 'superAdmin')
        .toList();
    members.sort((a, b) {
      if (a.role == b.role) return a.noms.compareTo(b.noms);
      return a.role == 'superAdmin' ? -1 : 1;
    });
    return members;
  }

  // ────────────────────────────────────────────────────
  // FIRESTORE : sync en arrière-plan
  // ────────────────────────────────────────────────────
  Future<void> _syncFromFirestore() async {
    if (_isSyncing) return;
    if (mounted) setState(() => _isSyncing = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('role', whereIn: ['staff', 'superAdmin'])
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 6));

      final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
      for (var doc in snapshot.docs) {
        final account = MemberAccount.fromJson(doc.data());
        await box.put(account.matricule.toUpperCase(), account);
      }
      if (mounted) setState(() => _isOffline = false);
    } catch (_) {
      if (mounted) setState(() => _isOffline = true);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // ────────────────────────────────────────────────────
  // CRÉER un membre staff (Hive puis Firestore en bg)
  // ────────────────────────────────────────────────────
  Future<void> _createStaffMember({
    required String matricule,
    required String noms,
    required String telephone,
    required String role,
  }) async {
    final now = DateTime.now();
    final account = MemberAccount(
      matricule: matricule,
      noms: noms,
      telephone: telephone,
      role: role,
      activite: 'Staff',
      dureeForfait: 'annuel',
      avecCoach: false,
      montantPaye: 0,
      dateDebut: now,
      dateFin: now.add(const Duration(days: 3650)), // 10 ans
      isActive: true,
    );

    // saveMemberAccount : Hive d'abord, Firestore en arrière-plan
    await widget.memberRepository.saveMemberAccount(account);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          content: Text(
            '$noms ajouté(e) • sync en cours...',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  // ────────────────────────────────────────────────────
  // RÉVOQUER accès (Hive puis Firestore en bg)
  // ────────────────────────────────────────────────────
  Future<void> _confirmRevokeAccess(MemberAccount member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'RÉVOQUER L\'ACCÈS',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        content: Text(
          'Voulez-vous retirer l\'accès staff à ${member.noms} ?\nLe compte sera supprimé.',
          style: GoogleFonts.outfit(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ANNULER', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('RÉVOQUER', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // deleteMember : Hive d'abord, Firestore en bg
      await widget.memberRepository.deleteMember(member.matricule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Accès de ${member.noms} révoqué',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  // ────────────────────────────────────────────────────
  // MODIFIER un membre staff
  // ────────────────────────────────────────────────────
  Future<void> _editStaffMember(MemberAccount member) async {
    // Re-use AddMemberView for editing staff
    // We need to wrap it in a scaffold or dialog
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'MODIFIER STAFF',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                // We use AddMemberView directly
                // Note: I need to import it first
               _AddMemberViewWrapper(
                  memberRepository: widget.memberRepository,
                  staffMember: member, // Passing the member as both staff (to allow role edits) and memberToEdit
                  memberToEdit: member,
                  onSave: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────
  // DIALOG : ajouter un membre staff
  // ────────────────────────────────────────────────────
  Future<void> _showAddStaffDialog() async {
    final matriculeController = TextEditingController();
    final nomsController = TextEditingController();
    final telController = TextEditingController();
    String selectedRole = 'staff';
    final formKey = GlobalKey<FormState>();
    bool isLoadingMatricule = true;

    // Local function to generate staff matricule
    Future<void> updateMatricule(StateSetter setDialogState) async {
      setDialogState(() => isLoadingMatricule = true);
      try {
        final next = await widget.memberRepository.generateNextMatricule(isStaff: true);
        setDialogState(() {
          matriculeController.text = next;
          isLoadingMatricule = false;
        });
      } catch (e) {
        setDialogState(() => isLoadingMatricule = false);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (matriculeController.text.isEmpty && isLoadingMatricule) {
            updateMatricule(setDialogState);
          }
          
          return AlertDialog(
            backgroundColor: const Color(0xFF161616),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'NOUVEAU MEMBRE STAFF',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField(
                      matriculeController, 
                      'Matricule (généré...)', 
                      Icons.badge_rounded,
                      enabled: false,
                      isLoading: isLoadingMatricule,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(nomsController, 'Nom complet', Icons.person_rounded),
                    const SizedBox(height: 12),
                    _buildDialogField(telController, 'Téléphone', Icons.phone_rounded, isPhone: true),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161616),
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'staff', child: Text('Staff')),
                            DropdownMenuItem(value: 'superAdmin', child: Text('Super Admin')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedRole = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('ANNULER', style: GoogleFonts.outfit(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);
                  await _createStaffMember(
                    matricule: matriculeController.text.trim().toUpperCase(),
                    noms: nomsController.text.trim(),
                    telephone: telController.text.trim(),
                    role: selectedRole,
                  );
                },
                child: Text('CRÉER', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isPhone = false,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.outfit(color: enabled ? Colors.white : Colors.white38),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      enabled: enabled,
      readOnly: !enabled,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        suffixIcon: isLoading ? const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
        ) : (!enabled && ctrl.text.isNotEmpty ? const Icon(Icons.auto_fix_high_rounded, color: Colors.white10, size: 16) : null),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────
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
          'GESTION DU STAFF',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        actions: [
          // Indicateur de statut réseau
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: 'Mode hors-ligne – données locales',
                child: const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 20),
              ),
            ),
          IconButton(
            onPressed: _isSyncing ? null : _syncFromFirestore,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                  )
                : const Icon(Icons.sync_rounded, color: Colors.white38),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('AJOUTER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      // ValueListenableBuilder = réactif Hive, pas de setState pour la liste
      body: ValueListenableBuilder(
        valueListenable: Hive.box<MemberAccount>(HiveService.accountsBoxName).listenable(),
        builder: (context, Box<MemberAccount> box, _) {
          final staffMembers = _getStaffFromHive(box);
          return _buildBody(staffMembers);
        },
      ),
    );
  }

  Widget _buildBody(List<MemberAccount> staffMembers) {
    if (staffMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off_rounded, color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            Text(
              _isOffline
                  ? 'Aucun staff en cache local.\nConnectez-vous pour synchroniser.'
                  : 'Aucun membre staff trouvé.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white24, height: 1.6),
            ),
            if (_isOffline) ...[
              const SizedBox(height: 16),
              const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 28),
            ],
          ],
        ),
      );
    }

    final superAdmins = staffMembers.where((m) => m.role == 'superAdmin').toList();
    final staffOnly = staffMembers.where((m) => m.role == 'staff').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        // Bannière offline si applicable
        if (_isOffline)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mode hors-ligne — données locales. Sync auto dès connexion rétablie.',
                    style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        _buildSummaryBanner(superAdmins.length, staffOnly.length),
        const SizedBox(height: 28),

        if (superAdmins.isNotEmpty) ...[
          _buildSectionLabel('SUPER ADMINS', superAdmins.length, Colors.orangeAccent),
          const SizedBox(height: 12),
          ...superAdmins.map((m) => _buildStaffCard(m)),
          const SizedBox(height: 28),
        ],

        if (staffOnly.isNotEmpty) ...[
          _buildSectionLabel('STAFF', staffOnly.length, Colors.white54),
          const SizedBox(height: 12),
          ...staffOnly.map((m) => _buildStaffCard(m)),
        ],
      ],
    );
  }

  Widget _buildSummaryBanner(int admins, int staff) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBannerStat('TOTAL', (admins + staff).toString(), Colors.white),
          _buildDivider(),
          _buildBannerStat('ADMINS', admins.toString(), Colors.orangeAccent),
          _buildDivider(),
          _buildBannerStat('STAFF', staff.toString(), Colors.white54),
        ],
      ),
    );
  }

  Widget _buildBannerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.07));
  }

  Widget _buildSectionLabel(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 3),
        ),
        const SizedBox(width: 8),
        Text('($count)', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24)),
      ],
    );
  }

  Widget _buildStaffCard(MemberAccount member) {
    final isSuperAdmin = member.role == 'superAdmin';
    final initials = member.noms.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSuperAdmin
              ? Colors.orangeAccent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSuperAdmin
                  ? Colors.orangeAccent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isSuperAdmin ? Colors.orangeAccent : Colors.white54,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.noms,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '#${member.matricule}',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold),
                    ),
                    if (member.telephone.isNotEmpty) ...[
                      Text(' • ', style: GoogleFonts.outfit(color: Colors.white12)),
                      Flexible(
                        child: Text(
                          member.telephone,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuperAdmin
                      ? Colors.orangeAccent.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isSuperAdmin ? 'ADMIN' : 'STAFF',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isSuperAdmin ? Colors.orangeAccent : Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _confirmRevokeAccess(member),
                child: Text(
                  'RÉVOQUER',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _editStaffMember(member),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white38, size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petit wrapper pour injecter AddMemberView proprement dans le contexte de StaffManagementPage
class _AddMemberViewWrapper extends StatelessWidget {
  final MemberRepository memberRepository;
  final MemberAccount staffMember;
  final MemberAccount memberToEdit;
  final VoidCallback onSave;

  const _AddMemberViewWrapper({
    required this.memberRepository,
    required this.staffMember,
    required this.memberToEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AddMemberView(
      memberRepository: memberRepository,
      staffMember: staffMember,
      memberToEdit: memberToEdit,
      onSave: onSave,
    );
  }
}
