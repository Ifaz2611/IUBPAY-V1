import 'package:flutter/material.dart';

/// IUB PAY — Calm campus-fintech design tokens.
/// Restrained palette, solid surfaces, subtle elevation.

class AppColors {
  // ── Core palette ──
  // Warm neutral canvas
  static const background = Color(0xFFF6F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F0EC);
  static const surfaceHover = Color(0xFFEBE9E5);

  // Borders — low contrast
  static const border = Color(0xFFE8E6E1);
  static const borderStrong = Color(0xFFD9D6D0);

  // Text — near-black hierarchy
  static const textPrimary = Color(0xFF14181F);
  static const textSecondary = Color(0xFF5E6166);
  static const textTertiary = Color(0xFF8A8D93);
  static const textInverse = Color(0xFFFFFFFF);

  // Brand — single confident accent (deep teal-green, trustworthy)
  static const brand = Color(0xFF0F5B4A);
  static const brandHover = Color(0xFF0D4E3F);
  static const brandPressed = Color(0xFF0A4235);
  static const brandSubtle = Color(0xFFEEF6F3); // tint for selected/filter states

  // Secondary accent — warm amber for "awaiting / attention" (sparingly)
  static const accentAmber = Color(0xFF9A5B11);
  static const accentAmberBg = Color(0xFFFFF7ED);

  // Semantic
  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFF0FDF4);
  static const successBorder = Color(0xFFBBF7D0);

  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFFFBEB);

  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFECACA);

  static const info = Color(0xFF0E7490);
  static const infoBg = Color(0xFFECFEFF);

  // Legacy aliases — kept for incremental migration, mapped to new tokens
  @Deprecated('Use AppColors.brand instead')
  static const neonCyan = brand;
  @Deprecated('Use AppColors.brand instead')
  static const neonPurple = brand;
  @Deprecated('Use AppColors.warning instead')
  static const neonPink = warning;
  @Deprecated('Use AppColors.success instead')
  static const neonGreen = success;
  @Deprecated('Use AppColors.warning instead')
  static const neonAmber = warning;
  @Deprecated('Use AppColors.error instead')
  static const neonRed = error;

  static const textTertiaryLegacy = textTertiary;
  static const glassBorder = border;
  static const glassFill = surfaceMuted;
  static const divider = border;
  static const bgDeep = background;
  static const bgMid = surfaceMuted;
  static const bgSurface = surface;
  static const bgCard = surface;
  static const bgCardHover = surfaceHover;

  // Deprecated gradients — neutralized
  static const primaryGradient = LinearGradient(colors: [brand, brand]);
  static const cardGradient = LinearGradient(colors: [surface, surfaceMuted]);
  static const bgGradient = LinearGradient(colors: [background, background]);
  static const cyanGlow = LinearGradient(colors: [Colors.transparent, Colors.transparent]);
  static const purpleGlow = LinearGradient(colors: [Colors.transparent, Colors.transparent]);
  static const neonCyanDim = brandHover;
}

/// Spacing scale — use consistently: 4, 8, 12, 16, 24, 32
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii
class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// Soft elevation
class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 1, offset: const Offset(0, 1)),
      ];
  static List<BoxShadow> get cardHover => [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
      ];
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.textSecondary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      // No bundled font file required — platform-safe fallback stack.
      // Flutter resolves the first available family.
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textTertiary.withOpacity(0.12),
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.brand, fontSize: 13, fontWeight: FontWeight.w500),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: false,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        titleTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        contentTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.8, height: 1.1),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.4),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 17, letterSpacing: -0.2),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
      ),
    );
  }

  // Compat: old code called futuristicDark()
  static ThemeData futuristicDark() => light();
}
