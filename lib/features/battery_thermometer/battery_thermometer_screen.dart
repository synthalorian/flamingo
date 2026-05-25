import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/utils/battery_channel.dart';

class BatteryThermometerScreen extends StatefulWidget {
  const BatteryThermometerScreen({super.key});

  @override
  State<BatteryThermometerScreen> createState() =>
      _BatteryThermometerScreenState();
}

class _BatteryThermometerScreenState extends State<BatteryThermometerScreen> {
  double? _tempC;
  String _status = 'reading...';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _read();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _read());
  }

  Future<void> _read() async {
    final ch = await BatteryChannel.getTemperatureC();
    if (!mounted) return;
    setState(() {
      _tempC = ch;
      _status = ch == null ? 'sensor unavailable' : 'battery_property';
    });
  }

  Color _zoneColor(double? t, ColorScheme cs) {
    if (t == null) return cs.onSurfaceVariant;
    if (t < 15) return cs.secondary;
    if (t > 45) return Colors.redAccent;
    return cs.primary;
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  String _zoneLabel(double? t) {
    if (t == null) return '';
    if (t < 15) return 'Cold';
    if (t > 45) return 'Hot';
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final temp = _tempC ?? 0.0;
    final span = (temp / 65).clamp(0.0, 1.0);
    final zc = _zoneColor(_tempC, cs);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.battery_charging_full, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'BATTERY TEMP',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gauge with glow
              SizedBox(
                width: 300,
                height: 240,
                child: CustomPaint(
                  painter: _BatteryGaugePainter(
                    span: span,
                    color: zc,
                    primaryGlow: cs.primary,
                    surfaceHigh: cs.surfaceContainerHigh,
                    surfaceLow: cs.surfaceContainerLow,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'monospace',
                          ),
                          child: Text(
                            _tempC == null
                                ? '--'
                                : '${temp.toStringAsFixed(1)}°C',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: zc.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _zoneLabel(_tempC),
                            style: TextStyle(
                              color: zc,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _status,
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Zone legend
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _zoneDot(cs.secondary, cs),
                    const SizedBox(width: 6),
                    Text(
                      'Cold',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _zoneDot(cs.primary, cs),
                    const SizedBox(width: 6),
                    Text(
                      'Normal',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _zoneDot(Colors.redAccent, cs),
                    const SizedBox(width: 6),
                    Text(
                      'Hot',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: cs.primary.withValues(alpha: 0.15),
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _read,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'REFRESH',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _zoneDot(Color c, ColorScheme cs) => Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    color: c,
    shape: BoxShape.circle,
    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 4)],
  ),
);

class _BatteryGaugePainter extends CustomPainter {
  final double span;
  final Color color;
  final Color primaryGlow;
  final Color surfaceHigh;
  final Color surfaceLow;

  _BatteryGaugePainter({
    required this.span,
    required this.color,
    required this.primaryGlow,
    required this.surfaceHigh,
    required this.surfaceLow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.68;
    final r = size.width * 0.38;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r + 4),
      math.pi * 0.14,
      math.pi * 0.72,
      false,
      glowPaint,
    );

    // Track
    final trackPaint = Paint()
      ..color = surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 0.14,
      math.pi * 0.72,
      false,
      trackPaint,
    );

    // Fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 0.14,
      math.pi * 0.72 * span,
      false,
      fillPaint,
    );

    // End cap
    if (span > 0.01) {
      final endAngle = math.pi * 0.14 + math.pi * 0.72 * span;
      final ex = cx + math.cos(endAngle) * r;
      final ey = cy + math.sin(endAngle) * r;
      canvas.drawCircle(Offset(ex, ey), 8, Paint()..color = color);
      canvas.drawCircle(Offset(ex, ey), 4, Paint()..color = surfaceLow);
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryGaugePainter old) =>
      old.span != span || old.color != color;
}
