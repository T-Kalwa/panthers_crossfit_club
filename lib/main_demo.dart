import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'data/services/hive_service.dart';
import 'data/services/demo_auth_service.dart';
import 'data/repositories/member_repository.dart';
import 'presentation/demo/screens/demo_login_screen.dart';
import 'presentation/demo/screens/demo_admin_dashboard.dart';
import 'presentation/demo/screens/demo_staff_home.dart';
import 'presentation/demo/screens/demo_scan_only_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr', null);
  
  try {
    await HiveService.init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Init Error: $e");
  }

  final memberRepository = MemberRepository();

  // Seed initial accounts (no-op if already exist)
  await DemoAuthService.seedAccounts();

  // Load persisted session
  final initialUser = await DemoAuthService.loadSession();

  runApp(PanthersDemoApp(memberRepository: memberRepository, initialUser: initialUser));
}

class PanthersDemoApp extends StatelessWidget {
  final MemberRepository memberRepository;
  final DemoAuthUser? initialUser;

  const PanthersDemoApp({super.key, required this.memberRepository, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panthers Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
          primary: Colors.white,
          surface: const Color(0xFF121212),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
      ),
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (initialUser == null) {
      return DemoLoginScreen(memberRepository: memberRepository);
    }
    
    switch (initialUser!.role) {
      case DemoUserRole.superAdmin:
        return DemoAdminDashboard(memberRepository: memberRepository, currentUser: initialUser!);
      case DemoUserRole.staff:
        return DemoStaffHome(memberRepository: memberRepository, currentUser: initialUser!);
      case DemoUserRole.scan:
        return DemoScanOnlyScreen(memberRepository: memberRepository);
      default:
        return DemoLoginScreen(memberRepository: memberRepository);
    }
  }
}
