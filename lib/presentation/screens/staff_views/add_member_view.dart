import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/member_account.dart';
import '../../../domain/logic/panthers_pricing.dart';
import '../../../data/repositories/member_repository.dart';

class AddMemberView extends StatefulWidget {
  final MemberRepository memberRepository;
  final MemberAccount staffMember;
  final MemberAccount? memberToEdit;
  final VoidCallback? onSave;

  const AddMemberView({
    super.key, 
    required this.memberRepository,
    required this.staffMember,
    this.memberToEdit,
    this.onSave,
  });

  @override
  State<AddMemberView> createState() => _AddMemberViewState();
}

class _AddMemberViewState extends State<AddMemberView> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingMatricule = false;
  
  late final TextEditingController _matriculeController;
  late final TextEditingController _nomsController;
  late final TextEditingController _telephoneController;
  
  late String _selectedRole;
  late String _selectedActivity;
  late String _selectedDuration;
  late bool _avecCoach;
  late DateTime _dateDebut;

  final List<String> _roles = ['membre', 'staff', 'superAdmin'];
  late final List<String> _activities;
  late final List<String> _paymentMethods;
  late String _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    final edit = widget.memberToEdit;
    _matriculeController = TextEditingController(text: edit?.matricule ?? '');
    _nomsController = TextEditingController(text: edit?.noms ?? '');
    _telephoneController = TextEditingController(text: edit?.telephone ?? '+243');
    _selectedRole = edit?.role ?? 'membre';
    
    _activities = ['CROSSFIT', 'BOXE', 'ZUMBA / AÉRO'];
    _selectedActivity = edit?.activite ?? 'CROSSFIT';
    
    _selectedDuration = edit?.dureeForfait ?? _getDurations().first;
    _avecCoach = edit?.avecCoach ?? false;
    _dateDebut = edit?.dateDebut ?? DateTime.now();
    
    _paymentMethods = ['Airtel Money', 'Orange Money', 'Espèces', 'Autre'];
    _selectedPaymentMethod = edit?.methodePaiement ?? 'Espèces';

    if (edit == null) {
      _generateMatricule();
    }
  }

  Future<void> _generateMatricule() async {
    setState(() => _isLoadingMatricule = true);
    try {
      final nextMatricule = await widget.memberRepository.generateNextMatricule();
      if (mounted) {
        _matriculeController.text = nextMatricule;
      }
    } finally {
      if (mounted) setState(() => _isLoadingMatricule = false);
    }
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _nomsController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }
  
  List<String> _getDurations() {
    if (_selectedActivity == 'CROSSFIT') {
      return ['1 séance', '10 jours', '1 mois', '3 mois', '6 mois', 'annuel'];
    } else if (_selectedActivity == 'BOXE') {
      return ['1 séance', '1 mois', '3 mois', '6 mois'];
    } else if (_selectedActivity == 'ZUMBA / AÉRO') {
      return ['1 séance', '1 mois'];
    } else {
      // Pour les activités spéciales (ex: ADMINISTRATION), on garde la durée actuelle si dispo
      if (widget.memberToEdit != null && widget.memberToEdit!.activite == _selectedActivity) {
        return [widget.memberToEdit!.dureeForfait];
      }
      return ['illimité'];
    }
  }

  PlanDetails get _currentPlan {
    return PanthersPricing.getPlanDetails(_selectedActivity, _selectedDuration, _avecCoach);
  }

  DateTime get _calculatedDateFin {
    return PanthersPricing.calculateExpiryDate(_dateDebut, _currentPlan.days);
  }

  void _saveMember() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final newMember = MemberAccount.fromPricing(
        matricule: _matriculeController.text.trim(),
        noms: _nomsController.text.trim(),
        telephone: _telephoneController.text.trim(),
        role: _selectedRole,
        activite: _selectedActivity,
        dureeForfait: _selectedDuration,
        avecCoach: _avecCoach,
        dateDebut: _dateDebut,
        methodePaiement: _selectedPaymentMethod,
        inscritPar: widget.staffMember.matricule,
      );

      try {
        await widget.memberRepository.saveMemberAccount(newMember);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newMember.noms} ${widget.memberToEdit != null ? 'mis à jour' : 'ajouté'} avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          
          if (widget.onSave != null) {
            widget.onSave!();
          } else {
            _matriculeController.clear();
            _nomsController.clear();
            _telephoneController.clear();
             setState(() {
              _dateDebut = DateTime.now();
            });
            _generateMatricule(); // Generate new one for next member
          }
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 20 : 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(isSmall ? 24 : 40),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                       if (isSmall) ...[
                        _buildTextField(
                          _matriculeController, 
                          'Matricule', 
                          Icons.badge_outlined, 
                          enabled: false, // Always disabled to avoid errors, pre-filled automatically
                          isLoading: _isLoadingMatricule,
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(_nomsController, 'Nom et Prénom', Icons.person_outline),
                      ] else
                         Row(
                          children: [
                            Expanded(child: _buildTextField(
                              _matriculeController, 
                              'Matricule', 
                              Icons.badge_outlined, 
                              enabled: false,
                              isLoading: _isLoadingMatricule,
                            )),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField(_nomsController, 'Nom et Prénom', Icons.person_outline)),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _buildTextField(_telephoneController, 'Téléphone', Icons.phone_outlined, keyboardType: TextInputType.phone),
                      const SizedBox(height: 32),
                      if (isSmall) ...[
                        _buildDropdown(
                          'Rôle', 
                          _selectedRole, 
                          _roles, 
                          widget.staffMember.role == 'superAdmin' ? (val) => setState(() => _selectedRole = val!) : null
                        ),
                        const SizedBox(height: 24),
                        _buildDropdown('Activité', _selectedActivity, _activities, (val) => setState(() {
                          _selectedActivity = val!;
                          if (!_getDurations().contains(_selectedDuration)) {
                            _selectedDuration = _getDurations().first;
                          }
                        })),
                      ] else
                        Row(
                          children: [
                            Expanded(child: _buildDropdown(
                              'Rôle', 
                              _selectedRole, 
                              _roles, 
                              widget.staffMember.role == 'superAdmin' ? (val) => setState(() => _selectedRole = val!) : null
                            )),
                            const SizedBox(width: 24),
                            Expanded(child: _buildDropdown('Activité', _selectedActivity, _activities, (val) => setState(() {
                              _selectedActivity = val!;
                              if (!_getDurations().contains(_selectedDuration)) {
                                _selectedDuration = _getDurations().first;
                              }
                            }))),
                          ],
                        ),
                      const SizedBox(height: 24),
                      if (isSmall) ...[
                        _buildDropdown('Forfait', _selectedDuration, _getDurations(), (val) => setState(() => _selectedDuration = val!)),
                        if (_selectedActivity == 'CROSSFIT') ...[
                          const SizedBox(height: 24),
                          _buildCoachToggle(),
                        ],
                      ] else
                        Row(
                          children: [
                            Expanded(child: _buildDropdown('Forfait', _selectedDuration, _getDurations(), (val) => setState(() => _selectedDuration = val!))),
                            if (_selectedActivity == 'CROSSFIT') ...[
                              const SizedBox(width: 24),
                              Expanded(child: _buildCoachToggle()),
                            ],
                          ],
                        ),
                      const SizedBox(height: 24),
                      _buildDropdown('Mode de Paiement', _selectedPaymentMethod, _paymentMethods, (val) => setState(() => _selectedPaymentMethod = val!)),
                      SizedBox(height: isSmall ? 32 : 48),
                      _buildPricingSummary(isSmall),
                      SizedBox(height: isSmall ? 32 : 48),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

   Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    TextInputType? keyboardType, 
    bool enabled = true,
    bool isLoading = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      readOnly: !enabled, // Ensure it's read only if not enabled
      style: GoogleFonts.outfit(color: (enabled || controller.text.isNotEmpty) ? Colors.white : Colors.white24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: isLoading ? const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
        ) : (!enabled && controller.text.isNotEmpty ? const Icon(Icons.auto_fix_high_rounded, color: Colors.white10, size: 16) : null),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white24)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?)? onChanged) {
    bool enabled = onChanged != null;
    
    // Sécurité critique : On s'assure que la valeur actuelle est RÉELLEMENT présente dans la liste des items
    // pour éviter l'erreur "Assertion failed: items.where(...).length == 1" si une valeur orpheline arrive (ex: ADMINISTRATION)
    final List<String> safeItems = List<String>.from(items);
    if (value.isNotEmpty && !safeItems.contains(value)) {
      safeItems.add(value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: enabled ? Colors.white38 : Colors.white10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(enabled ? 0.04 : 0.01),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(enabled ? 0.08 : 0.02)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              disabledHint: Text(value, style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.bold)),
              dropdownColor: const Color(0xFF151515),
              style: GoogleFonts.outfit(color: enabled ? Colors.white : Colors.white38, fontWeight: FontWeight.bold),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: enabled ? Colors.white38 : Colors.white12),
              items: safeItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COACH', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 4),
        Switch(
          value: _avecCoach,
          activeColor: Colors.white,
          activeTrackColor: Colors.white24,
          onChanged: (val) => setState(() => _avecCoach = val),
        ),
      ],
    );
  }

  Widget _buildPricingSummary(bool isSmall) {
    final plan = _currentPlan;
    final dateFin = _calculatedDateFin;

    return Container(
      padding: EdgeInsets.all(isSmall ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(isSmall ? 20 : 32),
      ),
      child: Column(
        children: [
          if (isSmall) ...[
            Text('MONTANT À PAYER', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('${plan.price}\$', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MONTANT À PAYER', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text('${plan.price}\$', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 24),
          _buildDetailRow('Date de début', DateFormat('dd/MM/yyyy').format(_dateDebut)),
          _buildDetailRow('Date d\'expiration', DateFormat('dd/MM/yyyy').format(dateFin), isHighlight: true),
          _buildDetailRow('Description', plan.description),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontWeight: FontWeight.bold)),
          Text(
            value, 
            style: GoogleFonts.outfit(
              color: isHighlight ? Colors.white : Colors.white70, 
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveMember,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: _isSaving 
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(
              widget.memberToEdit != null ? 'METTRE À JOUR LE MEMBRE' : 'ENREGISTRER LE MEMBRE',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
      ),
    );
  }
}
