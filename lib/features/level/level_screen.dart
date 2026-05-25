import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  double _sx = 0, _sy = 0;
  static const _alpha = 0.2;

  @override
  void initState() {
    super.initState();
    Sensors().accelerometerEventStream().listen((event) {
      setState(() {
        _sx = _sx + _alpha * (event.x - _sx);
        _sy = _sy + _alpha * (event.y - _sy);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pitchDeg = (math.atan2(_sy, -_sx) * 180 / math.pi).clamp(-180, 180);
    final rollDeg = (math.atan2(_sx, _sy) * 180 / math.pi).clamp(-180, 180);
    final flat = pitchDeg.abs() < 3 && rollDeg.abs() < 3;

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BUBBLE LEVEL',
                style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4),
              ),
              const SizedBox(height: 8),

              // Ring + bubble
              SizedBox(
                width: 280,
                height: 280,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cx = constraints.maxWidth / 2;
                    final cy = constraints.maxHeight / 2;
                    final ringRadius = math.min(cx, cy) - 20;
                    final bubbleR = 28.0;
                    final maxDrift = ringRadius - bubbleR - 4;

                    final dx = (_sy / 9.81 * 1.4 * maxDrift).clamp(-maxDrift, maxDrift);
                    final dy = (-_sx / 9.81 * 1.4 * maxDrift).clamp(-maxDrift, maxDrift);

                    final bx = cx + dx;
                    final by = cy + dy;

                    return Stack(
                      children: [
                        Center(
                          child: CustomPaint(
                            size: Size(ringRadius * 2 + 4, ringRadius * 2 + 4),
                            painter: _LevelRingPainter(ringRadius),
                          ),
                        ),
                        Center(
                          child: Column(
                            children: [
                              Container(width: 1.5, height: 16, color: FlamingoColors.cardBorder),
                              const SizedBox(height: 4),
                              Container(width: 1.5, height: 16, color: FlamingoColors.cardBorder),
                            ],
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            width: 6,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: FlamingoColors.cardBorder, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                        Positioned(
                          left: bx - bubbleR,
                          top: by - bubbleR,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 60),
                            width: bubbleR * 2,
                            height: bubbleR * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: flat
                                    ? [FlamingoColors.primaryLight, FlamingoColors.primary]
                                    : [FlamingoColors.neonBlue, FlamingoColors.primaryDark],
                                stops: const [0.3, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: FlamingoColors.primary.withValues(alpha: flat ? 0.6 : 0.3),
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
              ),
              const SizedBox(height: 24),

              // Digital readout
              Text(
                'P: ${pitchDeg.toStringAsFixed(1)}° / R: ${rollDeg.toStringAsFixed(1)}°',
                style: TextStyle(
                    color: FlamingoColors.text,
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 8),
              Text(
                flat ? '● LEVEL ●' : 'Not level',
                style: TextStyle(
                  color: flat ? FlamingoColors.primary : FlamingoColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  final double ringRadius;
  _LevelRingPainter(this.ringRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = FlamingoColors.primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), ringRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _LevelRingPainter old) => false;
}
