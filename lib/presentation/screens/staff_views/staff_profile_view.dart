import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/member_account.dart';

class StaffProfileView extends StatelessWidget {
  final MemberAccount staffMember;
  const StaffProfileView({super.key, required this.staffMember});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;
        final bool isExtraSmall = constraints.maxWidth < 380;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 20.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 24 : 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(isSmall ? 24 : 40),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isExtraSmall ? 35 : (isSmall ? 40 : 50),
                      backgroundColor: Colors.white.withOpacity(0.05),
                      child: Text(
                        staffMember.noms.isNotEmpty ? staffMember.noms[0] : '?',
                        style: GoogleFonts.outfit(
                          fontSize: isExtraSmall ? 28 : (isSmall ? 32 : 40),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmall ? 20 : 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staffMember.noms.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: isExtraSmall ? 20 : (isSmall ? 24 : 32),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PERSONNEL CONNECTÉ',
                            style: GoogleFonts.outfit(
                              fontSize: isExtraSmall ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white24,
                              letterSpacing: isExtraSmall ? 2 : 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmall ? 24 : 40),
              _buildInfoRow('MATRICULE', staffMember.matricule, isSmall),
              _buildInfoRow('ACCÈS', 'ADMINISTRATION COMPLÈTE', isSmall),
              _buildInfoRow('SESSION', 'ACTIVE', isSmall),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: isSmall ? 10 : 12,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
