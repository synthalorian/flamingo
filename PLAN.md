# Flamingo — Swiss Army Knife Utility App

> **Goal:** A single utility app that replaces 10+ separate apps — flashlight, thermometer, compass, calculator, level, metronome, timer, ruler, sound meter, and more — all in a beautiful pink synthwave aesthetic.
>
> **Target:** Android APK first (primary), Linux desktop (secondary via Flutter web/desktop for dev/debug).

## Architecture

**Single Flutter app** using:
- **Riverpod 3** (`flutter_riverpod`) for state management
- **go_router** for screen navigation (grid home → individual tools)
- **shared_preferences** for settings persistence
- **Material 3** with custom synthwave pink theme

**No server needed.** Everything runs 100% offline on device.

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Flutter 3.41.9 | Cross-platform, hot reload, single codebase |
| State | flutter_riverpod 3.x (NotifierProvider) | No StateNotifier, no generator conflicts |
| Nav | go_router | Deep linking, back navigation, animations |
| Storage | shared_preferences + json_serializable | Simple, no Hive conflicts |
| Icons | Material Icons (outlined) | Clean, consistent |
| Platform | Android APK (primary), Web (secondary) | Fastest path to production |

## Flamingo Pink Synthwave Theme

**Core palette:**
```
Background:      #0A0012 (near-black purple)
Surface:         #1A0A2E (deep purple)
Card:            #2D1B4D (muted purple)
Primary:         #FF69B4 (hot pink / "flamingo pink")
Primary Light:   #FFB6C1 (light pink)
Primary Dark:    #C71585 (deep pink)
Accent:          #FFD700 (gold — for highlights, badges)
Neon Blue:       #00D4FF (cyan — for contrast elements)
Neon Purple:     #B026FF (electric purple)
Text:            #F0E6FF (light lavender)
Muted:           #9B8ABF (purple-gray)
```

**Aesthetic touches:**
- CRT scanline background via `CustomPainter` (subtle, not overwhelming)
- Neon glow on primary buttons (shadow with pink blur)
- Chrome-style gradient borders on cards
- Breathing pulse animation on the flashlight button
- Pink neon status indicators throughout

## Tools (Phase 1 — Core Utilities)

### Tier 1: Essential (build first)

| Tool | Icon | Key APIs | Complexity |
|------|------|----------|------------|
| **Flashlight** | `Icons.flash_on` | `torch_state` or `android.hardware.camera2` | Low |
| **Calculator** | `Icons.calculate` | Standard calculator with history | Low |
| **Thermometer** | `Icons.thermostat` | System time / env (limited without hardware sensor) | Low |
| **Stopwatch** | `Icons.timer` | `Stopwatch` class | Low |
| **Timer** | `Icons.timer` | `Timer` class, vibration | Low |
| **Level / Bubble Level** | `Icons.straighten` | `sensors_platform` (accelerometer) | Medium |

### Tier 2: Useful (build second)

| Tool | Icon | Key APIs | Complexity |
|------|------|----------|------------|
| **Compass** | `Icons.explore` | `sensors_platform` (magnetometer) | Medium |
| **Sound Meter** | `Icons.graphic_eq` | `microphone` / audio API | Medium |
| **Metronome** | `Icons.music_note` | `audioplayers`, `vibration` | Medium |
| **Ruler** | `Icons.straighten` | Screen calibrate + AR overlay | Medium |
| **QR Scanner** | `Icons.qr_code_scanner` | `mobile_scanner` | Medium |
| **Color Picker** | `Icons.colorize` | Color utils, hex/RGB conversion | Low |

### Tier 3: Nice-to-have (build later)

| Tool | Icon | Key APIs | Complexity |
|------|------|----------|------------|
| **Torch Pro** | `Icons.wb_sunny` | Camera flash intensity control | High |
| **Breathing Exercise** | `Icons.air` | Animation + timer + haptic | Medium |
| **Dice Roller** | `Icons.casino` | Random + 3D dice animation | Medium |
| **Note Pad** | `Icons.note_alt` | SharedPreferences storage | Low |
| **Password Gen** | `Icons.lock` | Crypto-random string gen | Low |

## Project Structure

```
flamingo/
├── lib/
│   ├── main.dart                    # Entry point + ProviderScope
│   ├── app.dart                     # MaterialApp + router
│   └── core/
│       ├── navigation/
│       │   └── app_router.dart      # GoRouter config
│       ├── theme/
│       │   └── flamingo_theme.dart  # ThemeData + color constants
│       └── utils/
│           └── constants.dart       # App-wide constants
├── features/
│   ├── home/
│   │   └── home_screen.dart         # Tool grid (main menu)
│   ├── flashlight/
│   │   └── flashlight_screen.dart   # Flashlight tool
│   ├── calculator/
│   │   └── calculator_screen.dart   # Calculator tool
│   ├── stopwatch/
│   │   └── stopwatch_screen.dart    # Stopwatch tool
│   ├── timer/
│   │   └── timer_screen.dart        # Countdown timer
│   └── level/
│       └── level_screen.dart        # Bubble level
├── assets/
│   └── icon/
│       └── icon.png                 # 1024x1024 flamingo pink icon
├── pubspec.yaml
├── build.yaml                     # build_runner config
└── PLAN.md                        # This file
```

## Implementation Order

### Phase 1: Foundation + 3 Core Tools (Week 1)
1. Scaffold project + dependencies
2. Flamingo Pink theme system
3. Home screen (grid of tool cards)
4. Router + navigation
5. Flashlight (uses camera flash)
6. Calculator (full screen with history)
7. Stopwatch + countdown timer

### Phase 2: Sensor Tools (Week 2)
8. Bubble level (accelerometer)
9. Compass (magnetometer)
10. Sound meter (microphone)

### Phase 3: Extra Tools (Week 3)
11. QR scanner
12. Metronome
13. Color picker
14. Thermometer (system readings)

### Phase 4: Polish + Release (Week 4)
15. CRT synthwave visual effects
16. App icon generation (all densities)
17. Haptics + vibration on all tools
18. Settings screen (theme variants, sound settings)
19. APK build + release

## Key Implementation Notes

- **No enum constructors** — Dart 3.11.5 bug. Use `class` with `static const`.
- **Riverpod 3** — `NotifierProvider`, not `StateNotifierProvider`. No `riverpod_generator`.
- **shared_preferences** — init in `main()` before `runApp()`. Use shared instance pattern.
- **Empty states** — every list/screen must handle zero data with visible widgets.
- **build_runner** — filter to `lib/data/models/**` only via `build.yaml`.
- **surfaceTintColor** — set to `Colors.transparent` on all dark theme components.
- **withValues(alpha:)** — not `withOpacity()`.
- **No enum constructors with params** — Dart 3.11.5 compiler bug. Use class + static const workaround.

## Subagent Execution Strategy

Use `subagent-driven-development` for implementation. Each phase dispatches a fresh subagent:
1. Subagent writes code
2. Two-stage review: spec compliance → code quality
3. Verify with `flutter analyze` after each phase

## Pitfalls to Avoid

- Don't use `flutter_launcher_icons` without RGBA source (Android default logo)
- Don't call `canLaunchUrl()` on Android 11+ without `<queries>` in manifest
- Don't use `AnimatedBuilder` — use `ListenableBuilder` (Flutter 3.41+)
- Don't use `const` constructors with `GoogleFonts` or `Theme.of()`
- Don't put dark themes in `theme:` slot — use `darkTheme:` for dark themes
- Don't forget `android.permission.FLASHLIGHT` in AndroidManifest.xml
- Don't forget `android.permission.CAMERA` for flashlight
