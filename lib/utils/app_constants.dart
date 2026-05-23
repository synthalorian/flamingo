import 'package:flutter/material.dart';
import '../models/tool_model.dart';

/// Centralized constants for the Flamingo app.
class AppConstants {
  AppConstants._();

  /// Application title.
  static const String appTitle = 'Flamingo';

  /// Subtitle shown under the app title.
  static const String appSubtitle = 'Swiss Army Knife';

  /// All tool definitions, ordered by tier.
  static final List<ToolItem> tools = <ToolItem>[
    // ── Tier 1 – active tools ───────────────────────────────────
    ToolItem(
      id: 'flashlight',
      title: 'Flashlight',
      description: 'Use device flash as a light',
      routePath: '/tool/flashlight',
      icon: Icons.flash_on,
      accentColor: const Color(0xFFFF69B4),
    ),
    ToolItem(
      id: 'calculator',
      title: 'Calculator',
      description: 'Basic calculations',
      routePath: '/tool/calculator',
      icon: Icons.calculate,
      accentColor: const Color(0xFF00D4FF),
    ),
    ToolItem(
      id: 'stopwatch',
      title: 'Stopwatch',
      description: 'Stopwatch with lap times',
      routePath: '/tool/stopwatch',
      icon: Icons.timer,
      accentColor: const Color(0xFFB026FF),
    ),
    ToolItem(
      id: 'timer',
      title: 'Timer',
      description: 'Countdown timer',
      routePath: '/tool/timer',
      icon: Icons.timer_outlined,
      accentColor: const Color(0xFF00D4FF),
    ),
    ToolItem(
      id: 'level',
      title: 'Level',
      description: 'Bubble level / spirit level',
      routePath: '/tool/level',
      icon: Icons.straighten,
      accentColor: const Color(0xFFFFD700),
    ),
    // ── Tier 2 – coming soon ────────────────────────────────────
    ToolItem(
      id: 'compass',
      title: 'Compass',
      description: 'Digital compass',
      routePath: '/tool/compass',
      icon: Icons.explore,
      accentColor: const Color(0xFF00D4FF),
    ),
    ToolItem(
      id: 'soundMeter',
      title: 'Sound Meter',
      description: 'Measure ambient noise level',
      routePath: '/tool/soundMeter',
      icon: Icons.mic,
      accentColor: const Color(0xFFFF69B4),
    ),
    ToolItem(
      id: 'metronome',
      title: 'Metronome',
      description: 'Musical tempo metronome',
      routePath: '/tool/metronome',
      icon: Icons.music_note,
      accentColor: const Color(0xFFB026FF),
    ),
    ToolItem(
      id: 'qrScanner',
      title: 'QR Scanner',
      description: 'Scan QR codes',
      routePath: '/tool/qrScanner',
      icon: Icons.qr_code_scanner,
      accentColor: const Color(0xFF00D4FF),
    ),
    ToolItem(
      id: 'colorPicker',
      title: 'Color Picker',
      description: 'Pick and copy colors',
      routePath: '/tool/colorPicker',
      icon: Icons.color_lens,
      accentColor: const Color(0xFFFFD700),
    ),
    // ── Tier 3 – coming soon ────────────────────────────────────
    ToolItem(
      id: 'diceRoller',
      title: 'Dice Roller',
      description: 'Roll virtual dice',
      routePath: '/tool/diceRoller',
      icon: Icons.emoji_events,
      accentColor: const Color(0xFFFFD700),
    ),
    ToolItem(
      id: 'notepad',
      title: 'Note Pad',
      description: 'Quick notes',
      routePath: '/tool/notepad',
      icon: Icons.note_alt,
      accentColor: const Color(0xFF9B8ABF),
    ),
    ToolItem(
      id: 'passwordGen',
      title: 'Password Generator',
      description: 'Generate secure passwords',
      routePath: '/tool/passwordGen',
      icon: Icons.vpn_key,
      accentColor: const Color(0xFFB026FF),
    ),
    // ── Tier 2+ – new tools ───────────────────────────────────────
    ToolItem(
      id: 'thermometer',
      title: 'Thermometer',
      description: 'Temperature readings',
      routePath: '/tool/thermometer',
      icon: Icons.thermostat,
      accentColor: const Color(0xFFFFD700),
    ),
    ToolItem(
      id: 'ruler',
      title: 'Ruler',
      description: 'On-screen measure tool',
      routePath: '/tool/ruler',
      icon: Icons.straighten,
      accentColor: const Color(0xFF00D4FF),
    ),
    ToolItem(
      id: 'unitConverter',
      title: 'Unit Converter',
      description: 'Convert between units',
      routePath: '/tool/unitConverter',
      icon: Icons.auto_fix_high,
      accentColor: const Color(0xFFB026FF),
    ),
  ];

  /// Icon data for each tool id (used by home screen).
  static IconData iconForToolId(String id) {
    switch (id) {
      case 'flashlight':
        return Icons.flash_on;
      case 'calculator':
        return Icons.calculate;
      case 'stopwatch':
        return Icons.timer;
      case 'timer':
        return Icons.timer_outlined;
      case 'level':
        return Icons.straighten;
      case 'compass':
        return Icons.explore;
      case 'soundMeter':
        return Icons.mic;
      case 'metronome':
        return Icons.music_note;
      case 'qrScanner':
        return Icons.qr_code_scanner;
      case 'colorPicker':
        return Icons.color_lens;
      case 'diceRoller':
        return Icons.emoji_events;
      case 'notepad':
        return Icons.note_alt;
      case 'passwordGen':
        return Icons.vpn_key;
      case 'thermometer':
        return Icons.thermostat;
      case 'ruler':
        return Icons.straighten;
      case 'unitConverter':
        return Icons.auto_fix_high;
      default:
        return Icons.apps;
    }
  }
}
