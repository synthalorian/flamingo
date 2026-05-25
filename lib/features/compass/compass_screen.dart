import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/glow_container.dart';
import '../../core/widgets/pulse_dot.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen>
    with SingleTickerProviderStateMixin {
  static const _deadZone = 0.5;
  static const _smoothFactor = 0.3;

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

  // Animation
  late AnimationController _animCtrl;
  late Animation<double> _smoothAnim;
  double _targetHeading = 0;
  double _displayHeading = 0;

  StreamSubscription? _magSub;
  StreamSubscription? _accSub;

  @override
  void initState() {
    super.initState();
    _filtered = 0;
    _finalHeading = 0;
    _displayHeading = 0;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _smoothAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );

    _uiTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _tickAnimation(),
    );
    _startSensors();
  }

  void _tickAnimation() {
    if (_animCtrl.isCompleted || !_animCtrl.isAnimating) {
      // Smoothly glide toward target
      final diff = _targetHeading - _displayHeading;
      if (diff.abs() > 0.1) {
        _displayHeading += diff * 0.15;
        _updateBearing();
        setState(() {});
      }
    }
  }

  void _startSensors() {
    _magSub = Sensors().magnetometerEventStream().listen(
      _onMag,
      onError: (_) {},
    );
    _accSub = Sensors().accelerometerEventStream().listen(
      _onAcc,
      onError: (_) {},
    );
  }

  void _onMag(MagnetometerEvent e) {
    double raw = math.atan2(e.y, e.x) * 180 / math.pi;
    if (raw < 0) raw += 360;

    // Exponential moving average
    double delta = raw - _filtered;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    _filtered += delta * _smoothFactor;
    _filtered = (_filtered + 360) % 360;

    // Dead zone check
    double change = (_filtered - _finalHeading + 360) % 360;
    if (change > 180) change = 360 - change;
    if (change < _deadZone && _finalHeading != 0) return;

    _finalHeading = _locked ? _lockedAt : _filtered;
    _accuracy = change;

    // Set animation target
    final newTarget = (_locked ? _lockedAt : _filtered + 360) % 360;
    _targetHeading = newTarget;
    _animCtrl.forward(from: 0);

    // Calibration quality
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (mag >= 20 && mag <= 100) {
      _status = 'CALIBRATED';
    } else if (mag > 100) {
      _status = 'INTERFERENCE';
    } else {
      _status = 'WEAK SIGNAL';
    }

    _needsUpdate = true;
  }

  void _onAcc(AccelerometerEvent e) {}

  void _updateBearing() {
    final deg = _displayHeading;
    if (deg < 11.25 || deg >= 348.75)
      _bearing = 'N';
    else if (deg < 33.75)
      _bearing = 'NNE';
    else if (deg < 56.25)
      _bearing = 'NE';
    else if (deg < 78.75)
      _bearing = 'ENE';
    else if (deg < 101.25)
      _bearing = 'E';
    else if (deg < 123.75)
      _bearing = 'ESE';
    else if (deg < 146.25)
      _bearing = 'SE';
    else if (deg < 168.75)
      _bearing = 'SSE';
    else if (deg < 191.25)
      _bearing = 'S';
    else if (deg < 213.75)
      _bearing = 'SSW';
    else if (deg < 236.25)
      _bearing = 'SW';
    else if (deg < 258.75)
      _bearing = 'WSW';
    else if (deg < 281.25)
      _bearing = 'W';
    else if (deg < 303.75)
      _bearing = 'WNW';
    else if (deg < 326.25)
      _bearing = 'NW';
    else
      _bearing = 'NNW';
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
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final deg = _displayHeading;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'COMPASS',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _resetCalibration,
            icon: Icon(Icons.refresh, color: cs.onSurfaceVariant),
            tooltip: 'Reset',
          ),
          IconButton(
            onPressed: _toggleLock,
            icon: Icon(
              _locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: _locked ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: 4,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status badges
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statusBadge(
                          _status,
                          _status == 'CALIBRATED' ? cs.secondary : cs.tertiary,
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(
                          '±${_accuracy.toStringAsFixed(1)}°',
                          cs.onSurfaceVariant,
                        ),
                        if (_locked) ...[
                          const SizedBox(width: 8),
                          _statusBadge('LOCKED', cs.primary),
                        ],
                      ],
                    ),
                  ),

                  // Compass dial
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating dial
                        AnimatedBuilder(
                          animation: _smoothAnim,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: -deg * math.pi / 180,
                              child: CustomPaint(
                                size: const Size(280, 280),
                                painter: _CompassRosePainter(
                                  primaryColor: cs.primary,
                                  secondaryColor: cs.secondary,
                                  tertiaryColor: cs.tertiary,
                                  surfaceColor: cs.surfaceContainerLow,
                                  textColor: cs.onSurface,
                                  mutedColor: cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),

                        // Fixed needle overlay
                        IgnorePointer(
                          child: CustomPaint(
                            size: const Size(280, 280),
                            painter: _NeedlePainter(
                              primaryColor: cs.primary,
                              tertiaryColor: cs.tertiary,
                              mutedColor: cs.onSurfaceVariant,
                            ),
                          ),
                        ),

                        // Center cap with glow
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                cs.tertiary,
                                cs.tertiary.withValues(alpha: 0.5),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.tertiary.withValues(alpha: 0.6),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Large degree readout
                  Text(
                    '${deg.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                      shadows: [
                        Shadow(
                          color: cs.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Direction text with glow
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation, color: cs.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _bearing,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instructions
                  Text(
                    _locked
                        ? '🔒 Heading locked'
                        : 'Hold flat · Move in figure-8 to calibrate',
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Beautiful Compass Rose Painter ──
class _CompassRosePainter extends CustomPainter {
  final Color primaryColor,
      secondaryColor,
      tertiaryColor,
      surfaceColor,
      textColor,
      mutedColor;

  _CompassRosePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 16;

    // Outer glow ring
    final glowRing = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(Offset(cx, cy), r + 4, glowRing);

    // Outer ring
    final outerRing = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), r, outerRing);

    // Inner precision ring
    final innerRing = Paint()
      ..color = mutedColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(Offset(cx, cy), r - 12, innerRing);

    // Concentric guide rings
    for (int i = 1; i <= 3; i++) {
      final guide = Paint()
        ..color = mutedColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(Offset(cx, cy), r - i * (r / 4), guide);
    }

    // Tick marks - every 2 degrees
    for (int i = 0; i < 180; i++) {
      final angle = (i * 2) * math.pi / 180 - math.pi / 2;
      final isCardinal = i % 45 == 0;
      final isMajor = i % 15 == 0;
      final isMedium = i % 5 == 0;

      double tickLen;
      double strokeW;
      Color color;

      if (isCardinal) {
        tickLen = 0.28;
        strokeW = 3;
        color = primaryColor;
      } else if (isMajor) {
        tickLen = 0.22;
        strokeW = 2;
        color = tertiaryColor.withValues(alpha: 0.7);
      } else if (isMedium) {
        tickLen = 0.18;
        strokeW = 1.2;
        color = mutedColor.withValues(alpha: 0.5);
      } else {
        tickLen = 0.12;
        strokeW = 0.8;
        color = mutedColor.withValues(alpha: 0.25);
      }

      final adjustedR = r - 4;
      final outer = Offset(
        cx + math.cos(angle) * adjustedR,
        cy + math.sin(angle) * adjustedR,
      );
      final inner = Offset(
        cx + math.cos(angle) * (adjustedR - adjustedR * tickLen),
        cy + math.sin(angle) * (adjustedR - adjustedR * tickLen),
      );

      canvas.drawLine(
        outer,
        inner,
        Paint()
          ..color = color
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );

      // Cardinal labels with neon glow
      if (isCardinal) {
        final labels = ['N', 'E', 'S', 'W'];
        final dirIdx = (i ~/ 45);
        final isNorth = dirIdx == 0;
        final labelColor = isNorth
            ? primaryColor
            : textColor.withValues(alpha: 0.7);

        // Glow for N
        if (isNorth) {
          final glowTp = TextPainter(
            text: TextSpan(
              text: 'N',
              style: TextStyle(
                color: primaryColor.withValues(alpha: 0.3),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout();
          final glowR = r - 38;
          final glowPos = Offset(
            cx + math.cos(angle) * glowR - glowTp.width / 2,
            cy + math.sin(angle) * glowR - glowTp.height / 2,
          );
          glowTp.paint(canvas, glowPos);
        }

        final tp = TextPainter(
          text: TextSpan(
            text: labels[dirIdx],
            style: TextStyle(
              color: labelColor,
              fontSize: isNorth ? 20 : 15,
              fontWeight: isNorth ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        final labelR = r - 38;
        final pos = Offset(
          cx + math.cos(angle) * labelR - tp.width / 2,
          cy + math.sin(angle) * labelR - tp.height / 2,
        );
        tp.paint(canvas, pos);
      }

      // Sub-cardinal labels (NE, SE, SW, NW)
      if (isMajor && !isCardinal) {
        final subLabels = ['NE', 'SE', 'SW', 'NW'];
        final subIdx = (i ~/ 45);
        if (subIdx < subLabels.length) {
          final tp = TextPainter(
            text: TextSpan(
              text: subLabels[subIdx],
              style: TextStyle(
                color: mutedColor.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout();
          final labelR = r - 32;
          final pos = Offset(
            cx + math.cos(angle) * labelR - tp.width / 2,
            cy + math.sin(angle) * labelR - tp.height / 2,
          );
          tp.paint(canvas, pos);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompassRosePainter old) => false;
}

// ── Needle Painter ──
class _NeedlePainter extends CustomPainter {
  final Color primaryColor, tertiaryColor, mutedColor;

  _NeedlePainter({
    required this.primaryColor,
    required this.tertiaryColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 16;
    final nLen = r - 48;

    // North needle - longer, pink/red with glow
    final northTip = Offset(cx, cy - nLen);

    // Glow trail for north needle
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), northTip, glowPaint);

    // North needle body
    final northPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), northTip, northPaint);

    // North needle filled triangle tip
    final northTriPath = Path()
      ..moveTo(cx, cy - nLen)
      ..lineTo(cx - 5, cy - nLen + 14)
      ..lineTo(cx + 5, cy - nLen + 14)
      ..close();
    canvas.drawPath(
      northTriPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
    );

    // South needle - shorter, gray
    final southTip = Offset(cx, cy + nLen * 0.55);
    final southPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), southTip, southPaint);

    // Center pivot glow
    final pivotGlow = Paint()
      ..color = tertiaryColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy), 12, pivotGlow);

    // Center pivot
    final pivot = Paint()
      ..color = tertiaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 5, pivot);

    // Inner pivot dot
    final pivotInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 2.5, pivotInner);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) => false;
}
