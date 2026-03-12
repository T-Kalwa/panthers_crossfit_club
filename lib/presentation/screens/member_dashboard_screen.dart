import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../domain/models/member.dart';
import '../../data/services/hive_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'about_us_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  final Member member;

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
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  void _loadTrackerData() {
    final storedWeekId = _hiveService.getStoredWeekId();
    final currentWeekId = _getWeekId(DateTime.now());

    if (storedWeekId != currentWeekId) {
      _weeklyTracker = List.generate(7, (_) => false);
      _hiveService.saveWeeklyTracker(_weeklyTracker);
      _hiveService.saveWeekId(currentWeekId);
    } else {
      _weeklyTracker = _hiveService.getWeeklyTracker();
    }
    setState(() {});
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
      _hiveService.saveWeeklyTracker(_weeklyTracker);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Background Glow (Subtle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTopNav(context),
                  const SizedBox(height: 20),
                  _buildProgressCircle(),
                  const SizedBox(height: 20),
                  _buildDashboardSlider(),
                  const SizedBox(height: 20),
                  _buildMemberInfo(context),
                  const SizedBox(height: 32),
                  _buildQuickAction(context),
                  const SizedBox(height: 32),
                  _buildDetailCards(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
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
                color: Colors.white54,
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
                  widget.member.nomComplet.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'MEMBRE',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.1),
              backgroundImage: widget.member.profileImageUrl != null ? NetworkImage(widget.member.profileImageUrl!) : null,
              child: widget.member.profileImageUrl == null ? const Icon(Icons.person, color: Colors.white24, size: 20) : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              ),
              icon: const Icon(Icons.info_outline, color: Colors.white70),
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
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: widget.member.expiryProgress,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: Colors.white,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          children: [
            Text(
              '${widget.member.daysRemaining}',
              style: GoogleFonts.outfit(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1,
                color: Colors.white,
              ),
            ),
            Text(
              'JOURS RESTANTS',
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
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
          height: 120,
          child: PageView(
            controller: _sliderController,
            onPageChanged: (index) => setState(() => _currentSlide = index),
            children: [
              _buildClockSlide(),
              _buildWeeklyTrackerSlide(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: _currentSlide == index ? 16 : 6,
            decoration: BoxDecoration(
              color: _currentSlide == index ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(3),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('HH:mm').format(_now),
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              Text(
                DateFormat('EEEE d MMMM', 'fr').format(_now).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'WEEKLY FITNESS TRACKER',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                  letterSpacing: 1.5,
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isValidated ? Colors.white : Colors.transparent,
                            border: Border.all(
                              color: isValidated 
                                  ? Colors.white 
                                  : (isToday ? Colors.white38 : Colors.white10),
                              width: 1.5,
                            ),
                            boxShadow: isValidated ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ] : null,
                          ),
                          child: Center(
                            child: isValidated 
                                ? const Icon(Icons.check, size: 20, color: Colors.black)
                                : (isToday ? const Icon(Icons.fitness_center, size: 14, color: Colors.white24) : null),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[index],
                          style: GoogleFonts.outfit(
                            fontSize: 10,
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

  Widget _buildMemberInfo(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: widget.member.isExpired ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.member.isExpired ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Text(
            widget.member.isExpired ? 'EXPIRÉ' : 'ACTIVE',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.member.isExpired ? Colors.redAccent : Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context) {
    return InkWell(
      onTap: widget.member.isExpired ? null : () => _showQrModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: widget.member.isExpired ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            if (!widget.member.isExpired)
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.member.isExpired ? Icons.lock_outline : Icons.qr_code_2,
              color: widget.member.isExpired ? Colors.white24 : Colors.black,
            ),
            const SizedBox(width: 12),
            Text(
              widget.member.isExpired ? 'ACCÈS BLOQUÉ' : 'SHOW QR CODE',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: widget.member.isExpired ? Colors.white24 : Colors.black,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
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
              Icons.fitness_center_outlined,
            ),
            const SizedBox(width: 16),
            _buildGlassCard(
              'Coaching',
              widget.member.avecCoach ? 'Inclus' : 'Standard',
              Icons.person_pin_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGlassCardFull(
          'Abonnement jusqu\'au',
          _formatDate(widget.member.dateFin),
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Widget _buildGlassCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 40),
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'YOUR ACCESS PASS',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.member.matricule,
                  version: QrVersions.auto,
                  size: 220.0,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.member.matricule,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
