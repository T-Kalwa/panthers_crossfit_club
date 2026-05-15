import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/member_repository.dart';
import '../../domain/models/member_account.dart';
import '../../data/services/secure_qr_service.dart';

class ScanScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const ScanScreen({super.key, required this.memberRepository});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
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
    
    // 1. Vérification du format et du timestamp du QR (Anti-Capture d'écran)
    final String? matricule = SecureQrService.verifyAndExtractMatricule(code);
    
    if (matricule == null) {
      // Pour la compatibilité POC, on accepte aussi le matricule brut "P009"
      if (code == 'P009') {
        _processVerification(code);
      } else {
        _showResultModal(type: 'invalid');
      }
      return;
    }

    _processVerification(matricule);
  }

  Future<void> _processVerification(String matricule) async {
    final member = await widget.memberRepository.getMemberAccountByMatricule(matricule);

    if (member == null) {
      _showResultModal(type: 'invalid');
    } else if (!member.isActive) {
      _showResultModal(type: 'banned', member: member);
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
    
    if (type == 'success') {
      _audioPlayer.play(AssetSource('sounds/success.mp3'));
      HapticFeedback.mediumImpact();
      color = const Color(0xFF39FF14); // Cyber Green
      title = 'ACCÈS AUTORISÉ';
      icon = Icons.check_circle_outline_rounded;
    } else if (type == 'expired') {
      _audioPlayer.play(AssetSource('sounds/error.mp3'));
      HapticFeedback.vibrate();
      color = Colors.redAccent;
      title = 'ABONNEMENT EXPIRÉ';
      icon = Icons.error_outline_rounded;
    } else if (type == 'banned') {
      _audioPlayer.play(AssetSource('sounds/error.mp3'));
      color = Colors.black;
      title = 'ACCÈS RÉVOQUÉ / BANNIS';
      icon = Icons.block_flipped;
    } else {
      _audioPlayer.play(AssetSource('sounds/error.mp3'));
      color = Colors.orangeAccent;
      title = 'CODE INCONNU';
      icon = Icons.help_outline_rounded;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: color.withOpacity(0.9), // Full screen color overlay
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        // Auto-close logic
        Future.delayed(Duration(seconds: type == 'success' ? 2 : 4), () {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            if (mounted) setState(() => _isProcessing = false);
          }
        });

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 120, color: Colors.white)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ).animate().slideY(begin: 0.2, end: 0),
                if (member != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    member.noms.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 120), // Espace compensatoire pour l'absence du bouton
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
          // Overlay (Viseur Scanner)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // Simulation d'un scan réussi avec le matricule de test P001
                    _processVerification('P001');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'SIMULER SCAN (P001)',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SCANNAGE DES PASS...',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
