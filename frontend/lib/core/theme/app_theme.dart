import 'package:flutter/material.dart';

/// IUB PAY — Futuristic / Cyber-Neon palette
class AppColors {
  // Backgrounds
  static const bgDeep = Color(0xFF070A14);
  static const bgMid = Color(0xFF0F1430);
  static const bgSurface = Color(0xFF141A3A);
  static const bgCard = Color(0xFF1A2150);
  static const bgCardHover = Color(0xFF1E285E);

  // Neon accents
  static const neonCyan = Color(0xFF00E5FF);
  static const neonCyanDim = Color(0xFF00B8D4);
  static const neonPurple = Color(0xFF7C4DFF);
  static const neonPink = Color(0xFFFF2E93);
  static const neonGreen = Color(0xFF00E676);
  static const neonAmber = Color(0xFFFFAB00);
  static const neonRed = Color(0xFFFF3D57);

  // Text
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8B92B8);
  static const textTertiary = Color(0xFF5A628A);

  // Glass / borders
  static const glassBorder = Color(0x1AFFFFFF);
  static const glassFill = Color(0x12FFFFFF);

  static const divider = Color(0x14FFFFFF);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cardGradient = LinearGradient(
    colors: [Color(0xFF1C2450), Color(0xFF151B3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const bgGradient = LinearGradient(
    colors: [bgDeep, Color(0xFF0D1025), bgMid],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const cyanGlow = LinearGradient(
    colors: [Color(0x3300E5FF), Color(0x007C4DFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const purpleGlow = LinearGradient(
    colors: [Color(0x337C4DFF), Color(0x00FF2E93)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData futuristicDark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonCyan,
      primary: AppColors.neonCyan,
      secondary: AppColors.neonPurple,
      tertiary: AppColors.neonPink,
      brightness: Brightness.dark,
      surface: AppColors.bgSurface,
      error: AppColors.neonRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgDeep,
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.bgCard.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.bgDeep,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: AppColors.neonCyan.withOpacity(0.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.glassBorder, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.4),
        ),
        filled: true,
        fillColor: AppColors.bgCard.withOpacity(0.6),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgCard,
        side: const BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: -1),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  // Keep light() for compat — forwards to futuristicDark
  static ThemeData light() => futuristicDark();
}
