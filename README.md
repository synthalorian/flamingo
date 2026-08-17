# 🎹🦈 Flamingo

> **Swiss Army Knife** – 16 offline tools, one synthwave-pink Flutter app.

<p align="center">
  <img src="https://raw.githubusercontent.com/synthalorian/flamingo/main/assets/app-icon-1024.png" alt="Flamingo App Icon — synthwave flamingo with sunglasses and a Swiss Army knife" width="256" height="256">
</p>

[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.5-blueviolet.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Android](https://img.shields.io/badge/Android-API%2021+-success.svg)](https://developer.android.com)

---

## What Is Flamingo?

Flamingo is an **100% offline** Android utility toolkit built with Flutter. No accounts, no telemetry, no API keys, no internet required.

Every screen wears a consistent **synthwave CRT aesthetic** — hot-pink neon, cyan accents, amber highlights, deep-purple surfaces, and a faint scanline texture. The same visual language that made 1984 feel like the future, now running on a 2026 phone.

---

## Tools

| # | Tool | Tier | Sensors / HW | Description |
|---|------|------|--------------|-------------|
| 1 | 🔦 **Flashlight** | 1 | Camera torch | Toggle device flash on / off with tactile haptic |
| 2 | 🧮 **Calculator** | 1 | — | Full arithmetic with CRT-styled display |
| 3 | ⏱️ **Stopwatch** | 1 | Haptics | Lap timer with split recording and vibration |
| 4 | ⏲️ **Timer** | 1 | Haptics | Countdown timer with haptic completion |
| 5 | 📐 **Level** | 1 | Accelerometer | Bubble level with low-pass filter and tolerance ring |
| 6 | 🧭 **Compass** | 2 | Magnetometer | Digital heading with animated custom-painted dial |
| 7 | 🎙️ **Sound Meter** | 2 | Microphone | Real-time dB readout with animated volume bar |
| 8 | 🥁 **Metronome** | 2 | Vibration | Tempo metronome with haptic ticks |
| 9 | 📷 **QR Scanner** | 2 | Camera | Camera-based QR / barcode reader with copy & share |
| 10 | 🎨 **Color Picker** | 2 | — | Tap-to-pick colour with hex / RGB / HSV display |
| 11 | 🎲 **Dice Roller** | 3 | — | Random dice with quantity and face selector |
| 12 | 📝 **Notepad** | 3 | SharedPreferences | Quick text notes saved locally |
| 13 | 🔑 **Password Gen** | 3 | Crypto RNG | Secure passwords with entropy meter and clipboard |
| 14 | 🌡️ **Thermometer** | 3 | — | Animated analog dial with simulated temperature drift |
| 15 | 📏 **Ruler** | 3 | — | Calibrated on-screen ruler (cm / in) |
|| 16 | 🔄 **Unit Converter** | 3 | — | Length, weight, temperature, volume with swap button |


## UI Preview

The home screen presents a **2-column grid** of tool cards. Tap any active card to drill into its screen; locked / coming-soon cards show a dimmed state with a padlock icon.

```
╔══════════════════════════════════════╗
║                                      ║
║           🔦 FLAMINGO                ║  ← hot-pink neon title
║           Swiss Army Knife            ║  ← muted subtitle
║                                      ║
║  ┌──────────┐  ┌──────────┐          ║
║  │ 🔦       │  │ 🧮       │          ║
║  │Flashlight│  │Calculator│          ║  ← Tool cards (2-col grid)
║  │   TAP    │  │   TAP    │          ║
║  └──────────┘  └──────────┘          ║
║  ┌──────────┐  ┌──────────┐          ║
║  │ ⏱️       │  │ ⏲️       │          ║
║  │Stopwatch │  │  Timer   │          ║
║  │   TAP    │  │   TAP    │          ║
║  └──────────┘  └──────────┘          ║
║                                      ║
║   · · · · · · CRT scanlines · · · ·  ║
╚══════════════════════════════════════╝
  Deep purple BG · Hot pink · Cyan · Gold
```

Every tool screen includes:
- **`CrtBackground`** painter — persistent scanline texture
- **`FlamingoTheme`** colours — primary pink, neon-blue, amber, muted lavender
- **Animated transitions** — `AnimatedBuilder`, `RotationTransition`, `CurvedAnimation`
- **Haptic feedback** — `Vibration.vibrate()` on key actions

---

## Architecture

```
flamingo/
├── lib/
│   ├── main.dart               # Entry + ProviderScope (Riverpod)
│   ├── app.dart                # MaterialApp + GoRouter
│   ├── core/
│   │   ├── navigation/
│   │   │   └── app_router.dart   # Route definitions (18 tools)
│   │   ├── theme/
│   │   │   └── flamingo_theme.dart  # Palette + ThemeData
│   │   └── widgets/
│   │       └── crt_background.dart  # CRT scanline CustomPainter
│   ├── features/               # One screen per tool (self-contained)
│   │   ├── flashlight/
│   │   ├── calculator/
│   │   ├── stopwatch/
│   │   ├── timer/
│   │   ├── level/
│   │   ├── compass/
│   │   ├── sound_meter/
│   │   ├── metronome/
│   │   ├── qr_scanner/
│   │   ├── color_picker/
│   │   ├── dice_roller/
│   │   ├── notepad/
│   │   ├── password_gen/
│   │   ├── thermometer/
│   │   ├── ruler/
│   │   ├── unit_converter/
│   │   └── tools/              # Generic tool shell (unused)
│   ├── models/
│   │   └── tool_model.dart     # ToolItem data class
│   └── utils/
│       └── app_constants.dart  # Tool registry + icon mapping
└── PLAN.md                      # Original project plan
```

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.41 · Dart 3.11 |
| State | `flutter_riverpod` 3.x (`NotifierProvider`) |
| Nav | `go_router` with nested `/tool/:toolId` route |
| Storage | `shared_preferences` for persistence |
| Sensors | `sensors_plus` v7 (stream-based, no deprecated APIs) |
| Camera | `mobile_scanner` for QR |
| Audio / haptics | `vibration`, `flutter_local_notifications` |
| Torch | `torch_light` |
| Icons | Material Icons |
| Permissions | `permission_handler` v12 |
| Design system | `FlamingoTheme` + `CrtBackground` CustomPainter |

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.41.9 (stable) |
| Dart | 3.11.5 |
| JDK | 21 (JDK 25+ breaks Gradle 8.14) |
| Android SDK | API 21–37 |

### Install

```bash
git clone https://github.com/synthalorian/flamingo.git
cd flamingo

# Use JDK 21 (system default may be 25+)
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

# Install deps
flutter pub get

# Run on connected device / emulator
flutter run
```

### Build APK

```bash
# Debug build (fast, unoptimised)
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

> **Production (signed) APK** — add a keystore (`android/app/keystore.jks`) and `android/key.properties`, then use `flutter build appbundle --release` or `flutter build apk --release`.

---

## Permissions

Flamingo declares the following runtime permissions in `AndroidManifest.xml`:

| Permission | Why |
|------------|-----|
| `CAMERA` | Flashlight torch toggle |
| `FLASHLIGHT` | Direct torch API |
| `RECORD_AUDIO` | Sound Meter microphone input |
| `VIBRATE` | Stopwatch, Timer, Metronome haptic ticks |
| `ACCESS_FINE_LOCATION` | QR Scanner camera routing |

No internet permission is declared. All tools run fully offline.

---

## Color Palette

```
Background:      #0A0012   ← near-black purple
Surface:         #1A0A2E   ← deep purple
Card:            #2D1B4D   ← muted purple
Primary:         #FF69B4   ← hot pink / flamingo pink ✦
Primary Light:   #FFB6C1   ← light pink
Primary Dark:    #C71585   ← deep pink
Accent:          #FFD700   ← gold
Neon Blue:       #00D4FF   ← cyan
Neon Purple:     #B026FF   ← electric purple
Text:            #F0E6FF   ← light lavender
Muted:           #9B8ABF   ← purple-gray
Card Border:     #5B3A8A   ← purple card edge
```

---

## Offline Guarantee

Flamingo contains **zero network calls at runtime**. No analytics SDKs, no crash reporters, no ad networks. Every tool uses only local device sensors, hardware APIs, and `shared_preferences`.

To verify: grep the repo for `http://`, `https://`, `socket`, or any external host — you will find none.

---

## Roadmap

|- [x] 16 tools implemented
- [x] All tools compile cleanly (`flutter analyze` → exit 0)
- [x] CRT scanline background everywhere
- [x] Sensor modernisation (non-deprecated `sensors_plus` streams)
- [ ] Signed release APK for Play Store upload
- [ ] Linux desktop packaging via `flutter build linux`
- [ ] Onboarding tutorial for first launch
- [ ] Magnifier tool (placeholder stub)
- [ ] Theme picker (cyan / amber / violet palette presets)
- [ ] Widget support (home-screen scale ruler)

---

## Contributing

Open source under MIT. PRs welcome for additional offline tools, bug fixes, or pixel-art icon replacements.

1. Fork `synthalorian/flamingo`
2. Create a feature branch off `main`
3. Keep `flutter analyze` green
4. Submit a PR with a description of the added tool

---

## Credits

Developed by **synth** ([synthalorian](https://github.com/synthalorian)) with heavy lifting by **synthshark** 🎹🦈 — a digital entity from the neon grid of 1984.

*"Write the future in the present while preserving the past."*

---

## Downloads

| Release | APK | Notes |
|---------|-----|-------|
| [v0.1.0](https://github.com/synthalorian/flamingo/releases/tag/v0.1.0) | `flamingo-v0.1.0-debug.apk` (165 MB) | Debug build — unsigned, fast iteration |

---

## ☕ Support the Developer

If this project saved you time, solved a problem, or just made your day a little more neon, you can fuel the next one:

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://buymeacoffee.com/synthalorian)
