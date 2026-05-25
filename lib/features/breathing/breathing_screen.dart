import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  bool _running = false;
  BreathPhase _phase = BreathPhase.inhale;
  int _cycleCount = 0;
  int _totalBreaths = 0;

  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  static const _inhaleSec = 4;
  static const _holdSec = 4;
  static const _exhaleSec = 4;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _inhaleSec),
    );
    _breathAnim = CurvedAnimation(
      parent: _breathCtrl,
      curve: Curves.easeInOut,
    );
  }

  void _start() {
    setState(() {
      _running = true;
      _cycleCount = 0;
      _totalBreaths = 0;
      _phase = BreathPhase.inhale;
    });
    _breathCtrl.forward(from: 0);
    _nextPhase(BreathPhase.inhale);
  }

  void _stop() {
    _breathCtrl.stop();
    setState(() => _running = false);
  }

  void _nextPhase(BreathPhase phase) {
    setState(() => _phase = phase);
    switch (phase) {
      case BreathPhase.inhale:
        _breathCtrl.forward(from: 0);
        _runDelayed(_inhaleSec, () => _nextPhase(BreathPhase.holdIn));
      case BreathPhase.holdIn:
        _breathCtrl.forward(from: 1);
        _runDelayed(_holdSec, () => _nextPhase(BreathPhase.exhale));
      case BreathPhase.exhale:
        _breathCtrl.reverse(from: 1);
        _runDelayed(_exhaleSec, () => _nextPhase(BreathPhase.holdOut));
      case BreathPhase.holdOut:
        _breathCtrl.reverse(from: 0);
        setState(() {
          _cycleCount++;
          _totalBreaths++;
        });
        if (_cycleCount >= 4) {
          _cycleCount = 0;
        }
        _runDelayed(_holdSec, () => _nextPhase(BreathPhase.inhale));
    }
  }

  void _runDelayed(int seconds, VoidCallback callback) {
    Future.delayed(Duration(seconds: seconds), () {
      if (_running && mounted) callback();
    });
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  String get _phaseLabel {
    switch (_phase) {
      case BreathPhase.inhale:
        return 'Breathe In';
      case BreathPhase.holdIn:
        return 'Hold';
      case BreathPhase.exhale:
        return 'Breathe Out';
      case BreathPhase.holdOut:
        return 'Hold';
    }
  }

  IconData get _phaseIcon {
    switch (_phase) {
      case BreathPhase.inhale:
        return Icons.air;
      case BreathPhase.holdIn:
        return Icons.pause_circle_outline;
      case BreathPhase.exhale:
        return Icons.air_rounded;
      case BreathPhase.holdOut:
        return Icons.pause_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _running ? 5 : 2,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'BREATHING',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Guided breathing exercise',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 24),

                // Breathing circle
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _breathAnim,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: _running
                                    ? [
                                        BoxShadow(
                                          color: cs.primary.withValues(
                                            alpha: 0.15 * _breathAnim.value,
                                          ),
                                          blurRadius: 40,
                                          spreadRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),

                            // Background decorative rings
                            SizedBox(
                              width: 240,
                              height: 240,
                              child: CustomPaint(
                                painter: _BreathRingPainter(
                                  progress: _breathAnim.value,
                                  active: _running,
                                  primaryColor: cs.primary,
                                  mutedColor: cs.onSurfaceVariant,
                                ),
                              ),
                            ),

                            // Main breathing circle
                            Transform.scale(
                              scale: _running
                                  ? 0.3 + 0.7 * _breathAnim.value
                                  : 0.4,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: _running
                                        ? [
                                            cs.primary,
                                            cs.primary.withValues(alpha: 0.3),
                                            cs.primary.withValues(alpha: 0.05),
                                          ]
                                        : [
                                            cs.onSurfaceVariant.withValues(
                                              alpha: 0.5,
                                            ),
                                            cs.onSurfaceVariant.withValues(
                                              alpha: 0.1,
                                            ),
                                          ],
                                    stops: const [0.3, 0.6, 1.0],
                                  ),
                                  boxShadow: _running
                                      ? [
                                          BoxShadow(
                                            color: cs.primary.withValues(
                                              alpha: 0.3 * _breathAnim.value,
                                            ),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_running) ...[
                                        Icon(
                                          _phaseIcon,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _phaseLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ] else ...[
                                        Icon(
                                          Icons.self_improvement,
                                          color: cs.onSurfaceVariant,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'BREATHE',
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ],
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

                // Stats
                if (_running) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statChip(cs, 'Breaths', '$_totalBreaths'),
                      const SizedBox(width: 12),
                      _statChip(
                        cs,
                        'Cycle',
                        '${(_totalBreaths % 4) + 1}/4',
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Start / Stop button
                GestureDetector(
                  onTap: _running ? _stop : _start,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
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
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _running
                            ? cs.error.withValues(alpha: 0.3)
                            : cs.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _running
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: _running ? cs.error : cs.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _running ? 'STOP' : 'START',
                          style: TextStyle(
                            color: _running ? cs.error : cs.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Instructions
                Text(
                  _running
                      ? 'Follow the circle — breathe in as it grows, out as it shrinks'
                      : '4-4-4-4 box breathing — inhale, hold, exhale, hold',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(ColorScheme cs, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: cs.primary,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              fontFamily: 'monospace',
            ),
          ),
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
    );
  }
}

class _BreathRingPainter extends CustomPainter {
  final double progress;
  final bool active;
  final Color primaryColor, mutedColor;

  _BreathRingPainter({
    required this.progress,
    required this.active,
    required this.primaryColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;

    // Outer circle
    final outerPaint = Paint()
      ..color = (active ? primaryColor : mutedColor).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r, outerPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = active
          ? primaryColor.withValues(alpha: 0.3)
          : mutedColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );

    // Inner decorative rings
    for (int i = 1; i <= 3; i++) {
      final ringPaint = Paint()
        ..color = mutedColor.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(
        Offset(cx, cy),
        r * (i / 4),
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BreathRingPainter old) =>
      old.progress != progress || old.active != active;
}
