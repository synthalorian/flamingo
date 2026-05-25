import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FLAMINGO THEME SYSTEM — 4 Themes
// ═══════════════════════════════════════════════════════════════════════════════
// Themes are defined as complete ThemeData objects with all properties resolved.
// The app uses colorScheme tokens for consistency across all screens.
//
// Theme index mapping:
//   0 — Dark Synthwave (default)
//   1 — Light Clean
//   2 — Standard Flamingo (hot pink)
//   3 — Synthwave '84 (deep purple, neon cyan)
// ═══════════════════════════════════════════════════════════════════════════════

/// App-level theme definitions.
class AppTheme {
  AppTheme._();

  static const List<String> names = [
    'Dark Synthwave',
    'Light Clean',
    'Flamingo',
    'Synthwave \'84',
  ];

  static const List<IconData> icons = [
    Icons.dark_mode,
    Icons.light_mode,
    Icons.flash_on,
    Icons.grid_on,
  ];

  static ThemeData get(int index) => _themes[index.clamp(0, 3)];
  static int get defaultIndex => 0;

  static final List<ThemeData> _themes = [
    _darkSynthwave,
    _lightClean,
    _flamingo,
    _synthwave84,
  ];

  // ── Theme 0: Dark Synthwave ────────────────────────────────────────────────
  static final ThemeData _darkSynthwave = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFF69B4), // hot pink
    secondaryColor: const Color(0xFF00D4FF), // cyan
    tertiaryColor: const Color(0xFFFFD700), // gold
    surfaceColor: const Color(0xFF0A0012), // deep dark purple
    surfaceContainerLow: const Color(0xFF1A0A2E),
    surfaceContainerHigh: const Color(0xFF2D1B4D),
    onSurfaceColor: const Color(0xFFF0E6FF), // light lavender text
    onSurfaceVariant: const Color(0xFF9B8ABF), // muted lavender
    outlineVariant: const Color(0xFF4A2080), // border purple
    primaryContainer: const Color(0xFFFFB6C1), // light pink
    onPrimaryContainer: const Color(0xFFC71585), // deep pink
    scaffoldBg: const Color(0xFF0A0012),
    cardBg: const Color(0xFF2D1B4D),
    glowPink: const Color(0xFFFF69B4),
    glowCyan: const Color(0xFF00D4FF),
  );

  // ── Theme 1: Light Clean ───────────────────────────────────────────────────
  static final ThemeData _lightClean = _buildTheme(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFD81B60), // pink
    secondaryColor: const Color(0xFF0288D1), // blue
    tertiaryColor: const Color(0xFFFF8F00), // amber
    surfaceColor: const Color(0xFFF5F0FA), // very light purple tint
    surfaceContainerLow: const Color(0xFFFFFFFF),
    surfaceContainerHigh: const Color(0xFFEDE7F6),
    onSurfaceColor: const Color(0xFF1C1B1F), // near black
    onSurfaceVariant: const Color(0xFF6B657A), // muted grey
    outlineVariant: const Color(0xFFCAC4D0), // light border
    primaryContainer: const Color(0xFFFFD9E6), // very light pink
    onPrimaryContainer: const Color(0xFF8C0032), // dark pink
    scaffoldBg: const Color(0xFFF5F0FA),
    cardBg: const Color(0xFFFFFFFF),
    glowPink: const Color(0xFFD81B60),
    glowCyan: const Color(0xFF0288D1),
  );

  // ── Theme 2: Standard Flamingo ─────────────────────────────────────────────
  static final ThemeData _flamingo = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFF69B4), // bright hot pink
    secondaryColor: const Color(0xFFFF1493), // deep pink
    tertiaryColor: const Color(0xFFFFB6C1), // light pink
    surfaceColor: const Color(0xFF1A0008), // dark rose
    surfaceContainerLow: const Color(0xFF2C0012),
    surfaceContainerHigh: const Color(0xFF3D0020),
    onSurfaceColor: const Color(0xFFFFF0F5), // lavender blush
    onSurfaceVariant: const Color(0xFFCC99AA), // muted rose
    outlineVariant: const Color(0xFF5C0030), // deep rose border
    primaryContainer: const Color(0xFFFFB6C1),
    onPrimaryContainer: const Color(0xFFC71585),
    scaffoldBg: const Color(0xFF1A0008),
    cardBg: const Color(0xFF3D0020),
    glowPink: const Color(0xFFFF69B4),
    glowCyan: const Color(0xFFFF1493),
  );

  // ── Theme 3: Synthwave '84 ─────────────────────────────────────────────────
  // Matches Omarchy synthwave84 theme: vivid purple primary, deep purple surfaces,
  // yellow + hot pink accents, neon cyan secondary.
  // waybar: bg=#0d0221, fg=#ffff66, surface=#240037, primary=#8f00ff
  static final ThemeData _synthwave84 = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF8F00FF), // vivid purple
    secondaryColor: const Color(0xFF03EDF9), // neon cyan
    tertiaryColor: const Color(0xFFFF69B4), // hot pink
    surfaceColor: const Color(0xFF0D0221), // deep purple black
    surfaceContainerLow: const Color(0xFF240037), // deep purple (alacritty bg)
    surfaceContainerHigh: const Color(
      0xFF3A0057,
    ), // lighter deep purple (cards)
    onSurfaceColor: const Color(0xFFFFFFFF), // white text
    onSurfaceVariant: const Color(0xFFC8B060), // muted gold/yellow accent
    outlineVariant: const Color(0xFF4A0070), // purple border
    primaryContainer: const Color(0xFFB060FF), // light purple
    onPrimaryContainer: const Color(0xFF0D0221), // dark
    scaffoldBg: const Color(0xFF0D0221),
    cardBg: const Color(0xFF3A0057),
    glowPink: const Color(0xFFFF69B4),
    glowCyan: const Color(0xFF03EDF9),
  );

  // ── Theme builder ───────────────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color secondaryColor,
    required Color tertiaryColor,
    required Color surfaceColor,
    required Color surfaceContainerLow,
    required Color surfaceContainerHigh,
    required Color onSurfaceColor,
    required Color onSurfaceVariant,
    required Color outlineVariant,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color scaffoldBg,
    required Color cardBg,
    required Color glowPink,
    required Color glowCyan,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: isDark ? surfaceColor : Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondaryColor,
        onSecondary: isDark ? surfaceColor : Colors.white,
        secondaryContainer: secondaryColor.withValues(alpha: 0.2),
        onSecondaryContainer: secondaryColor,
        tertiary: tertiaryColor,
        onTertiary: isDark ? surfaceColor : Colors.white,
        tertiaryContainer: tertiaryColor.withValues(alpha: 0.2),
        onTertiaryContainer: tertiaryColor,
        error: isDark ? const Color(0xFFFF5252) : const Color(0xFFB00020),
        onError: isDark ? surfaceColor : Colors.white,
        surface: scaffoldBg,
        onSurface: onSurfaceColor,
        surfaceContainerLowest: surfaceColor,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHigh,
        onSurfaceVariant: onSurfaceVariant,
        outline: outlineVariant,
        outlineVariant: outlineVariant,
        shadow: isDark ? Colors.black26 : Colors.black12,
        inverseSurface: isDark ? onSurfaceColor : surfaceColor,
        onInverseSurface: isDark ? surfaceColor : onSurfaceColor,
        inversePrimary: isDark ? primaryContainer : onPrimaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outlineVariant, width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceContainerLow,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLow,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          fontFamily: 'Roboto',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          fontFamily: 'Roboto',
        ),
      ),
      iconTheme: IconThemeData(color: primaryColor, size: 24),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? surfaceColor : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: TextStyle(color: onSurfaceVariant),
        contentPadding: const EdgeInsets.all(16),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: surfaceContainerHigh,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.3),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        valueIndicatorTextStyle: TextStyle(color: onSurfaceColor),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : onSurfaceVariant,
        ),
        trackColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor.withValues(alpha: 0.5)
              : surfaceContainerHigh,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
    );
  }
}

