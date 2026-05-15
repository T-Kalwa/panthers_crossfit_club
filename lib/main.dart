import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart';
import 'presentation/screens/splash_screen.dart';
import 'data/repositories/member_repository.dart';
import 'data/services/hive_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'domain/models/member_account.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up a fail-safe for initialization
  bool hiveReady = false;
  bool firebaseReady = false;

  try {
    // 1. Hive is critical for offline mode
    await HiveService.init().timeout(const Duration(seconds: 10));
    hiveReady = true;
    debugPrint("✅ Hive initialisé");
  } catch (e) {
    debugPrint("❌ Erreur Hive: $e");
  }

  try {
    // 2. Firebase initialization with timeout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // 3. Silent Anonymous Auth for Security Rules
    try {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint(
        "✅ Authentification anonyme réussie (UID: ${FirebaseAuth.instance.currentUser?.uid})",
      );
    } catch (authError) {
      debugPrint("⚠️ Auth anonyme impossible : $authError");
    }

    firebaseReady = true;
    debugPrint("✅ Firebase initialisé");

    // 4. Auto-restauration du compte ADMIN (si manquant)
    final repo = MemberRepository();
    final admin = await repo.getMemberAccountByMatricule('ADMIN');
    if (admin == null) {
      final now = DateTime.now();
      await repo.saveMemberAccount(MemberAccount(
        matricule: 'ADMIN',
        noms: 'PANTHERS SUPER ADMIN',
        telephone: '000000',
        role: 'superAdmin',
        activite: 'ADMINISTRATION',
        dureeForfait: 'ILLIMITÉ',
        avecCoach: false,
        montantPaye: 0,
        dateDebut: now,
        dateFin: now.add(const Duration(days: 36500)),
        isActive: true,
      ));
      debugPrint("👑 Compte ADMIN restauré");
    }

  } catch (e) {
    debugPrint("⚠️ Firebase non disponible (Offline?): $e");
  }

  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('fr_FR', null);

  final memberRepository = MemberRepository();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      backgroundColor: const Color(0xFF000000),
      builder: (context) => PanthersApp(
        memberRepository: memberRepository,
        isHiveReady: hiveReady,
        isFirebaseReady: firebaseReady,
      ),
    ),
  );
}

class PanthersApp extends StatelessWidget {
  final MemberRepository memberRepository;
  final bool isHiveReady;
  final bool isFirebaseReady;

  const PanthersApp({
    super.key,
    required this.memberRepository,
    this.isHiveReady = true,
    this.isFirebaseReady = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Panthers CrossFit Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          primary: Colors.white,
          secondary: Colors.white70,
          brightness: Brightness.dark,
          surface: const Color(0xFF0F0F0F),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
            .copyWith(
              displayLarge: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              displayMedium: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              bodyLarge: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w300,
              ),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          labelStyle: GoogleFonts.outfit(color: Colors.white70),
          hintStyle: GoogleFonts.outfit(color: Colors.white24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 8,
            shadowColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
      home: isHiveReady
          ? SplashScreen(memberRepository: memberRepository)
          : Scaffold(
              body: Center(
                child: Text(
                  "Erreur d'initialisation locale.\nVeuillez redémarrer l'application.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
              ),
            ),
    );
  }
}
