import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/demo_auth_service.dart';
import '../../../data/repositories/member_repository.dart';
import 'demo_staff_home.dart';
import 'demo_admin_dashboard.dart';
import 'demo_scan_only_screen.dart';

class DemoLoginScreen extends StatefulWidget {
  final MemberRepository memberRepository;

  const DemoLoginScreen({super.key, required this.memberRepository});

  @override
  State<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends State<DemoLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isAdminMode = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _loginStaff() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final phone = '+243 ${_phoneController.text.trim()}';
      final user = await DemoAuthService.loginByPhone(phone);

      if (user == null) {
        setState(() => _errorMessage = 'Aucun compte staff trouvé avec ce numéro.');
        return;
      }

      if (!mounted) return;
      _routeByRole(user);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final user = await DemoAuthService.loginAdmin(
        _emailController.text,
        _passwordController.text,
      );

      if (user == null) {
        setState(() => _errorMessage = 'Email ou mot de passe incorrect.');
        return;
      }

      if (!mounted) return;
      _routeByRole(user);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _routeByRole(DemoAuthUser user) {
    Widget destination;
    switch (user.role) {
      case DemoUserRole.superAdmin:
        destination = DemoAdminDashboard(
          memberRepository: widget.memberRepository,
          currentUser: user,
        );
        break;
      case DemoUserRole.staff:
        destination = DemoStaffHome(
          memberRepository: widget.memberRepository,
          currentUser: user,
        );
        break;
      case DemoUserRole.scan:
        destination = DemoScanOnlyScreen(
          memberRepository: widget.memberRepository,
        );
        break;
      default:
        setState(() => _errorMessage = 'Rôle non reconnu.');
        return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo2.png',
                  height: 100,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'PANTHERS',
                  style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.white),
                ),
                Text(
                  'CROSSFIT CLUB',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 4, color: Colors.white38),
                ),
                const SizedBox(height: 60),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: _isAdminMode ? _buildAdminFields() : _buildStaffFields(),
                  ),
                ),

                // Error
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_errorMessage!, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 14))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_isAdminMode ? _loginAdmin : _loginStaff),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : Text(
                            'SE CONNECTER',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Toggle admin mode
                TextButton(
                  onPressed: () => setState(() {
                    _isAdminMode = !_isAdminMode;
                    _errorMessage = null;
                  }),
                  child: Text(
                    _isAdminMode ? '← CONNEXION STAFF' : 'CONNEXION ADMIN →',
                    style: GoogleFonts.outfit(
                      color: _isAdminMode ? Colors.amber.withOpacity(0.5) : Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Text('© 2026 Panthers CrossFit Club', style: GoogleFonts.outfit(color: Colors.white12, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStaffFields() {
    return [
      Text(
        'CONNEXION STAFF',
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 3),
      ),
      const SizedBox(height: 24),
      _buildPhoneField(
        controller: _phoneController,
        label: 'Numéro de téléphone',
        icon: Icons.phone_rounded,
      ),
    ];
  }

  List<Widget> _buildAdminFields() {
    return [
      Text(
        'CONNEXION ADMIN',
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.amber.withOpacity(0.6), fontWeight: FontWeight.w900, letterSpacing: 3),
      ),
      const SizedBox(height: 24),
      _buildField(
        controller: _emailController,
        label: 'Email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
      ),
      const SizedBox(height: 20),
      _buildField(
        controller: _passwordController,
        label: 'Mot de passe',
        icon: Icons.lock_outline_rounded,
        obscureText: _obscurePassword,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        validator: (v) => v == null || v.length < 6 ? 'Mot de passe trop court' : null,
      ),
    ];
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: (v) => v == null || v.trim().length != 9 ? 'Le numéro doit avoir 9 chiffres' : null,
    );
  }
}
