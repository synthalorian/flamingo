import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen>
    with SingleTickerProviderStateMixin {
  static const _stepThreshold = 12.0;
  static const _stepAlpha = 0.3;
  static const _minStepIntervalMs = 250;

  int _steps = 0;
  double _magnitude = 0;
  bool _running = false;
  bool _aboveThreshold = false;
  int _lastStepTime = 0;

  StreamSubscription? _accSub;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut);

    _loadSteps();
  }

  Future<void> _loadSteps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _steps = prefs.getInt('step_count') ?? 0);
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_count', _steps);
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _accSub = Sensors().accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      final mag = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      setState(() => _magnitude = _magnitude + _stepAlpha * (mag - _magnitude));

      final now = DateTime.now().millisecondsSinceEpoch;
      if (_magnitude > _stepThreshold && !_aboveThreshold) {
        _aboveThreshold = true;
        if (now - _lastStepTime > _minStepIntervalMs) {
          _lastStepTime = now;
          setState(() => _steps++);
          _pulseCtrl.forward(from: 0);
          _saveSteps();
        }
      } else if (_magnitude < _stepThreshold - 2) {
        _aboveThreshold = false;
      }
    });
  }

  void _stop() {
    _accSub?.cancel();
    setState(() => _running = false);
  }

  void _reset() async {
    _stop();
    setState(() => _steps = 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_count', 0);
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double get _estimatedDistance => _steps * 0.78;
  double get _estimatedCalories => _steps * 0.04;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _running ? 4 : 2,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'STEP COUNTER',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by accelerometer',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 32),

                // Step count display
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow rings
                            ...List.generate(3, (i) {
                              final scale = 0.7 +
                                  i * 0.15 +
                                  (_pulseAnim.value * 0.08);
                              final opacity =
                                  0.08 - i * 0.02 - (_pulseAnim.value * 0.03);
                              return Transform.scale(
                                scale: scale.clamp(0.5, 1.2),
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.primary.withValues(
                                        alpha: opacity.clamp(0.0, 0.15),
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Main circle
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    cs.primary.withValues(alpha: 0.2),
                                    cs.primary.withValues(alpha: 0.05),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.3, 0.7, 1.0],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$_steps',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontSize: 56,
                                        fontWeight: FontWeight.w200,
                                        fontFamily: 'monospace',
                                        shadows: [
                                          Shadow(
                                            color: cs.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'steps',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 13,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Animated pulse indicator
                            if (_running && _pulseAnim.value > 0.01)
                              IgnorePointer(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.primary.withValues(
                                        alpha: 0.3 * (1 - _pulseAnim.value),
                                      ),
                                      width:
                                          2 * (1 - _pulseAnim.value) + 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Live magnitude bar
                if (_running) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Motion',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              _magnitude > _stepThreshold ? 'STEP!' : '',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_magnitude / 25).clamp(0.0, 1.0),
                            backgroundColor: cs.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation(
                              _magnitude > _stepThreshold
                                  ? cs.primary
                                  : cs.secondary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      _statBox(
                        cs,
                        '${_estimatedDistance.toStringAsFixed(0)}m',
                        'Distance',
                      ),
                      const SizedBox(width: 12),
                      _statBox(
                        cs,
                        '${_estimatedCalories.toStringAsFixed(0)}',
                        'Cal',
                      ),
                      const SizedBox(width: 12),
                      _running
                          ? _statBox(cs, 'ON', 'Status')
                          : _statBox(cs, 'OFF', 'Status', dimmed: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _running ? _stop : _start,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _running
                                ? [
                                    cs.error.withValues(alpha: 0.2),
                                    cs.error.withValues(alpha: 0.05),
                                  ]
                                : [
                                    cs.primary.withValues(alpha: 0.2),
                                    cs.primary.withValues(alpha: 0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _running
                                ? cs.error.withValues(alpha: 0.3)
                                : cs.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: _running ? cs.error : cs.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _running ? 'PAUSE' : 'START',
                              style: TextStyle(
                                color: _running ? cs.error : cs.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color:
                              cs.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: cs.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'RESET',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  _running
                      ? 'Walk naturally — steps are detected automatically'
                      : 'Tap START to begin counting steps',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(
    ColorScheme cs,
    String value,
    String label, {
    bool dimmed = false,
  }) {
    final color = dimmed ? cs.onSurfaceVariant : cs.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: dimmed ? 0.08 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
