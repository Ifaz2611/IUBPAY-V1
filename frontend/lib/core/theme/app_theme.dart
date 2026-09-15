import 'package:flutter/material.dart';

/// Global theme state used by AppColors getters for legacy code
/// that still uses AppColors.xxx without context.
class AppThemeState {
  static bool isDark = false;
  static void setDark(bool v) => isDark = v;
}

/// IUB PAY — Calm campus-fintech design tokens.
/// Restrained palette, solid surfaces, subtle elevation.

class AppColors {
  // ── Core palette — LIGHT (private) + dynamic getters ──
  static const _backgroundLight = Color(0xFFF6F5F2);
  static Color get background => AppThemeState.isDark ? backgroundDark : _backgroundLight;
  static const _surfaceLight = Color(0xFFFFFFFF);
  static Color get surface => AppThemeState.isDark ? surfaceDark : _surfaceLight;
  static const _surfaceMutedLight = Color(0xFFF1F0EC);
  static Color get surfaceMuted => AppThemeState.isDark ? surfaceMutedDark : _surfaceMutedLight;
  static const _surfaceHoverLight = Color(0xFFEBE9E5);
  static Color get surfaceHover => AppThemeState.isDark ? surfaceHoverDark : _surfaceHoverLight;

  static const _borderLight = Color(0xFFE8E6E1);
  static Color get border => AppThemeState.isDark ? borderDark : _borderLight;
  static const _borderStrongLight = Color(0xFFD9D6D0);
  static Color get borderStrong => AppThemeState.isDark ? borderStrongDark : _borderStrongLight;

  static const _textPrimaryLight = Color(0xFF14181F);
  static Color get textPrimary => AppThemeState.isDark ? textPrimaryDark : _textPrimaryLight;
  static const _textSecondaryLight = Color(0xFF5E6166);
  static Color get textSecondary => AppThemeState.isDark ? textSecondaryDark : _textSecondaryLight;
  static const _textTertiaryLight = Color(0xFF8A8D93);
  static Color get textTertiary => AppThemeState.isDark ? textTertiaryDark : _textTertiaryLight;
  static const _textInverseLight = Color(0xFFFFFFFF);
  static Color get textInverse => AppThemeState.isDark ? textInverseDark : _textInverseLight;

  static const _brandLight = Color(0xFF0F5B4A);
  static Color get brand => AppThemeState.isDark ? brandDark : _brandLight;
  static const _brandHoverLight = Color(0xFF0D4E3F);
  static Color get brandHover => AppThemeState.isDark ? brandHoverDark : _brandHoverLight;
  static const _brandPressedLight = Color(0xFF0A4235);
  static Color get brandPressed => AppThemeState.isDark ? brandPressedDark : _brandPressedLight;
  static const _brandSubtleLight = Color(0xFFEEF6F3);
  static Color get brandSubtle => AppThemeState.isDark ? brandSubtleDark : _brandSubtleLight;

  static const _accentAmberLight = Color(0xFF9A5B11);
  static Color get accentAmber => AppThemeState.isDark ? accentAmberDark : _accentAmberLight;
  static const _accentAmberBgLight = Color(0xFFFFF7ED);
  static Color get accentAmberBg => AppThemeState.isDark ? accentAmberBgDark : _accentAmberBgLight;

  static const _successLight = Color(0xFF15803D);
  static Color get success => AppThemeState.isDark ? successDark : _successLight;
  static const _successBgLight = Color(0xFFF0FDF4);
  static Color get successBg => AppThemeState.isDark ? successBgDark : _successBgLight;
  static const _successBorderLight = Color(0xFFBBF7D0);
  static Color get successBorder => AppThemeState.isDark ? successBorderDark : _successBorderLight;

  static const _warningLight = Color(0xFFB45309);
  static Color get warning => AppThemeState.isDark ? warningDark : _warningLight;
  static const _warningBgLight = Color(0xFFFFFBEB);
  static Color get warningBg => AppThemeState.isDark ? warningBgDark : _warningBgLight;

  static const _errorLight = Color(0xFFDC2626);
  static Color get error => AppThemeState.isDark ? errorDark : _errorLight;
  static const _errorBgLight = Color(0xFFFEF2F2);
  static Color get errorBg => AppThemeState.isDark ? errorBgDark : _errorBgLight;
  static const _errorBorderLight = Color(0xFFFECACA);
  static Color get errorBorder => AppThemeState.isDark ? errorBorderDark : _errorBorderLight;

