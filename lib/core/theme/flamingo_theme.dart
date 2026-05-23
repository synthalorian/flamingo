import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FLAMINGO PINK SYNTHWAVE THEME
// ═══════════════════════════════════════════════════════════════════════════════
// Deep purple backgrounds, hot pink accents, gold highlights, cyan contrast.
// Think: flamingo flaming up a neon grid at 2am.

// ── Color Constants ──────────────────────────────────────────────────────────

// ignore: avoid_classes_with_only_static_members
class FlamingoColors {
  static const background    = Color(0xFF0A0012);
  static const surface       = Color(0xFF1A0A2E);
  static const card          = Color(0xFF2D1B4D);
  static const primary       = Color(0xFF69B4FF);
  static const primaryLight  = Color(0xFFFFB6C1);
  static const primaryDark   = Color(0xFFC71585);
  static const accent        = Color(0xFFFFD700);
  static const neonBlue      = Color(0xFF00D4FF);
  static const neonPurple    = Color(0xFFB026FF);
  static const text          = Color(0xFFF0E6FF);
  static const muted         = Color(0xFF9B8ABF);
  static const scaffoldBg    = Color(0xFF0A0012);
  static const cardBg        = Color(0xFF2D1B4D);
  static const cardBorder    = Color(0xFF4A2080);
  static const glowPink      = Color(0xFFFF69B4);
  static const glowCyan      = Color(0xFF00D4FF);
}

// ── Theme Data ───────────────────────────────────────────────────────────────

class FlamingoTheme {
  FlamingoTheme._();

  /// The main synthwave pink theme (used as darkTheme since it's dark by default).
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: FlamingoColors.scaffoldBg,
    colorScheme: const ColorScheme.dark(
      primary: FlamingoColors.primary,
      secondary: FlamingoColors.neonBlue,
      surface: FlamingoColors.surface,
      onSurface: FlamingoColors.text,
      tertiary: FlamingoColors.accent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FlamingoColors.surface,
      foregroundColor: FlamingoColors.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: const CardThemeData(
      color: FlamingoColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: FlamingoColors.surface,
      selectedItemColor: FlamingoColors.primary,
      unselectedItemColor: FlamingoColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.text,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.muted,
        fontFamily: 'Roboto',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: FlamingoColors.muted,
        fontFamily: 'Roboto',
      ),
    ),
    iconTheme: const IconThemeData(
      color: FlamingoColors.primary,
      size: 24,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FlamingoColors.primary,
        foregroundColor: FlamingoColors.scaffoldBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FlamingoColors.primary,
        side: const BorderSide(color: FlamingoColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FlamingoColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlamingoColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlamingoColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlamingoColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: FlamingoColors.muted),
      contentPadding: const EdgeInsets.all(16),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: FlamingoColors.primary,
      inactiveTrackColor: FlamingoColors.card,
      thumbColor: FlamingoColors.primary,
      overlayColor: FlamingoColors.primary.withValues(alpha: 0.3),
      tickMarkShape: SliderTickMarkShape.noTickMark,
      valueIndicatorTextStyle: const TextStyle(color: FlamingoColors.text),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateColor.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? FlamingoColors.primary
              : FlamingoColors.muted),
      trackColor: WidgetStateColor.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? FlamingoColors.primary.withValues(alpha: 0.5)
              : FlamingoColors.card),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D1B4D),
      thickness: 1,
    ),
  );
}
