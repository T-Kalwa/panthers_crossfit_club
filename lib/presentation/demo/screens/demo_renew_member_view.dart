import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/member_account.dart';
import '../../../data/repositories/member_repository.dart';
import '../widgets/member_pass_card.dart';
import '../utils/demo_utils.dart';

class DemoRenewMemberView extends StatefulWidget {
  final MemberRepository memberRepository;
  final MemberAccount member;

  const DemoRenewMemberView({super.key, required this.memberRepository, required this.member});

  @override
  State<DemoRenewMemberView> createState() => _DemoRenewMemberViewState();
}

class _DemoRenewMemberViewState extends State<DemoRenewMemberView> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _passKey = GlobalKey();
  bool _isSaving = false;
  
  late String _selectedActivity;
  late String _selectedDuration;
  late bool _avecCoach;

  final List<String> _activities = ['CROSSFIT', 'BOXE', 'ZUMBA / AÉRO'];

  @override
  void initState() {
    super.initState();
    // Normalize activity to known values — prevents crash for legacy values like 'ADMINISTRATION'
    const knownActivities = ['CROSSFIT', 'BOXE', 'ZUMBA / AÉRO'];
    _selectedActivity = knownActivities.contains(widget.member.activite)
        ? widget.member.activite
        : 'CROSSFIT';
    
    final available = _getAvailableDurations();
    _selectedDuration = available.contains(widget.member.dureeForfait)
        ? widget.member.dureeForfait
        : available.first;
    _avecCoach = widget.member.avecCoach;
  }

  List<String> _getAvailableDurations() {
    switch (_selectedActivity) {
      case 'BOXE':
        return ['1 séance', '1 mois', '3 mois', '6 mois'];
      case 'ZUMBA / AÉRO':
        return ['1 séance', '1 mois'];
      case 'CROSSFIT':
      default:
        return ['1 séance', '10 jours', '1 mois', '3 mois', '6 mois', 'annuel'];
    }
  }

  Future<void> _renewAndShowPass() async {
    setState(() => _isSaving = true);

    try {
      // Logic for renewal: 
      // If still active, start from dateFin. If expired, start from now.
      final now = DateTime.now();
      final startDate = widget.member.dateFin.isAfter(now) ? widget.member.dateFin : now;

      final updatedMember = MemberAccount.fromPricing(
        matricule: widget.member.matricule,
        noms: widget.member.noms,
        telephone: widget.member.telephone,
        role: widget.member.role,
        activite: _selectedActivity,
        dureeForfait: _selectedDuration,
        avecCoach: _avecCoach,
        dateDebut: startDate,
        profileImageUrl: widget.member.profileImageUrl,
      );

      await widget.memberRepository.saveMemberAccount(updatedMember);

      if (mounted) {
        _showPassDialog(updatedMember);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPassDialog(MemberAccount member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _passKey,
              child: MemberPassCard(member: member),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionIcon(
                  icon: Icons.share_rounded,
                  color: Colors.blueAccent,
                  onTap: () => DemoUtils.shareWidgetAsImage(_passKey, 'pass_${member.matricule}'),
                ),
                const SizedBox(width: 20),
                _buildActionIcon(
                  icon: Icons.download_rounded,
                  color: Colors.greenAccent,
                  onTap: () async {
                    final success = await DemoUtils.saveToGallery(_passKey, 'pass_${member.matricule}');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Enregistré !' : 'Erreur'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 20),
                _buildActionIcon(
                  icon: Icons.close_rounded,
                  color: Colors.white24,
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close renew view
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RÉABONNEMENT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('MEMBRE'),
              const SizedBox(height: 16),
              Text(
                widget.member.noms,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Matricule: ${widget.member.matricule}',
                style: GoogleFonts.outfit(color: Colors.white38),
              ),
              
              const SizedBox(height: 40),
              _buildSectionTitle('NOUVEAU FORFAIT'),
              const SizedBox(height: 16),
              _buildDropdown('Activité', _selectedActivity, _activities, (v) {
                setState(() {
                  _selectedActivity = v!;
                  final available = _getAvailableDurations();
                  if (!available.contains(_selectedDuration)) {
                    _selectedDuration = available.first;
                  }
                });
              }),
              const SizedBox(height: 20),
              _buildDropdown('Durée', _selectedDuration, _getAvailableDurations(), (v) => setState(() => _selectedDuration = v!)),
              const SizedBox(height: 20),
              if (_selectedActivity == 'CROSSFIT')
                SwitchListTile(
                  title: Text('AVEC COACH', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  value: _avecCoach,
                  onChanged: (v) => setState(() => _avecCoach = v),
                  activeColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                ),
              
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _renewAndShowPass,
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('ACTIVER LE NOUVEAU PASS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.white38,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    final List<String> safeItems = List<String>.from(items);
    if (value.isNotEmpty && !safeItems.contains(value)) {
      safeItems.add(value);
    }
    return DropdownButtonFormField<String>(
      value: value,
      items: safeItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}