  static const _infoLight = Color(0xFF0E7490);
  static Color get info => AppThemeState.isDark ? infoDark : _infoLight;
  static const _infoBgLight = Color(0xFFECFEFF);
  static Color get infoBg => AppThemeState.isDark ? infoBgDark : _infoBgLight;

  // ── DARK palette ──
  static const backgroundDark = Color(0xFF121416);
  static const surfaceDark = Color(0xFF1C1E21);
  static const surfaceMutedDark = Color(0xFF25282C);
  static const surfaceHoverDark = Color(0xFF2E3236);

  static const borderDark = Color(0xFF2A2E33);
  static const borderStrongDark = Color(0xFF363A40);

  static const textPrimaryDark = Color(0xFFF1F1F1);
  static const textSecondaryDark = Color(0xFFB0B3B8);
  static const textTertiaryDark = Color(0xFF8A8D93);
  static const textInverseDark = Color(0xFF14181F);

  static const brandDark = Color(0xFF1FAA8A);
  static const brandHoverDark = Color(0xFF1D9A7E);
  static const brandPressedDark = Color(0xFF17806A);
  static const brandSubtleDark = Color(0xFF17302A);

  static const accentAmberDark = Color(0xFFF59E0B);
  static const accentAmberBgDark = Color(0xFF33260A);

  static const successDark = Color(0xFF22C55E);
  static const successBgDark = Color(0xFF16251A);
  static const successBorderDark = Color(0xFF1E3A22);

  static const warningDark = Color(0xFFF59E0B);
  static const warningBgDark = Color(0xFF2A1F0A);

  static const errorDark = Color(0xFFEF4444);
  static const errorBgDark = Color(0xFF2A1515);
  static const errorBorderDark = Color(0xFF4A1E1E);

  static const infoDark = Color(0xFF22D3EE);
  static const infoBgDark = Color(0xFF0F2A30);

  // Legacy aliases — kept for incremental migration, mapped to new tokens
  @Deprecated('Use AppColors.brand instead')
  static const neonCyan = _brandLight;
  @Deprecated('Use AppColors.brand instead')
  static const neonPurple = _brandLight;
  @Deprecated('Use AppColors.warning instead')
  static const neonPink = _warningLight;
  @Deprecated('Use AppColors.success instead')
  static const neonGreen = _successLight;
  @Deprecated('Use AppColors.warning instead')
  static const neonAmber = _warningLight;
  @Deprecated('Use AppColors.error instead')
  static const neonRed = _errorLight;

  static const textTertiaryLegacy = _textTertiaryLight;
  static const glassBorder = _borderLight;
  static const glassFill = _surfaceMutedLight;
  static const divider = _borderLight;
  static const bgDeep = _backgroundLight;
  static const bgMid = _surfaceMutedLight;
  static const bgSurface = _surfaceLight;
  static const bgCard = _surfaceLight;
  static const bgCardHover = _surfaceHoverLight;

  // Deprecated gradients — neutralized
  static const primaryGradient = LinearGradient(colors: [_brandLight, _brandLight]);
  static const cardGradient = LinearGradient(colors: [_surfaceLight, _surfaceMutedLight]);
  static const bgGradient = LinearGradient(colors: [_backgroundLight, _backgroundLight]);
  static const cyanGlow = LinearGradient(colors: [Colors.transparent, Colors.transparent]);
  static const purpleGlow = LinearGradient(colors: [Colors.transparent, Colors.transparent]);
  static const neonCyanDim = _brandHoverLight;

  /// Helper: resolve correct color set based on brightness.
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
}

