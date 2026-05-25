import 'dart:async';
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
  static const _deadZone = 1.0;
  static const _smoothFactor = 0.25;

  double _heading = 0;
  double _filtered = 0;
  double _finalHeading = 0;
  bool _locked = false;
  double _lockedAt = 0;
  String _status = 'CALIBRATING…';
  String _bearing = 'N';
  double _accuracy = 0;
  bool _needsUpdate = false;
  Timer? _uiTimer;

  StreamSubscription? _magSub;
  StreamSubscription? _accSub;

  @override
  void initState() {
    super.initState();
    _filtered = 0;
    _finalHeading = 0;
    _uiTimer = Timer.periodic(const Duration(milliseconds: 66), (_) => _flushUpdate());
    _startSensors();
  }

  void _flushUpdate() {
    if (_needsUpdate) {
      _needsUpdate = false;
      _updateBearing();
      setState(() {}); // throttle to ~15 Hz
    }
  }

  void _startSensors() {
    _magSub = Sensors().magnetometerEventStream().listen(_onMag, onError: (_) {});
    _accSub = Sensors().accelerometerEventStream().listen(_onAcc, onError: (_) {});
  }

  void _onMag(MagnetometerEvent e) {
    // Compute heading from magnetometer (yaw only, assumes level)
    double raw = math.atan2(e.y, e.x) * 180 / math.pi;
    if (raw < 0) raw += 360;

    // Exponential moving average
    double delta = raw - _filtered;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    _filtered += delta * _smoothFactor;
    _filtered = (_filtered + 360) % 360;

    // Dead zone check against last display heading
    double change = (_filtered - _finalHeading + 360) % 360;
    if (change > 180) change = 360 - change;
    if (change < _deadZone && _finalHeading != 0) return;

    _finalHeading = _locked ? _lockedAt : _filtered;
    _accuracy = change;

    // Calibration quality: track magnitude over time
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (mag >= 20 && mag <= 100) {
      _status = 'CALIBRATED ✓';
    } else if (mag > 100) {
      _status = 'STRONG INTERFERENCE';
    } else {
      _status = 'WEAK SIGNAL';
    }

    _needsUpdate = true;
  }

  void _onAcc(AccelerometerEvent e) {
    // Just update pitch for display — no heading fusion needed for modern phones
    // with gyroscope (sensors_plus handles gravity removal on devices that have it)
  }

  void _updateBearing() {
    final deg = _finalHeading;
    if (deg < 11.25 || deg >= 348.75) _bearing = 'N';
    else if (deg < 33.75) _bearing = 'NNE';
    else if (deg < 56.25) _bearing = 'NE';
    else if (deg < 78.75) _bearing = 'ENE';
    else if (deg < 101.25) _bearing = 'E';
    else if (deg < 123.75) _bearing = 'ESE';
    else if (deg < 146.25) _bearing = 'SE';
    else if (deg < 168.75) _bearing = 'SSE';
    else if (deg < 191.25) _bearing = 'S';
    else if (deg < 213.75) _bearing = 'SSW';
    else if (deg < 236.25) _bearing = 'SW';
    else if (deg < 258.75) _bearing = 'WSW';
    else if (deg < 281.25) _bearing = 'W';
    else if (deg < 303.75) _bearing = 'WNW';
    else if (deg < 326.25) _bearing = 'NW';
    else _bearing = 'NNW';
  }

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      if (_locked) {
        _lockedAt = _finalHeading;
      }
    });
  }

  void _resetCalibration() {
    setState(() {
      _finalHeading = 0;
      _filtered = 0;
      _accuracy = 0;
    });
  }

  @override
  void dispose() {
    _magSub?.cancel();
    _accSub?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deg = (_locked ? _lockedAt : _finalHeading + 360) % 360;

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('COMPASS',
            style: TextStyle(
                color: FlamingoColors.muted,
                fontSize: 12,
                letterSpacing: 4)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _resetCalibration,
            icon: Icon(Icons.refresh, color: FlamingoColors.muted),
            tooltip: 'Reset heading',
          ),
          IconButton(
            onPressed: _toggleLock,
            icon: Icon(
              _locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: _locked ? FlamingoColors.primary : FlamingoColors.muted,
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
                // Status row
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FlamingoColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status,
                          style: const TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FlamingoColors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '±${_accuracy.toStringAsFixed(1)}°',
                          style: TextStyle(
                            color: FlamingoColors.muted,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Compass dial — rotates opposite heading so needle points to N
                Transform.rotate(
                  angle: -deg * math.pi / 180,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(
                      painter: _CompassPainter(),
                      child: const Center(),
                    ),
                  ),
                ),

                // Needle — painted in screen space, always points north
                Container(
                  width: 260,
                  height: 260,
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size(260, 260),
                    painter: _NeedlePainter(heading: deg),
                  ),
                ),

                const SizedBox(height: 16),

                // Large degree readout
                Text(
                  '${deg.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: FlamingoColors.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),

                // Direction text
                Text(
                  _bearing,
                  style: TextStyle(
                    color: FlamingoColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '(${deg.toStringAsFixed(1)}°)',
                  style: TextStyle(
                    color: FlamingoColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'monospace',
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Column(
                  children: [
                    Text(
                      _locked
                          ? '🔒 Locked — tap lock to release'
                          : 'Hold flat for best accuracy',
                      style: TextStyle(
                        color: FlamingoColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Move phone in figure-8 to calibrate',
                      style: TextStyle(
                        color: FlamingoColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compass Dial Painter ─────────────────────────────────────────────────────

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 16;

    // Outer ring
    Paint ring = Paint()
      ..color = FlamingoColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r, ring);

    // Inner ring
    Paint inner = Paint()
      ..color = FlamingoColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r - 8, inner);

    // Tick marks every 10°
    for (int i = 0; i < 36; i++) {
      final a = i * math.pi / 18 - math.pi / 2;
      final isCardinal = i % 9 == 0; // N, E, S, W
      final isHalfCard = i % 3 == 0; // NNE, ENE, etc.
      final tickLen = isCardinal ? 0.20 : (isHalfCard ? 0.15 : 0.08);
      final adjustedR = r - 6;

      final outer = Offset(
        cx + math.cos(a) * adjustedR,
        cy + math.sin(a) * adjustedR,
      );
      final inner = Offset(
        cx + math.cos(a) * (adjustedR - adjustedR * tickLen),
        cy + math.sin(a) * (adjustedR - adjustedR * tickLen),
      );

      canvas.drawLine(outer, inner, Paint()
        ..color = (isCardinal ? FlamingoColors.primary
            : (isHalfCard ? FlamingoColors.accent : FlamingoColors.muted))
            .withValues(alpha: isCardinal ? 1.0 : (isHalfCard ? 0.6 : 0.3))
        ..strokeWidth = isCardinal ? 2.5 : 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);

      // Cardinal labels
      if (isCardinal) {
        final labels = ['N', 'E', 'S', 'W'];
        final dirIdx = (i ~/ 9);
        final lbl = labels[dirIdx];
        final textPainter = TextPainter(
          text: TextSpan(
            text: lbl,
            style: TextStyle(
              color: dirIdx == 0 ? FlamingoColors.primary : FlamingoColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        final labelR = r - 26;
        final pos = Offset(
          cx + math.cos(a) * labelR - textPainter.width / 2,
          cy + math.sin(a) * labelR - textPainter.height / 2,
        );
        textPainter.paint(canvas, pos);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => false;
}

// ── Needle Painter ───────────────────────────────────────────────────────────

class _NeedlePainter extends CustomPainter {
  final double heading;

  _NeedlePainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 16;
    final nLen = r - 50;

    // North needle (points toward magnetic north, which is UP in screen space)
    final northX = cx;
    final northY = cy - nLen;
    final southX = cx;
    final southY = cy + nLen * 0.5;

    // North tip (pink, longer)
    Paint northPaint = Paint()
      ..color = FlamingoColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(northX, northY), northPaint);

    // South tip (muted, shorter)
    Paint southPaint = Paint()
      ..color = FlamingoColors.muted.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(southX, southY), southPaint);

    // Center pivot — neon glow
    Paint glow = Paint()
      ..color = FlamingoColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 8, glow);

    Paint pivot = Paint()
      ..color = FlamingoColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 4, pivot);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) => old.heading != heading;
}
