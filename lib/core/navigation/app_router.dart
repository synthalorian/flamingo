import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/flamingo_theme.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/flashlight/flashlight_screen.dart';
import '../../features/calculator/calculator_screen.dart';
import '../../features/stopwatch/stopwatch_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/level/level_screen.dart';
import '../../features/compass/compass_screen.dart';
import '../../features/sound_meter/sound_meter_screen.dart';
import '../../features/metronome/metronome_screen.dart';
import '../../features/qr_scanner/qr_scanner.dart';
import '../../features/color_picker/color_picker_screen.dart';
import '../../features/dice_roller/dice_roller_screen.dart';
import '../../features/notepad/notepad_screen.dart';
import '../../features/password_gen/password_gen_screen.dart';
import '../../features/thermometer/thermometer_screen.dart';
import '../../features/ruler/ruler_screen.dart';
import '../../features/unit_converter/unit_converter_screen.dart';
import '../../features/battery_thermometer/battery_thermometer_screen.dart';
import '../../features/magnifier/magnifier_screen.dart';
import '../../features/breathing/breathing_screen.dart';
import '../../features/step_counter/step_counter_screen.dart';
import '../../features/pomodoro/pomodoro_screen.dart';
import '../../features/home/home_screen.dart';

/// Central router configuration for the Flamingo app.
class AppRouter {
  AppRouter._();

  /// Global navigator key shared across the app.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Returns a configured [GoRouter] instance.
  static GoRouter goRouter() {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'tool/:toolId',
              name: 'tool',
              builder: (context, state) {
                final toolId = state.pathParameters['toolId']!;
                switch (toolId) {
                  case 'flashlight':
                    return const FlashlightScreen();
                  case 'calculator':
                    return const CalculatorScreen();
                  case 'stopwatch':
                    return const StopwatchScreen();
                  case 'timer':
                    return const TimerScreen();
                  case 'level':
                    return const LevelScreen();
                  case 'compass':
                    return const CompassScreen();
                  case 'soundMeter':
                    return const SoundMeterScreen();
                  case 'metronome':
                    return const MetronomeScreen();
                  case 'qrScanner':
                    return const QrScannerScreen();
                  case 'colorPicker':
                    return const ColorPickerScreen();
                  case 'diceRoller':
                    return const DiceRollerScreen();
                  case 'notepad':
                    return const NotePadScreen();
                  case 'passwordGen':
                    return const PasswordGenScreen();
                  case 'thermometer':
                    return const ThermometerScreen();
                  case 'ruler':
                    return const RulerScreen();
                  case 'unitConverter':
                    return const UnitConverterScreen();
                  case 'batteryThermometer':
                    return const BatteryThermometerScreen();
                  case 'magnifier':
                    return const MagnifierScreen();
                  case 'breathing':
                    return const BreathingScreen();
                  case 'stepCounter':
                    return const StepCounterScreen();
                  case 'pomodoro':
                    return const PomodoroScreen();
                  default:
                    return Scaffold(
                      backgroundColor: FlamingoColors.card,
                      body: Center(
                        child: Text(
                          'Tool "$toolId" not found',
                          style: TextStyle(color: FlamingoColors.muted),
                        ),
                      ),
                    );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
