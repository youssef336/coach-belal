import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Coach Belal palette: near-black ground, lime energy, orange fire.
abstract final class AppColors {
  static const bg = Color(0xFF0B0F14);
  static const surface = Color(0xFF141B23);
  static const surface2 = Color(0xFF1C2530);
  static const lime = Color(0xFFC6FF3D);
  static const orange = Color(0xFFFF8A3D);
  static const sky = Color(0xFF5EC8FF);
  static const text = Color(0xFFF2F5F7);
  static const muted = Color(0xFF9AA7B5);
  static const line = Color(0x14FFFFFF);
  static const danger = Color(0xFFFF5A5A);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lime,
      onPrimary: AppColors.bg,
      secondary: AppColors.orange,
      onSecondary: AppColors.bg,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
  );
  final font = GoogleFonts.cairo().fontFamily;
  final text = base.textTheme.apply(fontFamily: font, bodyColor: AppColors.text, displayColor: AppColors.text);
  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.lime.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? AppColors.lime : AppColors.muted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surface2,
      contentTextStyle: GoogleFonts.cairo(color: AppColors.text),
    ),
  );
}
