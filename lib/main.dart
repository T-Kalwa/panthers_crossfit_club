import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/screens/splash_screen.dart';
import 'data/repositories/member_repository.dart';
import 'data/services/hive_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await HiveService.init();
  // await Firebase.initializeApp(); // Uncomment when firebase_options.dart is ready
  
  final memberRepository = MemberRepository();
  await memberRepository.seedMockUser();

  runApp(PanthersApp(memberRepository: memberRepository));
}

class PanthersApp extends StatelessWidget {
  final MemberRepository memberRepository;

  const PanthersApp({super.key, required this.memberRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panthers CrossFit Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6D00), // Deep Metallic Orange
          brightness: Brightness.dark,
          primary: const Color(0xFFFF6D00),
          secondary: const Color(0xFFFF9E40),
          surface: const Color(0xFF121212),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.prata(
            fontSize: 48,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.prata(
            fontSize: 32,
            fontWeight: FontWeight.w400,
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
          fillColor: Colors.white.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white38, width: 1),
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white10,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white24),
            ),
            elevation: 0,
            textStyle: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
      home: SplashScreen(memberRepository: memberRepository),
    );
  }
}
