import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/flamingo_theme.dart';
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
      if (ch == null) {
        _status = 'sensor unavailable';
      } else {
        _status = 'battery_property';
      }
    });
  }

  Color _zoneColor(double? t) {
    if (t == null) return FlamingoColors.muted;
    if (t < 15) return const Color(0xFF00D4FF);
    if (t > 45) return const Color(0xFFFF4500);
    return FlamingoColors.primary;
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temp = _tempC ?? 0.0;
    final span = (temp / 65).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: FlamingoColors.scaffoldBg,
        elevation: 0,
        title: Text('BATTERY TEMP',
            style: TextStyle(
                color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 220,
                child: CustomPaint(
                  painter: _BatteryGaugePainter(
                    span: span,
                    color: _zoneColor(temp),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tempC == null
                              ? '--'
                              : '${temp.toStringAsFixed(1)}\u00B0C',
                          style: TextStyle(
                            color: FlamingoColors.text,
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _status,
                          style: TextStyle(
                            color: FlamingoColors.muted,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Zone legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _zoneDot(const Color(0xFF00D4FF)),
                  const SizedBox(width: 6),
                  Text('Cold', style: TextStyle(color: FlamingoColors.muted, fontSize: 11)),
                  const SizedBox(width: 16),
                  _zoneDot(FlamingoColors.primary),
                  const SizedBox(width: 6),
                  Text('Normal', style: TextStyle(color: FlamingoColors.muted, fontSize: 11)),
                  const SizedBox(width: 16),
                  _zoneDot(const Color(0xFFFF4500)),
                  const SizedBox(width: 6),
                  Text('Hot', style: TextStyle(color: FlamingoColors.muted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: FlamingoColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _read,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    child: Text('REFRESH',
                        style: TextStyle(
                            color: FlamingoColors.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3)),
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

Widget _zoneDot(Color c) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );

class _BatteryGaugePainter extends CustomPainter {
  final double span;
  final Color color;

  _BatteryGaugePainter({required this.span, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.68;
    final r = size.width * 0.38;

    final trackPaint = Paint()
      ..color = FlamingoColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 0.14,
      math.pi * 0.72,
      false,
      trackPaint,
    );

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 0.14,
      math.pi * 0.72 * span,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryGaugePainter old) =>
      old.span != span || old.color != color;
}
