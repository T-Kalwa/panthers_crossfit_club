import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/member_account.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/services/hive_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'about_us_screen.dart';
import '../widgets/payment_bottom_sheet.dart';
import '../../data/services/secure_qr_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'login_screen.dart';
import 'package:showcaseview/showcaseview.dart';

class MemberDashboardScreen extends StatefulWidget {
  final MemberAccount member;

  const MemberDashboardScreen({super.key, required this.member});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final HiveService _hiveService = HiveService();
  final PageController _sliderController = PageController();
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  List<bool> _weeklyTracker = List.generate(7, (_) => false);
  int _currentSlide = 0;
  String _qrData = '';
  Timer? _qrUpdateTimer;
  bool _isSyncing = false;

  Future<void> _handleSyncStatus() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final updatedMember = await MemberRepository().loginByMatriculeAndPhone(
        widget.member.matricule, 
        widget.member.telephone
      );

      if (updatedMember != null) {
        if (!updatedMember.isExpired) {
          // Success!
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Abonnement renouvelé ! Bienvenue au club.'),
                backgroundColor: Colors.green,
              ),
            );
            // Rediriger ou mettre à jour l'état local
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MemberDashboardScreen(member: updatedMember))
            );
          }
        } else {
          // Still expired
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Toujours expiré. Demandez au Staff de valider votre paiement.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur de synchronisation. Vérifiez votre connexion à la réception.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌐 Erreur réseau.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // Showcase keys
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey _three = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadTrackerData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    // Affichage d'une fenêtre d'alerte si l'abonnement est expiré
    if (widget.member.isExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showExpiredDialog(context);
      });
    }

    // Lancer le tutoriel si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hiveService.hasSeenDashboardTutorial && !widget.member.isExpired) {
        ShowCaseWidget.of(context).startShowCase([_one, _two, _three]);
        _hiveService.setHasSeenDashboardTutorial(true);
      }
    });
  }

  void _showExpiredDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Empêche de fermer en cliquant à côté
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 64),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                  const SizedBox(height: 24),
                  Text(
                    'ATTENTION',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 8),
                  Text(
                    'ABONNEMENT EXPIRÉ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ).animate().slideY(begin: 0.2, end: 0, delay: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Votre accès au club est actuellement bloqué. Veuillez renouveler votre pass pour débloquer votre code QR.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isSyncing ? null : _handleSyncStatus,
                      icon: _isSyncing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_rounded),
                      label: Text(
                        _isSyncing ? 'SYNCHRONISATION...' : 'SYNCHRONISER MON PASS',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'FERMER',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 2,
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _qrUpdateTimer?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  void _loadTrackerData() {
    final now = DateTime.now();
    final currentWeekId = _getWeekId(now);
    final lastReset = widget.member.lastGoalReset;
    
    // Reset if it's a new week (Monday reset)
    if (lastReset == null || _getWeekId(lastReset) != currentWeekId) {
      _weeklyTracker = List.generate(7, (_) => false);
      _saveGoalData();
    } else {
      // Load from member data
      _weeklyTracker = List.generate(7, (index) => 
        widget.member.reachedGoals?.contains(index) ?? false);
    }
    setState(() {});
  }

  void _saveGoalData() {
    final List<int> reached = [];
    for (int i = 0; i < 7; i++) {
        if (_weeklyTracker[i]) reached.add(i);
    }
    
    // Update the member object and save to Hive
    final updatedMember = widget.member.copyWith(
      reachedGoals: reached,
      lastGoalReset: DateTime.now(),
    );
    
    // Persist to the local box
    final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
    box.put(updatedMember.matricule, updatedMember);
    
    // If this is the logged-in user, also update 'current_account'
    if (box.get('current_account')?.matricule == updatedMember.matricule) {
       box.put('current_account', updatedMember);
    }
  }

  int _getWeekId(DateTime date) {
    DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return startOfWeek.year * 10000 + startOfWeek.month * 100 + startOfWeek.day;
  }

  void _toggleDay(int index) {
    if (index == DateTime.now().weekday - 1) {
      setState(() {
        _weeklyTracker[index] = !_weeklyTracker[index];
      });
      _saveGoalData();
    }
  }

  void _startTutorialIfPossible(BuildContext context) {
    if (!_hiveService.hasSeenDashboardTutorial && !widget.member.isExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([_one, _two, _three]);
        // Note: setting it to true after it finishes or starts
        _hiveService.setHasSeenDashboardTutorial(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) {
        _startTutorialIfPossible(context);
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background Image with Overlay
              Positioned.fill(
                child: Image.asset(
                  'assets/images/int_3.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              // Background Glow
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ).animate().fadeIn(duration: 2000.ms),
              
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTopNav(context).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
                      const SizedBox(height: 24),
                      _buildProgressCircle().animate().scale(duration: 800.ms, curve: Curves.easeOutBack, delay: 200.ms),
                      const SizedBox(height: 32),
                      Showcase(
                        key: _two,
                        title: 'Objectifs de la semaine',
                        description: 'Swippez ici pour alterner entre l\'heure et vos objectifs. Cliquez sur un jour pour valider votre séance !',
                        targetPadding: const EdgeInsets.all(8),
                        child: _buildDashboardSlider(),
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 32),
                      Showcase(
                        key: _three,
                        title: 'Votre PASS QR',
                        description: 'Cliquez ici pour générer votre QR code et scanner votre entrée au club.',
                        child: _buildQuickAction(context),
                      ).animate().fadeIn(delay: 600.ms).scale(curve: Curves.elasticOut, duration: 1000.ms),
                      const SizedBox(height: 40),
                      _buildDetailCards(context).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PANTHERS',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            Text(
              'CROSSFIT CLUB',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.member.noms.split(' ').first.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 20, // Increased size for the first name
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'MEMBRE VIP',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Showcase(
              key: _one,
              title: 'Votre Profil',
              description: 'Consultez vos infos et déconnectez-vous ici.',
              child: InkWell(
                onTap: _showProfileInfo,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.white24, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              ),
              icon: const Icon(Icons.info_outline, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: widget.member.expiryProgress,
            strokeWidth: 10,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: Colors.white,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.member.daysRemaining}',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1,
                color: Colors.white,
              ),
            ),
            Text(
              'JOURS RESTANTS',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardSlider() {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView(
            controller: _sliderController,
            onPageChanged: (index) => setState(() => _currentSlide = index),
            children: [
              _buildClockSlide(),
              _buildWeeklyTrackerSlide(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: _currentSlide == index ? 24 : 6,
            decoration: BoxDecoration(
              color: _currentSlide == index ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(3),
              boxShadow: _currentSlide == index ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ] : null,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildClockSlide() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('HH:mm').format(_now),
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              Text(
                DateFormat('EEEE d MMMM', 'fr').format(_now).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTrackerSlide() {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'OBJECTIF SEMAINE',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  bool isToday = index == DateTime.now().weekday - 1;
                  bool isValidated = _weeklyTracker[index];
                  return GestureDetector(
                    onTap: () => _toggleDay(index),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isValidated ? Colors.white : Colors.transparent,
                            border: Border.all(
                              color: isValidated 
                                  ? Colors.white 
                                  : (isToday ? Colors.white.withOpacity(0.5) : Colors.white10),
                              width: 2,
                            ),
                            boxShadow: isValidated ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                              )
                            ] : null,
                          ),
                          child: Center(
                            child: isValidated 
                                ? const Icon(Icons.check, size: 20, color: Colors.black)
                                : (isToday ? const Icon(Icons.fitness_center, size: 16, color: Colors.white) : null),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[index],
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context) {
    final bool isExpired = widget.member.isExpired;

    return Column(
      children: [
        if (isExpired) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_flipped, color: Colors.redAccent, size: 40),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms),
                const SizedBox(height: 16),
                Text(
                  'ACCÈS BLOQUÉ',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Renouvelez votre pass pour accéder au club et générer votre QR code.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _handleSyncStatus,
                    icon: _isSyncing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.sync_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    label: Text(
                      _isSyncing ? 'EN COURS...' : 'SYNCHRONISER MON COMPTE',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showPaymentOptions(context),
                  child: Text(
                    'VOIR LES TARIFS',
                    style: GoogleFonts.outfit(color: Colors.white38, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(delay: 600.ms),
        ] else ...[
          InkWell(
            onTap: () => _showQrModal(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 26),
                  const SizedBox(width: 16),
                  Text(
                    'VOTRE PASS QR',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(curve: Curves.elasticOut, duration: 1000.ms),
        ],
      ],
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PaymentBottomSheet(),
    );
  }

  Widget _buildDetailCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildGlassCard(
              'Activité',
              widget.member.activite,
              Icons.bolt_rounded,
            ),
            const SizedBox(width: 20),
            _buildGlassCard(
              'Coaching',
              widget.member.avecCoach ? 'Inclus' : 'Standard',
              Icons.star_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildGlassCardFull(
          'Abonnement jusqu\'au',
          _formatDate(widget.member.dateFin),
          Icons.calendar_today_rounded,
        ),
      ],
    );
  }

  Widget _buildGlassCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCardFull(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 50),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: CircleAvatar(
                radius: 46,
                backgroundImage: widget.member.profileImageUrl != null
                    ? (widget.member.profileImageUrl!.startsWith('http')
                        ? NetworkImage(widget.member.profileImageUrl!)
                        : FileImage(File(widget.member.profileImageUrl!)) as ImageProvider)
                    : null,
                backgroundColor: Colors.black,
                child: widget.member.profileImageUrl == null
                    ? Icon(Icons.person, color: Colors.white.withOpacity(0.5), size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.member.noms.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            Text(
              'MEMBRE #${widget.member.matricule}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _hiveService.clear();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(
                          memberRepository: MemberRepository(), // Create fresh repo
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: Text(
                    'DÉCONNEXION',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildModalCloseButton(context),
          ],
        ),
      ),
    );
  }

  void _showQrModal(BuildContext context) {
    // Generate initial QR data
    _qrData = SecureQrService.generateSecureQrData(widget.member.matricule);
    
    // Refresh QR data every 30 seconds while modal is open
    _qrUpdateTimer?.cancel();
    _qrUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _qrData = SecureQrService.generateSecureQrData(widget.member.matricule);
        });
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Inner timer to update the modal state too
          Timer? innerTimer;
          innerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
            if (context.mounted) {
              setModalState(() {
                _qrData = SecureQrService.generateSecureQrData(widget.member.matricule);
              });
            } else {
              timer.cancel();
            }
          });

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 60),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Text(
                        'PASS D\'ACCÈS PERSONNEL',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(48),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 40),
                      Text(
                        widget.member.matricule,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SÉCURISÉ • MISE À JOUR EN TEMPS RÉEL',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white24,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: IconButton(
                    onPressed: () {
                      innerTimer?.cancel();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.4),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 1.0, end: 0, duration: 450.ms, curve: Curves.easeOutQuart);
        }
      ),
    ).whenComplete(() {
      _qrUpdateTimer?.cancel();
    });
  }

  Widget _buildModalCloseButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          'FERMER',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'fr');
    return formatter.format(date);
  }
}

