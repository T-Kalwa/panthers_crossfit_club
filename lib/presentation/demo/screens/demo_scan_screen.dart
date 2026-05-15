import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../domain/models/member_account.dart';
import '../../../data/services/demo_auth_service.dart';
import 'demo_login_screen.dart';

class DemoScanScreen extends StatefulWidget {
  final MemberRepository memberRepository;
  final bool isKioskMode;

  const DemoScanScreen({super.key, required this.memberRepository, this.isKioskMode = false});

  @override
  State<DemoScanScreen> createState() => _DemoScanScreenState();
}

class _DemoScanScreenState extends State<DemoScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    
    // 1. On essaie d'extraire le matricule si c'est un format sécurisé (ancien)
    String matricule = code.trim().toUpperCase();
    if (code.contains('|')) {
      final parts = code.split('|');
      if (parts.isNotEmpty) {
        matricule = parts[0].trim().toUpperCase();
      }
    }

    // 2. Recherche du membre
    final member = await widget.memberRepository.getMemberAccountByMatricule(matricule);

    if (member == null) {
      _showResultModal(type: 'invalid');
    } else if (member.isExpired) {
      _showResultModal(type: 'expired', member: member);
    } else {
      _showResultModal(type: 'success', member: member);
    }
  }

  void _showResultModal({required String type, MemberAccount? member}) {
    Color color;
    String title;
    IconData icon;
    String sound = 'sounds/error.mp3';
    
    if (type == 'success') {
      sound = 'sounds/success.mp3';
      color = const Color(0xFF39FF14); // Cyber Green
      title = 'BIENVENUE';
      icon = Icons.check_circle_rounded;
    } else if (type == 'expired') {
      color = Colors.redAccent;
      title = 'ABONNEMENT EXPIRÉ';
      icon = Icons.error_rounded;
    } else {
      color = Colors.orangeAccent;
      title = 'CODE INVALIDE';
      icon = Icons.help_rounded;
    }

    _audioPlayer.play(AssetSource(sound)).catchError((e) => debugPrint('Sound error: $e'));
    
    if (type == 'success') {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.vibrate();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: color.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            setState(() => _isProcessing = false);
          }
        });

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 160, color: Colors.white)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 40),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                if (member != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    member.noms.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleCapture,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: Icon(widget.isKioskMode ? Icons.logout_rounded : Icons.close, color: Colors.white),
                onPressed: () async {
                  if (widget.isKioskMode) {
                    await DemoAuthService.clearSession();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => DemoLoginScreen(memberRepository: widget.memberRepository)), (_) => false);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ALIGNER LE QR CODE',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
