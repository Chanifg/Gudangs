import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Custom Color Palette from Stitch
  static const Color primaryGreen = Color(0x006E2F); // Custom 0xFF006E2F
  static const Color emeraldGreen = Color(0xFF22C55E);
  static const Color darkNavy = Color(0xFF0B1C30);
  static const Color slateGrey = Color(0xFF565E74);
  static const Color lightIceBlue = Color(0xFFF8F9FF);
  static const Color softBlueGray = Color(0xFFEFF4FF);
  static const Color borderGray = Color(0xFFBCCBB9);
  static const Color errorRed = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF006E2F), // Ensure it is fully opaque
        onPrimary: Colors.white,
        primaryContainer: emeraldGreen,
        onPrimaryContainer: Color(0xFF004B1E),
        secondary: slateGrey,
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        background: lightIceBlue,
        onBackground: darkNavy,
        surface: lightIceBlue,
        onSurface: darkNavy,
        surfaceVariant: Color(0xFFD3E4FE),
        onSurfaceVariant: Color(0xFF3D4A3D),
        outline: Color(0xFF6D7B6C),
        outlineVariant: borderGray,
      ),
      scaffoldBackgroundColor: lightIceBlue,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.02, color: darkNavy),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.01, color: darkNavy),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.semibold, color: darkNavy),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.semibold, color: darkNavy),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.semibold, color: darkNavy),
          bodyLarge: TextStyle(fontSize: 16, color: darkNavy),
          bodyMedium: TextStyle(fontSize: 14, color: darkNavy),
          bodySmall: TextStyle(fontSize: 12, color: slateGrey),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkNavy),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.05, color: slateGrey),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: slateGrey),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkNavy),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: slateGrey),
        hintStyle: const TextStyle(color: slateGrey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006E2F),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: emeraldGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF006E2F),
        unselectedItemColor: slateGrey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
