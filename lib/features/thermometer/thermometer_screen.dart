import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class ThermometerScreen extends StatefulWidget {
  const ThermometerScreen({super.key});

  @override
  State<ThermometerScreen> createState() => _ThermometerScreenState();
}

class _ThermometerScreenState extends State<ThermometerScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  double _display = 22.0; // °C
  Timer? _drift;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // Drift temperature ±8 °C around 22 °C every 10 s
    _drift = Timer.periodic(const Duration(seconds: 10), (_) {
      final target = 22.0 + (math.Random.secure().nextDouble() - 0.5) * 16.0;
      if (mounted) {
          _display = target;
        _ctrl.forward(from: 0).ignore();
      }
    });
  }

  @override
  void dispose() {
    _drift?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  double get _f => _display * 9 / 5 + 32;
  double get _needleAngle => -135.0 + ((_display + 10).clamp(0.0, 60.0) / 60.0) * 270.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Thermometer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FlamingoColors.text,
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Analog dial gauge
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _ThermoDialPainter(_needleAngle),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_display.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: FlamingoColors.text,
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              '°C',
                              style: TextStyle(color: FlamingoColors.muted, fontSize: 14, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // °F under the dial
              Text(
                '${_f.toStringAsFixed(1)} °F',
                style: TextStyle(color: FlamingoColors.accent, fontFamily: 'monospace', fontSize: 15, letterSpacing: 2),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: FlamingoColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FlamingoColors.cardBorder),
                ),
                child: Text(
                  'Updates every 10 s  ·  Simulated',
                  style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 2),
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
  _ThermoDialPainter(this._needleAngle);
  final double _needleAngle; // degrees, -135 to +135
  final _minT = -10.0, _maxT = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final outerR = size.width / 2 - 6;
    final innerR = outerR - 18;

    // Ring
    final ring = Paint()
      ..color = FlamingoColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), outerR, ring);

    // Tick marks & labels
    final totalTicks = ((_maxT - _minT) / 2).round(); // every 2 °C -> tick
    for (int i = 0; i <= totalTicks; i++) {
      final t = _minT + i * 2.0;
      final frac = (t - _minT) / (_maxT - _minT);
      final angle = (-135 + frac * 270) * math.pi / 180.0;
      final cos = math.cos(angle);
      final sin = math.sin(angle);
      final big = i % 5 == 0;
      final tickR1 = outerR - 4;
      final tickR2 = big ? innerR + 6 : outerR - 12;
      canvas.drawLine(
        Offset(cx + cos * tickR1, cy + sin * tickR1),
        Offset(cx + cos * tickR2, cy + sin * tickR2),
        Paint()
          ..color = big ? FlamingoColors.primary : FlamingoColors.text.withValues(alpha: 0.4)
          ..strokeWidth = big ? 2 : 1
          ..style = PaintingStyle.stroke,
      );
      if (big) {
        final labelR = innerR - 16;
        final lx = cx + cos * labelR;
        final ly = cy + sin * labelR;
        final tp = TextPainter(
          text: TextSpan(text: t.toInt().toString(), style: TextStyle(color: FlamingoColors.text, fontSize: 10, fontFamily: 'monospace')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }
    }

    // Colored arc (cold→warm→hot)
    final arcPath = Path()
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: innerR - 2), -135 * math.pi / 180, 270 * math.pi / 180, false);
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [const Color(0xFF00D4FF), const Color(0xFF69B4FF), Colors.redAccent],
        transform: const GradientRotation(135 * math.pi / 180),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: innerR - 2));
    arcPaint.style = PaintingStyle.stroke;
    arcPaint.strokeWidth = 5;
    canvas.drawPath(arcPath, arcPaint);

    // Shaft
    final shaftPaint = Paint()
      ..color = FlamingoColors.cardBorder
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final ca = _needleAngle * math.pi / 180.0;
    canvas.drawLine(Offset(cx, cy), Offset(cx + math.cos(ca) * (innerR - 6), cy + math.sin(ca) * (innerR - 6)), shaftPaint);
  }

  @override
  bool shouldRepaint(covariant _ThermoDialPainter old) => old._needleAngle != _needleAngle;
}
