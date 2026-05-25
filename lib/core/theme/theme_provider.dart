import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flamingo_theme.dart';

const _prefsKey = 'flamingo_theme_index';

/// Theme state notifier using Riverpod 3.x Notifier API.
class ThemeNotifier extends Notifier<int> {
  @override
  int build() {
    _load();
    return AppTheme.defaultIndex;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_prefsKey) ?? AppTheme.defaultIndex;
    if (idx != state) {
      state = idx.clamp(0, 3);
      _apply(idx);
    }
  }

  Future<void> setTheme(int index) async {
    final clamped = index.clamp(0, 3);
    if (clamped == state) return;
    state = clamped;
    _apply(clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, clamped);
  }

  void _apply(int index) {
    final cs = AppTheme.get(index).colorScheme;
    FlamingoColors.syncFrom(cs);
  }
}

final themeIndexProvider = NotifierProvider<ThemeNotifier, int>(ThemeNotifier.new);

/// Derived provider that returns the current ThemeData.
final themeDataProvider = Provider<ThemeData>((ref) {
  final index = ref.watch(themeIndexProvider);
  return AppTheme.get(index);
});

/// Supported themes enum for display.
enum FlamingoThemeName {
  darkSynthwave,
  lightClean,
  flamingo,
  synthwave84;

  String get label {
    switch (this) {
      case FlamingoThemeName.darkSynthwave: return 'Dark Synthwave';
      case FlamingoThemeName.lightClean:    return 'Light Clean';
      case FlamingoThemeName.flamingo:      return 'Flamingo';
      case FlamingoThemeName.synthwave84:   return 'Synthwave \'84';
    }
  }

  String get description {
    switch (this) {
      case FlamingoThemeName.darkSynthwave: return 'Deep purple, hot pink, neon cyan';
      case FlamingoThemeName.lightClean:    return 'Clean light with pink accents';
      case FlamingoThemeName.flamingo:      return 'Hot pink on dark rose';
      case FlamingoThemeName.synthwave84:   return 'Vivid purple, yellow, pink, neon cyan';
    }
  }

  IconData get icon {
    switch (this) {
      case FlamingoThemeName.darkSynthwave: return Icons.dark_mode;
      case FlamingoThemeName.lightClean:    return Icons.light_mode;
      case FlamingoThemeName.flamingo:      return Icons.flash_on;
      case FlamingoThemeName.synthwave84:   return Icons.grid_on;
    }
  }

  Color get accentColor {
    switch (this) {
      case FlamingoThemeName.darkSynthwave: return const Color(0xFFFF69B4);
      case FlamingoThemeName.lightClean:    return const Color(0xFFD81B60);
      case FlamingoThemeName.flamingo:      return const Color(0xFFFF69B4);
      case FlamingoThemeName.synthwave84:   return const Color(0xFF8F00FF);
    }
  }

  int get themeIndex => this == FlamingoThemeName.darkSynthwave ? 0
      : this == FlamingoThemeName.lightClean ? 1
      : this == FlamingoThemeName.flamingo ? 2
      : 3;
}