/// Backward-compatible static color accessors.
/// Each maps to the currently selected theme's color scheme slots.
/// Screens should prefer Theme.of(context).colorScheme.* for theme-aware colors.
class FlamingoColors {
  FlamingoColors._();

  // Legacy static colors — used by screens that haven't been migrated yet.
  // These default to theme 0 (Dark Synthwave) for backward compat.
  static Color scaffoldBg = const Color(0xFF0A0012);
  static Color surface = const Color(0xFF1A0A2E);
  static Color card = const Color(0xFF2D1B4D);
  static Color primary = const Color(0xFFFF69B4);
  static Color primaryLight = const Color(0xFFFFB6C1);
  static Color primaryDark = const Color(0xFFC71585);
  static Color accent = const Color(0xFFFFD700);
  static Color neonBlue = const Color(0xFF00D4FF);
  static Color neonPurple = const Color(0xFFB026FF);
  static Color text = const Color(0xFFF0E6FF);
  static Color muted = const Color(0xFF9B8ABF);
  static Color cardBg = const Color(0xFF2D1B4D);
  static Color cardBorder = const Color(0xFF4A2080);
  static Color glowPink = const Color(0xFFFF69B4);
  static Color glowCyan = const Color(0xFF00D4FF);

  /// Call this when the theme changes so legacy color references follow.
  static void syncFrom(ColorScheme cs) {
    scaffoldBg = cs.surface;
    surface = cs.surfaceContainerLow;
    card = cs.surfaceContainerHigh;
    primary = cs.primary;
    primaryLight = cs.primaryContainer;
    primaryDark = cs.onPrimaryContainer;
    accent = cs.tertiary;
    neonBlue = cs.secondary;
    neonPurple = cs.secondaryContainer;
    text = cs.onSurface;
    muted = cs.onSurfaceVariant;
    cardBg = cs.surfaceContainerHigh;
    cardBorder = cs.outlineVariant;
    glowPink = cs.primary;
    glowCyan = cs.secondary;
  }
}
