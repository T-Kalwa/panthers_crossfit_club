import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/services/demo_auth_service.dart';
import '../../../domain/models/member_account.dart';
import '../widgets/member_pass_card.dart';
import '../utils/demo_utils.dart';
import 'demo_add_member_view.dart';
import 'demo_scan_screen.dart';
import 'demo_members_list_view.dart';
import 'demo_renew_member_view.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'demo_login_screen.dart';

class DemoAdminDashboard extends StatefulWidget {
  final MemberRepository memberRepository;
  final DemoAuthUser currentUser;

  const DemoAdminDashboard({super.key, required this.memberRepository, required this.currentUser});

  @override
  State<DemoAdminDashboard> createState() => _DemoAdminDashboardState();
}

class _DemoAdminDashboardState extends State<DemoAdminDashboard> {
  int _selectedTab = 0; // 0=Dashboard, 1=Membres, 2=Staff
  bool _isClearing = false;
  bool _isExporting = false;

  Future<void> _logout() async {
    await DemoAuthService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DemoLoginScreen(memberRepository: widget.memberRepository)),
      (_) => false,
    );
  }

  Future<void> _confirmAndClearDb() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('VIDER LA BASE DE DONNÉES', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)),
        content: Text('Tous les membres inscrits seront supprimés.\nCette action est irréversible.', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ANNULER', style: GoogleFonts.outfit(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('CONFIRMER', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isClearing = true);
    try {
      await widget.memberRepository.clearAllData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Base vidée.', style: GoogleFonts.outfit()), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildDashboardTab(),
                  _buildMembresTab(),
                  _buildStaffTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PANTHERS', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4)),
              Text('ADMIN — ${widget.currentUser.nom.toUpperCase()}',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.amber.withOpacity(0.8), fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DemoScanScreen(memberRepository: widget.memberRepository),
            )),
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white54),
            tooltip: 'Scanner',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white38),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.people_alt_rounded, 'Membres'),
      (Icons.badge_rounded, 'Staff'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final selected = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tabs[i].$1, size: 16, color: selected ? Colors.white : Colors.white38),
                      const SizedBox(width: 6),
                      Text(tabs[i].$2, style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected ? Colors.white : Colors.white38,
                      )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── DASHBOARD TAB ────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('members').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final members = docs.map((d) => MemberAccount.fromJson(d.data() as Map<String, dynamic>)).toList();

        // Filter out admin/staff accounts
        final clients = members.where((m) => m.role == 'membre').toList();
        final activeClients = clients.where((m) => !m.isExpired && m.isActive).toList();
        final expiredClients = clients.where((m) => m.isExpired).toList();
        final totalRevenue = clients.fold<double>(0, (sum, m) => sum + m.montantPaye);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Cards
              Row(
                children: [
                  Expanded(child: _buildKpiCard('REVENUS', '${totalRevenue.toStringAsFixed(0)} \$', Icons.payments_rounded, Colors.amber)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard('MEMBRES', '${clients.length}', Icons.people_rounded, Colors.blueAccent)),
                ],
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildKpiCard('ACTIFS', '${activeClients.length}', Icons.check_circle_rounded, Colors.greenAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard('EXPIRÉS', '${expiredClients.length}', Icons.warning_rounded, Colors.redAccent)),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              // Quick Actions
              Text('ACTIONS RAPIDES', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildQuickAction('Nouveau\nmembre', Icons.person_add_rounded, Colors.greenAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DemoAddMemberView(
                      memberRepository: widget.memberRepository,
                      inscritPar: widget.currentUser.matricule,
                    )));
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction('Nouveau\nstaff', Icons.badge_rounded, Colors.blueAccent, () => _showAddStaffDialog(context))),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildQuickAction('Exporter\nrapport', Icons.download_rounded, Colors.amber, _exportReport)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction('Vider\nla DB', Icons.delete_rounded, Colors.redAccent, _isClearing ? null : _confirmAndClearDb)),
                ],
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // Recent members
              Text('DERNIERS INSCRITS', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              ...clients.reversed.take(5).map((m) => _buildMiniMemberRow(m)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: onTap == null ? color.withOpacity(0.4) : color, size: 26),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMemberRow(MemberAccount m) {
    final isActive = !m.isExpired && m.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(m.noms, style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
          Text(m.activite, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 12),
          Text('${m.montantPaye.toStringAsFixed(0)}\$', style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    String role = 'staff';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              left: 32, right: 32, top: 32,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 32),
                  Text('AJOUTER UN STAFF', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: nomCtrl,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      labelStyle: GoogleFonts.outfit(color: Colors.white38),
                      filled: true, fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 2),
                    decoration: InputDecoration(
                      labelText: 'Téléphone (Sert de login)',
                      labelStyle: GoogleFonts.outfit(color: Colors.white38, letterSpacing: 0),
                      prefixText: '+243 ',
                      prefixStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
                      counterText: '',
                      filled: true, fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v!.trim().length != 9 ? 'Le numéro doit avoir 9 chiffres' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Rôle',
                      labelStyle: GoogleFonts.outfit(color: Colors.white38),
                      filled: true, fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'staff', child: Text('STAFF (Inscriptions & Scan)')),
                      DropdownMenuItem(value: 'scan', child: Text('SCAN UNIQUEMENT (Kiosque)')),
                    ],
                    onChanged: (v) => setStateSB(() => role = v!),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, elevation: 0),
                      onPressed: isSaving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setStateSB(() => isSaving = true);
                        final success = await DemoAuthService.createStaffAccount(
                          nom: nomCtrl.text,
                          telephone: '+243 ${telCtrl.text.trim()}',
                          role: role,
                        );
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff ajouté avec succès'), backgroundColor: Colors.green));
                        } else if (mounted) {
                          setStateSB(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'ajout'), backgroundColor: Colors.red));
                        }
                      },
                      child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('CRÉER LE COMPTE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── MEMBRES TAB ────────────────────────────────────────────────────
  Widget _buildMembresTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('members').where('role', isEqualTo: 'membre').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text('Aucun membre.', style: GoogleFonts.outfit(color: Colors.white38)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final m = MemberAccount.fromJson(docs[index].data() as Map<String, dynamic>);
            return _buildAdminMemberTile(m);
          },
        );
      },
    );
  }

  Widget _buildAdminMemberTile(MemberAccount m) {
    final isExpired = m.isExpired;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(m.noms, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isExpired ? 'EXPIRÉ' : 'ACTIF',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: isExpired ? Colors.redAccent : Colors.greenAccent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailChip(Icons.badge_outlined, m.matricule),
          const SizedBox(height: 4),
          _buildDetailChip(Icons.fitness_center_rounded, '${m.activite} — ${m.dureeForfait}'),
          const SizedBox(height: 4),
          _buildDetailChip(Icons.payments_rounded, '${m.montantPaye.toStringAsFixed(0)} \$', color: Colors.amber),
          if (m.inscritPar != null) ...[
            const SizedBox(height: 4),
            _buildDetailChip(Icons.person_outline_rounded, 'Inscrit par: ${m.inscritPar}', color: Colors.blueAccent),
          ],
          const SizedBox(height: 4),
          _buildDetailChip(Icons.calendar_today_rounded,
            '${DateFormat('dd/MM/yy').format(m.dateDebut)} → ${DateFormat('dd/MM/yy').format(m.dateFin)}'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DemoRenewMemberView(memberRepository: widget.memberRepository, member: m),
                )),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('RÉABONNER', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showPassPreview(m),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                label: Text('PASS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.white38),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.outfit(color: color ?? Colors.white54, fontSize: 13)),
      ],
    );
  }

  void _showPassPreview(MemberAccount member) {
    final passKey = GlobalKey();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(key: passKey, child: MemberPassCard(member: member)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconBtn(Icons.share_rounded, Colors.blueAccent, () => DemoUtils.shareWidgetAsImage(passKey, 'pass_${member.matricule}')),
                const SizedBox(width: 16),
                _buildIconBtn(Icons.download_rounded, Colors.greenAccent, () => DemoUtils.saveToGallery(passKey, 'pass_${member.matricule}')),
                const SizedBox(width: 16),
                _buildIconBtn(Icons.close_rounded, Colors.white24, () => Navigator.pop(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.2))),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  // ─── STAFF TAB ────────────────────────────────────────────────────
  Widget _buildStaffTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('members')
          .where('role', whereIn: ['staff', 'superAdmin', 'scan']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text('Aucun compte staff.', style: GoogleFonts.outfit(color: Colors.white38)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildStaffTile(data);
          },
        );
      },
    );
  }

  Widget _buildStaffTile(Map<String, dynamic> data) {
    final role = data['role'] as String? ?? 'staff';
    final color = role == 'superAdmin' ? Colors.amber : role == 'scan' ? Colors.blueAccent : Colors.greenAccent;
    final label = role == 'superAdmin' ? 'ADMIN' : role == 'scan' ? 'SCAN' : 'STAFF';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.person, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['noms'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                Text(data['email'] ?? data['matricule'] ?? '', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }

  // ─── EXPORT ────────────────────────────────────────────────────
  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('members').where('role', isEqualTo: 'membre').get();
      final members = snapshot.docs.map((d) => MemberAccount.fromJson(d.data())).toList();

      final pdf = pw.Document();

      double totalRevenue = 0;
      for (final m in members) {
        totalRevenue += m.montantPaye;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('RAPPORT PANTHERS CROSSFIT CLUB', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                  ]
                )
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                headers: ['Nom', 'Tél', 'Forfait', 'Tarif (\$)', 'Inscrit par', 'Statut'],
                data: members.map((m) => [
                  m.noms,
                  m.telephone,
                  '${m.activite} - ${m.dureeForfait}',
                  m.montantPaye.toStringAsFixed(0),
                  m.inscritPar ?? 'N/A',
                  m.isExpired ? 'EXPIRÉ' : 'ACTIF',
                ]).toList(),
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL REVENUS: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${totalRevenue.toStringAsFixed(0)} \$', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL MEMBRES: ${members.length}'),
                ]
              )
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'rapport_panthers_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
