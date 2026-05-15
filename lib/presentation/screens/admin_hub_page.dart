import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/member_account.dart';
import '../../data/repositories/member_repository.dart';
import 'scan_screen.dart';
import 'staff_dashboard_screen.dart';
import 'admin_views/finance_dashboard_page.dart';
import 'admin_views/staff_management_page.dart';
import 'login_screen.dart';

class AdminHubPage extends StatelessWidget {
  final MemberAccount staffMember;
  final MemberRepository memberRepository;

  const AdminHubPage({
    super.key,
    required this.staffMember,
    required this.memberRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmall = constraints.maxHeight < 700;
            final bool isNarrow = constraints.maxWidth < 380;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? 16.0 : 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - (isNarrow ? 32 : 64)),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmall ? 20 : 40),
                      _buildHeader(context, isNarrow),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Image.asset(
                          'assets/images/logo_splash.png',
                          height: isSmall ? 80 : 120,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fitness_center,
                            size: isSmall ? 60 : 80,
                            color: Colors.white10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildIconButton(
                              context,
                              title: 'SCANNER',
                              icon: Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              isSmall: isSmall,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScanScreen(memberRepository: memberRepository),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isNarrow ? 12 : 20),
                          Expanded(
                            child: _buildIconButton(
                              context,
                              title: 'GÉRER',
                              icon: Icons.group_rounded,
                              color: Colors.white.withOpacity(0.05),
                              isOutline: true,
                              isSmall: isSmall,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StaffDashboardScreen(
                                    staffMember: staffMember,
                                    memberRepository: memberRepository,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (staffMember.role == 'superAdmin') ...[
                        SizedBox(height: isNarrow ? 12 : 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildIconButton(
                                context,
                                title: 'FINANCES',
                                icon: Icons.account_balance_rounded,
                                color: Colors.white.withOpacity(0.05),
                                isOutline: true,
                                isSmall: isSmall,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FinanceDashboardPage(memberRepository: memberRepository),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: isNarrow ? 12 : 20),
                            Expanded(
                              child: _buildIconButton(
                                context,
                                title: 'ÉQUIPE',
                                icon: Icons.manage_accounts_rounded,
                                color: Colors.white.withOpacity(0.05),
                                isOutline: true,
                                isSmall: isSmall,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StaffManagementPage(memberRepository: memberRepository),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isNarrow) {
    return Column(
      children: [
        Text(
          'BIENVENUE,',
          style: GoogleFonts.outfit(
            fontSize: isNarrow ? 10 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          staffMember.noms.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isNarrow ? 20 : 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            staffMember.matricule.startsWith('PS') ? 'ACCÈS STAFF' : 'ADMINISTRATEUR',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white54,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutline = false,
    bool isSmall = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isSmall ? 24 : 40),
      child: Container(
        height: isSmall ? 130 : 180,
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(isSmall ? 24 : 40),
          border: isOutline ? Border.all(color: Colors.white.withOpacity(0.1), width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutline ? Colors.white : Colors.black,
              size: isSmall ? 32 : 48,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isOutline ? Colors.white : Colors.black,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoginScreen(memberRepository: memberRepository),
              ),
            );
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.white38, size: 18),
          label: Text(
            'DÉCONNEXION',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white38,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'PANTHERS CLUB • ADMIN SYSTEM v2.0',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white12,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
