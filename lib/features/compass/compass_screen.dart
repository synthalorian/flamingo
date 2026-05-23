import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> with SingleTickerProviderStateMixin {
  double _heading = 0;
  late AnimationController _ctrl;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _rotation = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    
    Sensors().magnetometerEventStream().listen((event) {
      double heading = math.atan2(event.x, event.y) * 180 / math.pi;
      if (heading < 0) heading += 360;
      setState(() => _heading = heading);
      _ctrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deg = ((_heading % 360) + 360) % 360;
    final dir = _direction(deg);

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('COMPASS', style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
                const SizedBox(height: 24),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: RotationTransition(
                    turns: _rotation,
                    child: CustomPaint(
                      painter: _CompassPainter(deg),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              deg.toStringAsFixed(1),
                              style: const TextStyle(
                                color: FlamingoColors.text,
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dir,
                              style: const TextStyle(
                                color: FlamingoColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tap to lock',
                  style: TextStyle(color: FlamingoColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _direction(double deg) {
    if (deg < 22.5 || deg >= 337.5) return 'N';
    if (deg < 67.5) return 'NE';
    if (deg < 112.5) return 'E';
    if (deg < 157.5) return 'SE';
    if (deg < 202.5) return 'S';
    if (deg < 247.5) return 'SW';
    if (deg < 292.5) return 'W';
    return 'NW';
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  _CompassPainter(this.heading);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 16;

    Paint ring = Paint()
      ..color = FlamingoColors.primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), r, ring);

    Paint inner = Paint()
      ..color = FlamingoColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r - 8, inner);

    // Cardinal directions at N, E, S, W
    final positions = <Offset>[
      Offset(cx, cy - r + 30), // N
      Offset(cx + r - 24, cy), // E
      Offset(cx, cy + r - 30), // S
      Offset(cx - r + 24, cy), // W
    ];

    for (final pos in positions) {
      final p = Paint()..color = FlamingoColors.accent..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 1, p);
    }

    // Needle
    final nLen = r - 40;
    final needlePaint = Paint()
      ..color = FlamingoColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + math.sin(heading * math.pi / 180) * nLen, cy - math.cos(heading * math.pi / 180) * nLen),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.heading != heading;
}
