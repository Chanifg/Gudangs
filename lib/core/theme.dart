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
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkNavy),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkNavy),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkNavy),
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
      cardTheme: CardThemeData(
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

  static ThemeData get darkTheme {
    const Color darkBg = Color(0xFF0F172A); // Slate 900
    const Color darkSurface = Color(0xFF1E293B); // Slate 800
    const Color darkCard = Color(0xFF1E293B);
    const Color darkOnSurface = Color(0xFFF8FAFC); // Slate 50
    const Color darkOnBackground = Color(0xFFE2E8F0); // Slate 200
    const Color darkInputFill = Color(0xFF0F172A);
    const Color darkBorder = Color(0xFF334155); // Slate 700

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF22C55E), // Emerald Green
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF15803D),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFF94A3B8), // Slate 400
        onSecondary: Colors.black,
        error: errorRed,
        onError: Colors.white,
        background: darkBg,
        onBackground: darkOnBackground,
        surface: darkSurface,
        onSurface: darkOnSurface,
        surfaceVariant: Color(0xFF334155),
        onSurfaceVariant: Color(0xFFCBD5E1),
        outline: Color(0xFF64748B),
        outlineVariant: darkBorder,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.02, color: darkOnSurface),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.01, color: darkOnSurface),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkOnSurface),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkOnSurface),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkOnSurface),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkOnSurface),
          bodyLarge: TextStyle(fontSize: 16, color: darkOnBackground),
          bodyMedium: TextStyle(fontSize: 14, color: darkOnBackground),
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkOnSurface),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.05, color: Color(0xFF94A3B8)),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkOnSurface,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkOnSurface),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBg,
        selectedItemColor: Color(0xFF22C55E),
        unselectedItemColor: Color(0xFF94A3B8),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