/// ThemeExtension carrying all tokens so widgets can be brightness-aware
/// without hard-coding AppColors.xxx.
@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceHover;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color brand;
  final Color brandHover;
  final Color brandPressed;
  final Color brandSubtle;
  final Color accentAmber;
  final Color accentAmberBg;
  final Color success;
  final Color successBg;
  final Color successBorder;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color errorBorder;
  final Color info;
  final Color infoBg;

  const AppColorExtension({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceHover,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.brand,
    required this.brandHover,
    required this.brandPressed,
    required this.brandSubtle,
    required this.accentAmber,
    required this.accentAmberBg,
    required this.success,
    required this.successBg,
    required this.successBorder,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.errorBorder,
    required this.info,
    required this.infoBg,
  });

  static const light = AppColorExtension(
    background: Color(0xFFF6F5F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F0EC),
    surfaceHover: Color(0xFFEBE9E5),
    border: Color(0xFFE8E6E1),
    borderStrong: Color(0xFFD9D6D0),
    textPrimary: Color(0xFF14181F),
    textSecondary: Color(0xFF5E6166),
    textTertiary: Color(0xFF8A8D93),
    textInverse: Color(0xFFFFFFFF),
    brand: Color(0xFF0F5B4A),
    brandHover: Color(0xFF0D4E3F),
    brandPressed: Color(0xFF0A4235),
    brandSubtle: Color(0xFFEEF6F3),
    accentAmber: Color(0xFF9A5B11),
    accentAmberBg: Color(0xFFFFF7ED),
    success: Color(0xFF15803D),
    successBg: Color(0xFFF0FDF4),
    successBorder: Color(0xFFBBF7D0),
    warning: Color(0xFFB45309),
    warningBg: Color(0xFFFFFBEB),
    error: Color(0xFFDC2626),
    errorBg: Color(0xFFFEF2F2),
    errorBorder: Color(0xFFFECACA),
    info: Color(0xFF0E7490),
    infoBg: Color(0xFFECFEFF),
  );

  static const dark = AppColorExtension(
    background: Color(0xFF121416),
    surface: Color(0xFF1C1E21),
    surfaceMuted: Color(0xFF25282C),
    surfaceHover: Color(0xFF2E3236),
    border: Color(0xFF2A2E33),
    borderStrong: Color(0xFF363A40),
    textPrimary: Color(0xFFF1F1F1),
    textSecondary: Color(0xFFB0B3B8),
    textTertiary: Color(0xFF8A8D93),
    textInverse: Color(0xFF14181F),
    brand: Color(0xFF1FAA8A),
    brandHover: Color(0xFF1D9A7E),
    brandPressed: Color(0xFF17806A),
    brandSubtle: Color(0xFF17302A),
    accentAmber: Color(0xFFF59E0B),
    accentAmberBg: Color(0xFF33260A),
    success: Color(0xFF22C55E),
    successBg: Color(0xFF16251A),
    successBorder: Color(0xFF1E3A22),
    warning: Color(0xFFF59E0B),
    warningBg: Color(0xFF2A1F0A),
    error: Color(0xFFEF4444),
    errorBg: Color(0xFF2A1515),
    errorBorder: Color(0xFF4A1E1E),
    info: Color(0xFF22D3EE),
    infoBg: Color(0xFF0F2A30),
  );

  @override
  AppColorExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceHover,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? brand,
    Color? brandHover,
    Color? brandPressed,
    Color? brandSubtle,
    Color? accentAmber,
    Color? accentAmberBg,
    Color? success,
    Color? successBg,
    Color? successBorder,
    Color? warning,
    Color? warningBg,
    Color? error,
    Color? errorBg,
    Color? errorBorder,
    Color? info,
    Color? infoBg,
  }) {
    return AppColorExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      brandPressed: brandPressed ?? this.brandPressed,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      accentAmber: accentAmber ?? this.accentAmber,
      accentAmberBg: accentAmberBg ?? this.accentAmberBg,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      successBorder: successBorder ?? this.successBorder,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      errorBorder: errorBorder ?? this.errorBorder,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
    );
  }

  @override
  AppColorExtension lerp(ThemeExtension<AppColorExtension>? other, double t) {
    if (other is! AppColorExtension) return this;
    return AppColorExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandHover: Color.lerp(brandHover, other.brandHover, t)!,
      brandPressed: Color.lerp(brandPressed, other.brandPressed, t)!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      accentAmberBg: Color.lerp(accentAmberBg, other.accentAmberBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorExtension get appColors => Theme.of(this).extension<AppColorExtension>()!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
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
  static List<BoxShadow> get cardDark => [
        BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 4)),
        BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 1, offset: const Offset(0, 1)),
      ];
}

