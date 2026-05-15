import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/member_account.dart';
import '../../data/repositories/member_repository.dart';
import 'staff_views/overview_view.dart';
import 'staff_views/add_member_view.dart';
import 'staff_views/members_list_view.dart';
import 'staff_views/staff_profile_view.dart';
import 'login_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  final MemberAccount staffMember;
  final MemberRepository memberRepository;

  const StaffDashboardScreen({
    super.key,
    required this.staffMember,
    required this.memberRepository,
  });

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Activation de la synchronisation en temps réel (Firestore -> Hive)
    // Cela permet d'avoir les données à jour dès que la connexion revient.
    widget.memberRepository.startRealtimeSync();
  }

  int _selectedIndex = 0;
  MemberAccount? _memberToEdit;

  final List<String> _titles = [
    'TABLEAU DE BORD',
    'AJOUTER CLIENT',
    'LISTE DES MEMBRES',
    'MON PROFIL',
  ];

  void _startEditing(MemberAccount member) {
    setState(() {
      _memberToEdit = member;
      _selectedIndex = 1; // Switch to Add Member tab
    });
  }

  void _clearEditing() {
    setState(() {
      _memberToEdit = null;
      _selectedIndex = 2; // Switch back to list after save
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(isMobile),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? _buildBottomBar() : null,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarItem(0, Icons.dashboard_rounded),
          _buildBottomBarItem(1, Icons.person_add_rounded),
          _buildBottomBarItem(2, Icons.group_rounded),
          _buildBottomBarItem(3, Icons.account_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildBottomBarItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedIndex = index;
        if (index != 1) _memberToEdit = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white30,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              'assets/images/logo_splash.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(0, Icons.dashboard_rounded),
          _buildSidebarItem(1, Icons.person_add_rounded),
          _buildSidebarItem(2, Icons.group_rounded),
          const Spacer(),
          _buildSidebarItem(3, Icons.account_circle_rounded),
          const SizedBox(height: 20),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen(memberRepository: widget.memberRepository)),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white30),
            tooltip: 'Déconnexion',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedIndex = index;
        if (index != 1) _memberToEdit = null; // Reset edit mode when changing tabs (unless going to Add Client)
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white30,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              onPressed: () => Navigator.pop(context), // Back to Admin Hub if applicable
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedIndex == 1 && _memberToEdit != null ? 'MODIFIER MEMBRE' : _titles[_selectedIndex],
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 20 : 24, // Slightly smaller on mobile
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: isMobile ? 1 : 2, // Tighter on mobile
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              widget.staffMember.matricule,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = OverviewView(
          key: const ValueKey('overview'),
          staffMember: widget.staffMember,
        );
        break;
      case 1:
        content = AddMemberView(
          key: ValueKey('add_member_${_memberToEdit?.matricule ?? "new"}'),
          memberRepository: widget.memberRepository,
          staffMember: widget.staffMember,
          memberToEdit: _memberToEdit,
          onSave: _clearEditing,
        );
        break;
      case 2:
        content = MembersListView(
          key: const ValueKey('members_list'),
          staffMember: widget.staffMember,
          memberRepository: widget.memberRepository,
          onEdit: _startEditing,
        );
        break;
      case 3:
        content = StaffProfileView(
          key: const ValueKey('staff_profile'),
          staffMember: widget.staffMember,
        );
        break;
      default:
        content = OverviewView(
          key: const ValueKey('overview_default'),
          staffMember: widget.staffMember,
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: content,
    );
  }
}
