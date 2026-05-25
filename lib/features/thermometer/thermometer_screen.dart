import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';

class ThermometerScreen extends StatefulWidget {
  const ThermometerScreen({super.key});

  @override
  State<ThermometerScreen> createState() => _ThermometerScreenState();
}

class _ThermometerScreenState extends State<ThermometerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  double _display = 22.0;
  double _target = 22.0;
  Timer? _drift;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _anim.addListener(() => setState(() {}));

    _drift = Timer.periodic(const Duration(seconds: 10), (_) {
      _target = 22.0 + (math.Random.secure().nextDouble() - 0.5) * 16.0;
      if (mounted) {
        _ctrl.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _drift?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  double get _displayAnim => _display + (_target - _display) * _ctrl.value;
  double get _f => _displayAnim * 9 / 5 + 32;
  double get _needleAngle =>
      -135.0 + ((_displayAnim + 10).clamp(0.0, 60.0) / 60.0) * 270.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Thermometer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Analog dial gauge with glow
              SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(
                  painter: _ThermoDialPainter(
                    _needleAngle,
                    primaryGlow: cs.primary,
                    secondaryGlow: cs.secondary,
                    surfaceHigh: cs.surfaceContainerHigh,
                    surfaceLow: cs.surfaceContainerLow,
                    outlineVariant: cs.outlineVariant,
                    onSurface: cs.onSurface,
                    onSurfaceVariant: cs.onSurfaceVariant,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_displayAnim.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          '°C',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // °F display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${_f.toStringAsFixed(1)} °F',
                  style: TextStyle(
                    color: cs.secondary,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Simulated  ·  Updates every 10 s',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThermoDialPainter extends CustomPainter {
  final double _needleAngle;
  final Color primaryGlow;
  final Color secondaryGlow;
  final Color surfaceHigh;
  final Color surfaceLow;
  final Color outlineVariant;
  final Color onSurface;
  final Color onSurfaceVariant;

  _ThermoDialPainter(
    this._needleAngle, {
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.surfaceHigh,
    required this.surfaceLow,
    required this.outlineVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  final _minT = -10.0, _maxT = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final outerR = size.width / 2 - 6;
    final innerR = outerR - 20;

    // Glow ring
    final glowPaint = Paint()
      ..color = primaryGlow.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(cx, cy), outerR + 8, glowPaint);

    // Outer ring
    final ring = Paint()
      ..color = outlineVariant.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), outerR, ring);

    // Inner ring (lighter)
    final innerRing = Paint()
      ..color = surfaceHigh
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), outerR - 2, innerRing);

    // Tick marks & labels
    final totalTicks = ((_maxT - _minT) / 2).round();
    for (int i = 0; i <= totalTicks; i++) {
      final t = _minT + i * 2.0;
      final frac = (t - _minT) / (_maxT - _minT);
      final angle = (-135 + frac * 270) * math.pi / 180.0;
      final cos = math.cos(angle);
      final sin = math.sin(angle);
      final big = i % 5 == 0;
      final tickR1 = outerR - 4;
      final tickR2 = big ? innerR + 8 : outerR - 14;
      canvas.drawLine(
        Offset(cx + cos * tickR1, cy + sin * tickR1),
        Offset(cx + cos * tickR2, cy + sin * tickR2),
        Paint()
          ..color = big
              ? primaryGlow.withValues(alpha: 0.7)
              : onSurface.withValues(alpha: 0.3)
          ..strokeWidth = big ? 2.5 : 1
          ..strokeCap = StrokeCap.round,
      );
      if (big) {
        final labelR = innerR - 18;
        final lx = cx + cos * labelR;
        final ly = cy + sin * labelR;
        final tp = TextPainter(
          text: TextSpan(
            text: t.toInt().toString(),
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.7),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }
    }

    // Colored arc (cold→warm→hot) with glow
    final arcPath = Path()
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerR - 1),
        -135 * math.pi / 180,
        270 * math.pi / 180,
        false,
      );

    final arcGlow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader =
          SweepGradient(
            colors: [
              secondaryGlow.withValues(alpha: 0.4),
              primaryGlow.withValues(alpha: 0.4),
              Colors.redAccent.withValues(alpha: 0.4),
            ],
            transform: const GradientRotation(135 * math.pi / 180),
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: innerR - 1),
          );
    arcGlow.style = PaintingStyle.stroke;
    arcGlow.strokeWidth = 7;
    canvas.drawPath(arcPath, arcGlow);

    final arcPaint = Paint()
      ..shader =
          SweepGradient(
            colors: [secondaryGlow, primaryGlow, Colors.redAccent],
            transform: const GradientRotation(135 * math.pi / 180),
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: innerR - 1),
          );
    arcPaint.style = PaintingStyle.stroke;
    arcPaint.strokeWidth = 4;
    canvas.drawPath(arcPath, arcPaint);

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = surfaceLow);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = primaryGlow);

    // Needle
    final ca = _needleAngle * math.pi / 180.0;
    final needleEnd = Offset(
      cx + math.cos(ca) * (innerR - 4),
      cy + math.sin(ca) * (innerR - 4),
    );

    // Needle glow
    final needleGlow = Paint()
      ..color = primaryGlow.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), needleEnd, needleGlow);

    // Needle
    final shaftPaint = Paint()
      ..color = primaryGlow
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), needleEnd, shaftPaint);
  }

  @override
  bool shouldRepaint(covariant _ThermoDialPainter old) =>
      old._needleAngle != _needleAngle;
}