class AppTheme {
  static final lightScheme = ColorScheme.fromSeed(
    seedColor: Color(0xFF0F5B4A),
    primary: Color(0xFF0F5B4A),
    onPrimary: Colors.white,
    secondary: Color(0xFF5E6166),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFDC2626),
    brightness: Brightness.light,
  );

  static final darkScheme = ColorScheme.fromSeed(
    seedColor: Color(0xFF1FAA8A),
    primary: Color(0xFF1FAA8A),
    onPrimary: Colors.black,
    secondary: Color(0xFFB0B3B8),
    surface: Color(0xFF1C1E21),
    error: Color(0xFFEF4444),
    brightness: Brightness.dark,
  ).copyWith(
    surface: Color(0xFF1C1E21),
    error: Color(0xFFEF4444),
    onSurface: Color(0xFFF1F1F1),
    primary: Color(0xFF1FAA8A),
    onPrimary: Colors.white,
  );

  static ThemeData light() {
    const ext = AppColorExtension.light;
    final scheme = lightScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Color(0xFFF6F5F2),
      extensions: const [ext],
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFF14181F),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF14181F),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Color(0xFF14181F), size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Color(0xFFFFFFFF),
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: Color(0xFFE8E6E1), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Color(0xFF0F5B4A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFF8A8D93).withOpacity(0.12),
          disabledForegroundColor: Color(0xFF8A8D93),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF14181F),
          side: const BorderSide(color: Color(0xFFD9D6D0), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF0F5B4A),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFD9D6D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFD9D6D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFF0F5B4A), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
        ),
        filled: true,
        fillColor: Color(0xFFFFFFFF),
        hintStyle: const TextStyle(color: Color(0xFF8A8D93), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF5E6166), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: Color(0xFF0F5B4A), fontSize: 13, fontWeight: FontWeight.w500),
        prefixIconColor: Color(0xFF8A8D93),
        suffixIconColor: Color(0xFF8A8D93),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: false,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFF1F0EC),
        side: const BorderSide(color: Color(0xFFE8E6E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
        labelStyle: const TextStyle(color: Color(0xFF14181F), fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8E6E1), thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: Color(0xFF5E6166), size: 20),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF14181F),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        titleTextStyle: const TextStyle(color: Color(0xFF14181F), fontSize: 17, fontWeight: FontWeight.w600),
        contentTextStyle: const TextStyle(color: Color(0xFF5E6166), fontSize: 14, height: 1.4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF14181F), fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.8, height: 1.1),
        headlineSmall: TextStyle(color: Color(0xFF14181F), fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.4),
        titleLarge: TextStyle(color: Color(0xFF14181F), fontWeight: FontWeight.w600, fontSize: 17, letterSpacing: -0.2),
        titleMedium: TextStyle(color: Color(0xFF14181F), fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: TextStyle(color: Color(0xFF5E6166), fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2),
        bodyLarge: TextStyle(color: Color(0xFF14181F), fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(color: Color(0xFF5E6166), fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: Color(0xFF8A8D93), fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: Color(0xFF14181F), fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: Color(0xFF8A8D93), fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
      ),
    );
  }

  static ThemeData dark() {
    const ext = AppColorExtension.dark;
    final scheme = darkScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Color(0xFF121416),
      extensions: const [ext],
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1E21),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFFF1F1F1),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF1F1F1),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF1F1F1), size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Color(0xFF1C1E21),
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: Color(0xFF2A2E33), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Color(0xFF1FAA8A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFF8A8D93).withOpacity(0.14),
          disabledForegroundColor: Color(0xFF8A8D93),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFFF1F1F1),
          side: const BorderSide(color: Color(0xFF363A40), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF1FAA8A),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFF363A40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFF363A40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFF1FAA8A), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
        ),
        filled: true,
        fillColor: Color(0xFF1C1E21),
        hintStyle: const TextStyle(color: Color(0xFF8A8D93), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFFB0B3B8), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: Color(0xFF1FAA8A), fontSize: 13, fontWeight: FontWeight.w500),
        prefixIconColor: Color(0xFF8A8D93),
        suffixIconColor: Color(0xFF8A8D93),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: false,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF25282C),
        side: const BorderSide(color: Color(0xFF2A2E33)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
        labelStyle: const TextStyle(color: Color(0xFFF1F1F1), fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2E33), thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: Color(0xFFB0B3B8), size: 20),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF25282C),
        contentTextStyle: const TextStyle(color: Color(0xFFF1F1F1), fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xFF1C1E21),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        titleTextStyle: const TextStyle(color: Color(0xFFF1F1F1), fontSize: 17, fontWeight: FontWeight.w600),
        contentTextStyle: const TextStyle(color: Color(0xFFB0B3B8), fontSize: 14, height: 1.4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1C1E21),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFF1F1F1), fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.8, height: 1.1),
        headlineSmall: TextStyle(color: Color(0xFFF1F1F1), fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.4),
        titleLarge: TextStyle(color: Color(0xFFF1F1F1), fontWeight: FontWeight.w600, fontSize: 17, letterSpacing: -0.2),
        titleMedium: TextStyle(color: Color(0xFFF1F1F1), fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: TextStyle(color: Color(0xFFB0B3B8), fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2),
        bodyLarge: TextStyle(color: Color(0xFFF1F1F1), fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(color: Color(0xFFB0B3B8), fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: Color(0xFF8A8D93), fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: Color(0xFFF1F1F1), fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: Color(0xFF8A8D93), fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
      ),
    );
  }

  // Compat: old code called futuristicDark()
  static ThemeData futuristicDark() => dark();
}
