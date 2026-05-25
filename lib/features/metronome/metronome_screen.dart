import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/pulse_dot.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen>
    with SingleTickerProviderStateMixin {
  int _bpm = 120;
  bool _running = false;
  Timer? _tick;
  int _beat = 0;

  late AnimationController _pendulumCtrl;
  late Animation<double> _pendulumAnim;

  @override
  void initState() {
    super.initState();
    _pendulumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pendulumAnim = CurvedAnimation(
      parent: _pendulumCtrl,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pendulumCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _tick?.cancel();
      _pendulumCtrl.stop();
      setState(() {
        _running = false;
        _beat = 0;
      });
    } else {
      final interval = (60000 / _bpm).round();
      _tick = Timer.periodic(Duration(milliseconds: interval), (_) {
        Vibration.vibrate(duration: 15);
        setState(() {
          _beat++;
        });
        // Swing pendulum
        _pendulumCtrl.forward(from: 0);
      });
      setState(() => _running = true);
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
          particleCount: _running ? 4 : 2,
          colors: [cs.primary, cs.tertiary],
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'METRONOME',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pendulum animation
                  AnimatedBuilder(
                    animation: _pendulumAnim,
                    builder: (context, child) {
                      final swingAngle =
                          math.sin(_pendulumAnim.value * math.pi * 2) *
                          0.4; // ±23 degrees

                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: _PendulumPainter(
                          angle: swingAngle,
                          isRunning: _running,
                          isDownbeat: _running && _beat % 4 == 0,
                          primaryColor: cs.primary,
                          accentColor: cs.tertiary,
                          mutedColor: cs.onSurfaceVariant,
                          surfaceColor: cs.surfaceContainerLow,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Beat counter
                  if (_running)
                    PulseDot(
                      color: _beat % 4 == 0 ? cs.tertiary : cs.primary,
                      size: 10,
                    ),

                  const SizedBox(height: 24),

                  // BPM display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _arrowBtn(
                        cs,
                        Icons.remove_circle_outline,
                        !_running,
                        () => setState(() => _bpm = (_bpm - 5).clamp(40, 200)),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '$_bpm',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 72,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'monospace',
                              shadows: _running
                                  ? [
                                      Shadow(
                                        color: cs.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          Text(
                            'BPM',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      _arrowBtn(
                        cs,
                        Icons.add_circle_outline,
                        !_running,
                        () => setState(() => _bpm = (_bpm + 5).clamp(40, 200)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Start/Stop button
                  GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: 200,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (_running ? cs.tertiary : cs.primary).withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: (_running ? cs.tertiary : cs.primary)
                              .withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_running ? cs.tertiary : cs.primary)
                                .withValues(alpha: 0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _running ? Icons.stop : Icons.play_arrow,
                            color: _running ? cs.tertiary : cs.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _running ? 'STOP' : 'START',
                            style: TextStyle(
                              color: _running ? cs.tertiary : cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_running) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Beat ${_beat + 1}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arrowBtn(
    ColorScheme cs,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainerHigh.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 36,
          color: enabled
              ? cs.primary
              : cs.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double angle;
  final bool isRunning, isDownbeat;
  final Color primaryColor, accentColor, mutedColor, surfaceColor;

  _PendulumPainter({
    required this.angle,
    required this.isRunning,
    required this.isDownbeat,
    required this.primaryColor,
    required this.accentColor,
    required this.mutedColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final topY = size.height * 0.15;
    final pivotY = topY;
    final pendulumLen = size.height * 0.65;

    // Pivot point
    final pivot = Offset(cx, pivotY);

    // Pendulum bob position
    final bobX = cx + math.sin(angle) * pendulumLen;
    final bobY = pivotY + math.cos(angle) * pendulumLen;
    final bobPos = Offset(bobX, bobY);

    // Arc path (trace of pendulum)
    final arcPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: pendulumLen),
      -1.0 + angle,
      2.0 - angle * 2,
      false,
      arcPaint,
    );

    // Pendulum arm
    final armPaint = Paint()
      ..color = isRunning ? primaryColor : mutedColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, bobPos, armPaint);

    // Arm glow when running
    if (isRunning) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(pivot, bobPos, glowPaint);
    }

    // Bob glow
    final bobGlowPaint = Paint()
      ..color = (isDownbeat ? accentColor : primaryColor).withValues(
        alpha: 0.25,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(bobPos, 14, bobGlowPaint);

    // Bob
    final bobPaint = Paint()
      ..color = isDownbeat ? accentColor : primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bobPos, 8, bobPaint);

    // Bob highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bobX - 2, bobY - 2), 3, highlightPaint);

    // Pivot
    final pivotPaint = Paint()
      ..color = mutedColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pivot, 5, pivotPaint);
    canvas.drawCircle(
      pivot,
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _PendulumPainter old) =>
      old.angle != angle ||
      old.isRunning != isRunning ||
      old.isDownbeat != isDownbeat;
}
