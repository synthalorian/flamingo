import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with SingleTickerProviderStateMixin {
  double _sx = 0, _sy = 0;
  static const _alpha = 0.2;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    Sensors().accelerometerEventStream().listen((event) {
      setState(() {
        _sx = _sx + _alpha * (event.x - _sx);
        _sy = _sy + _alpha * (event.y - _sy);
      });
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final pitchDeg = (math.atan2(_sy, -_sx) * 180 / math.pi).clamp(-180, 180);
    final rollDeg = (math.atan2(_sx, _sy) * 180 / math.pi).clamp(-180, 180);
    final flat = pitchDeg.abs() < 3 && rollDeg.abs() < 3;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: 3,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BUBBLE LEVEL',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),

                // Level indicator
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) {
                    return SizedBox(
                      width: 280,
                      height: 280,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cx = constraints.maxWidth / 2;
                          final cy = constraints.maxHeight / 2;
                          final ringRadius = math.min(cx, cy) - 20;
                          final bubbleR = 28.0;
                          final maxDrift = ringRadius - bubbleR - 4;

                          final dx = (_sy / 9.81 * 1.4 * maxDrift).clamp(
                            -maxDrift,
                            maxDrift,
                          );
                          final dy = (-_sx / 9.81 * 1.4 * maxDrift).clamp(
                            -maxDrift,
                            maxDrift,
                          );

                          final bx = cx + dx;
                          final by = cy + dy;

                          return Stack(
                            children: [
                              // Outer glow ring
                              Center(
                                child: Container(
                                  width: ringRadius * 2 + 16,
                                  height: ringRadius * 2 + 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: flat
                                        ? [
                                            BoxShadow(
                                              color: cs.primary.withValues(
                                                alpha: 0.1 * _glowAnim.value,
                                              ),
                                              blurRadius: 30,
                                              spreadRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),

                              // Ring
                              Center(
                                child: CustomPaint(
                                  size: Size(
                                    ringRadius * 2 + 4,
                                    ringRadius * 2 + 4,
                                  ),
                                  painter: _LevelRingPainter(
                                    ringRadius: ringRadius,
                                    isFlat: flat,
                                    primaryColor: cs.primary,
                                    tertiaryColor: cs.tertiary,
                                    mutedColor: cs.onSurfaceVariant,
                                    glowIntensity: _glowAnim.value,
                                  ),
                                ),
                              ),

                              // Crosshair lines
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 1.5,
                                      height: 20,
                                      color: cs.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 1.5,
                                      height: 20,
                                      color: cs.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Center(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 1.5,
                                      color: cs.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 20,
                                      height: 1.5,
                                      color: cs.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Bubble
                              Positioned(
                                left: bx - bubbleR,
                                top: by - bubbleR,
                                child: Container(
                                  width: bubbleR * 2,
                                  height: bubbleR * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: flat
                                          ? [
                                              cs.primary,
                                              cs.primary.withValues(alpha: 0.6),
                                            ]
                                          : [
                                              cs.secondary,
                                              cs.secondary.withValues(
                                                alpha: 0.5,
                                              ),
                                            ],
                                      stops: const [0.3, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (flat ? cs.primary : cs.secondary)
                                                .withValues(
                                                  alpha: flat ? 0.6 : 0.3,
                                                ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Digital readout
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: flat
                          ? cs.primary.withValues(alpha: 0.2)
                          : cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Text(
                            'PITCH',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${pitchDeg.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 20,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: 1,
                          height: 30,
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'ROLL',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${rollDeg.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 20,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Level status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: flat
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: flat ? cs.primary : cs.onSurfaceVariant,
                          boxShadow: flat
                              ? [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        flat ? '● LEVEL' : 'Not level',
                        style: TextStyle(
                          color: flat ? cs.primary : cs.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  final double ringRadius;
  final bool isFlat;
  final Color primaryColor, tertiaryColor, mutedColor;
  final double glowIntensity;

  _LevelRingPainter({
    required this.ringRadius,
    required this.isFlat,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.mutedColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Ring glow
    if (isFlat) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.08 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(Offset(cx, cy), ringRadius + 2, glowPaint);
    }

    // Main ring
    final paint = Paint()
      ..color = isFlat
          ? primaryColor.withValues(alpha: 0.4)
          : mutedColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), ringRadius, paint);

    // Concentric guide rings
    for (double r = ringRadius * 0.25; r < ringRadius; r += ringRadius * 0.25) {
      final guide = Paint()
        ..color = mutedColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(Offset(cx, cy), r, guide);
    }

    // Tolerance ring (indicates "level" zone)
    final tolerancePaint = Paint()
      ..color = (isFlat ? primaryColor : mutedColor).withValues(
        alpha: isFlat ? 0.2 : 0.08,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), ringRadius * 0.3, tolerancePaint);
  }

  @override
  bool shouldRepaint(covariant _LevelRingPainter old) =>
      old.isFlat != isFlat || old.ringRadius != ringRadius;
}
