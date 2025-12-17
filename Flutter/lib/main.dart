import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← TAMBAHKAN INI

import 'screens/intro_splash.dart';
import 'login_page.dart';
import 'riwayat_page.dart';
import 'detail_riwayat_page.dart';
import 'trip_simulation_page.dart';
import 'hitung_emisi_page.dart';
import 'detail_emisi_page.dart';

void main() async { // ← TAMBAHKAN async
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ INISIALISASI LOCALE INDONESIA (TAMBAHKAN INI)
  await initializeDateFormatting('id_ID', null);
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ITransecApp());
}

class ITransecApp extends StatelessWidget {
  const ITransecApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme dasar
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF22C55E),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'I-TransEC',
      theme: base.copyWith(
        // 🔤 Semua text default pakai Poppins
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),

        // 🔝 AppBar biar konsisten
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // Tombol Elevated default
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Optional: Card/Chip dsb bisa ikut colorScheme
      ),
      home: const IntroSplash(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/simulate': (context) => const TripSimWithMapPage(),
        '/riwayat': (context) => const RiwayatPage(),
        // kalau mau, bisa tambahin:
        // '/hitung-emisi': (context) => const HitungEmisiPage(),
      },
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
    );
  }
}