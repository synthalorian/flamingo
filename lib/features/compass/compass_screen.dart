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

class _CompassScreenState extends State<CompassScreen>
    with SingleTickerProviderStateMixin {
  static const _deadZone = 1.5; // ° — ignore fluctuations smaller than this
  static const _smoothFactor = 0.25; // exponential moving average weight

  double _heading = 0;   // smoothed heading
  double _filtered = 0;  // EMA accumulator
  bool _locked = false;
  double _lockedAt = 0;

  @override
  void initState() {
    super.initState();
    _filtered = 0;
    Sensors().magnetometerEventStream().listen(_onSensor);
  }

  void _onSensor(MagnetometerEvent e) {
    if (!mounted) return;
    // atan2(y, x) — note: swapped from old version
    double raw = math.atan2(e.y, e.x) * 180 / math.pi;
    if (raw < 0) raw += 360;

    // Exponential moving average to smooth jitter
    double delta = raw - _filtered;
    // Handle wrap-around (359 → 2 is a backward hop, not 357°)
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    _filtered += delta * _smoothFactor;
    _filtered = (_filtered + 360) % 360;

    // Dead zone — only update if change exceeds threshold
    double change = (_filtered - _heading + 360) % 360;
    if (change > 180) change = 360 - change;
    if (change < _deadZone) return;

    setState(() {
      _heading = _locked ? _lockedAt : _filtered;
    });
  }

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      if (_locked) {
        _lockedAt = _heading;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deg = (_heading + 360) % 360;
    final dir = _direction(deg);

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: FlamingoColors.scaffoldBg,
        elevation: 0,
        title: const Text('COMPASS',
            style: TextStyle(
                color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleLock,
            icon: Icon(
              _locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: _locked ? FlamingoColors.accent : FlamingoColors.muted,
            ),
          ),
        ],
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Dial rotates opposite to heading so needle points UP → N
                Transform.rotate(
                  angle: -deg * math.pi / 180,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(
                      painter: _CompassPainter(),
                      child: const Center(), // needle painted in dial
                    ),
                  ),
                ),
                // Needle (pointing up, painted in widget coords)
                const SizedBox(height: 0),
                Container(
                  width: 260,
                  height: 260,
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size(260, 260),
                    painter: _NeedlePainter(deg: deg),
                  ),
                ),
                const SizedBox(height: 12),
                // Value output
                Text(
                  '${deg.toStringAsFixed(1)}\u00B0',
                  style: const TextStyle(
                    color: FlamingoColors.text,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dir,
                  style: const TextStyle(
                    color: FlamingoColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _locked ? 'Locked — tap lock to release'
                      : 'Calibrate • Tap lock icon to fix',
                  style: const TextStyle(
                    color: FlamingoColors.muted,
                    fontSize: 11,
                  ),
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

// Compass dial — rotates opposite heading, so N card stays at TOP
class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 16;

    Paint ring = Paint()
      ..color = FlamingoColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r, ring);

    Paint inner = Paint()
      ..color = FlamingoColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r - 8, inner);

    // Cardinal tick marks every 15° — N and S prominent
    for (int i = 0; i < 24; i++) {
      final a = i * math.pi / 12 - math.pi / 2;
      final isCardinal = i % 6 == 0;
      final factor = isCardinal ? 0.18 : 0.1;
      final adjustedR = r - 6;
      canvas.drawLine(
          Offset(cx + math.cos(a) * (r - 6),
              cy + math.sin(a) * (r - 6)),
          Offset(cx + math.cos(a) * (r - 6 - adjustedR * factor),
              cy + math.sin(a) * (r - 6 - adjustedR * factor)),
          Paint()
            ..color = isCardinal ? FlamingoColors.accent : FlamingoColors.muted
            ..strokeWidth = isCardinal ? 2 : 1
            ..style = PaintingStyle.stroke);

      // N/S/E/W labels
      if (isCardinal) {
        final labels = ['N', 'E', 'S', 'W'];
        final dirIdx = (i ~/ 6);
        final lbl = labels[dirIdx];
        final textPainter = TextPainter(
          text: TextSpan(
            text: lbl,
            style: TextStyle(
              color: dirIdx == 0 ? FlamingoColors.primary : FlamingoColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        final labelR = r - 24;
        final pos = Offset(
          cx + math.cos(a) * labelR - textPainter.width / 2,
          cy + math.sin(a) * labelR - textPainter.height / 2,
        );
        textPainter.paint(canvas, pos);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => true;
}

// Central needle (painted in screen space, NOT rotated with dial)
class _NeedlePainter extends CustomPainter {
  final double deg;
  _NeedlePainter({required this.deg});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 16;

    // Needle: tip at center, swept arc for both arms
    final nLen = r - 46;
    Paint needlePaint = Paint()
      ..color = FlamingoColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // North-tip (pointing left-ish toward heading direction)
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + math.sin(deg * math.pi / 180) * nLen,
          cy - math.cos(deg * math.pi / 180) * nLen),
      needlePaint,
    );

    Paint southPaint = Paint()
      ..color = FlamingoColors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx - math.sin(deg * math.pi / 180) * nLen * 0.6,
          cy + math.cos(deg * math.pi / 180) * nLen * 0.6),
      southPaint,
    );

    // Center pivot
    Paint pivot = Paint()..color = FlamingoColors.accent..style = PaintingStyle.fill..strokeWidth = 0;
    canvas.drawCircle(Offset(cx, cy), 5, pivot);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) => old.deg != deg;
}
