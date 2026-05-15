import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/member_repository.dart';
import 'demo_scan_screen.dart';

class DemoScanOnlyScreen extends StatelessWidget {
  final MemberRepository memberRepository;

  const DemoScanOnlyScreen({super.key, required this.memberRepository});

  @override
  Widget build(BuildContext context) {
    // This role is meant for a device placed at the gym entrance.
    // It launches the scanner immediately, fullscreen.
    return DemoScanScreen(memberRepository: memberRepository, isKioskMode: true);
  }
}
