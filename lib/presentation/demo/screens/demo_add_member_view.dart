import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/member_account.dart';
import '../../../data/repositories/member_repository.dart';
import '../widgets/member_pass_card.dart';
import '../utils/demo_utils.dart';

class DemoAddMemberView extends StatefulWidget {
  final MemberRepository memberRepository;
  final String? inscritPar;

  const DemoAddMemberView({super.key, required this.memberRepository, this.inscritPar});

  @override
  State<DemoAddMemberView> createState() => _DemoAddMemberViewState();
}

class _DemoAddMemberViewState extends State<DemoAddMemberView> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _passKey = GlobalKey();
  bool _isSaving = false;
  
  final TextEditingController _nomsController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  
  String _selectedActivity = 'CROSSFIT';
  String _selectedDuration = '1 mois';
  bool _avecCoach = false;

  final List<String> _activities = ['CROSSFIT', 'BOXE', 'ZUMBA / AÉRO'];
  
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

  Future<void> _saveAndShowPass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final nextMatricule = await widget.memberRepository.generateNextMatricule();
      
      final newMember = MemberAccount.fromPricing(
        matricule: nextMatricule,
        noms: _nomsController.text.trim(),
        telephone: '+243 ${_telephoneController.text.trim()}',
        role: 'membre',
        activite: _selectedActivity,
        dureeForfait: _selectedDuration,
        avecCoach: _avecCoach,
        dateDebut: DateTime.now(),
        inscritPar: widget.inscritPar,
      );

      await widget.memberRepository.saveMemberAccount(newMember);

      if (mounted) {
        _showPassDialog(newMember);
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
                    Navigator.pop(context);
                    Navigator.pop(context);
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
        title: Text('NOUVELLE INSCRIPTION', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
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
              _buildSectionTitle('IDENTITÉ'),
              const SizedBox(height: 16),
              _buildTextField(_nomsController, 'Nom Complet', Icons.person_outline),
              const SizedBox(height: 20),
              _buildPhoneField(_telephoneController, 'Téléphone', Icons.phone_outlined),
              
              const SizedBox(height: 40),
              _buildSectionTitle('FORFAIT'),
              const SizedBox(height: 16),
              _buildDropdown('Activité', _selectedActivity, _activities, (v) {
                setState(() {
                  _selectedActivity = v!;
                  // Reset duration if not available for the new activity
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
                  onPressed: _isSaving ? null : _saveAndShowPass,
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('ENREGISTRER ET GÉNÉRER LE PASS'),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white38),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
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

  Widget _buildPhoneField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 9,
      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 2),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white38, letterSpacing: 0),
        prefixIcon: Icon(icon, color: Colors.white38),
        prefixText: '+243 ',
        prefixStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
        counterText: '',
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
      validator: (v) => v == null || v.trim().length != 9 ? 'Le numéro doit avoir 9 chiffres' : null,
    );
  }
}
