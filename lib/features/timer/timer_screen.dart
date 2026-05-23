import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

/// Preset durations in minutes.
const List<int> kPresets = [1, 2, 5, 10, 15, 30];

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Duration _total = const Duration(minutes: 5);
  Duration _remaining = const Duration(minutes: 5);
  bool _running = false;
  bool _finished = false;
  Timer? _timer;

  // ── Actions ────────────────────────────────────────────────

  void _start() {
    if (_running || _remaining.inSeconds <= 0) return;
    setState(() { _running = true; _finished = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _timer?.cancel();
        _onComplete();
        return;
      }
      setState(() => _remaining = Duration(seconds: _remaining.inSeconds - 1));
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _total;
      _finished = false;
    });
  }

  void _onComplete() {
    setState(() {
      _running = false;
      _finished = true;
    });
    Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 300]);
    _showDoneDialog();
  }

  void _showDoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: FlamingoColors.card,
        title: const Text('Timer Done!',
            style: TextStyle(color: FlamingoColors.primary)),
        content:
            const Text("Time's up.", style: TextStyle(color: FlamingoColors.text)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _remaining = _total;
                _finished = false;
              });
            },
            child: const Text('OK',
                style: TextStyle(color: FlamingoColors.neonBlue)),
          ),
        ],
      ),
    );
  }

  void _setDuration(int minutes) {
    _timer?.cancel();
    setState(() {
      _total = Duration(minutes: minutes);
      _remaining = Duration(minutes: minutes);
      _running = false;
      _finished = false;
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fraction = _total.inSeconds > 0
        ? (_remaining.inSeconds / _total.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Preset chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: kPresets.map((m) {
                    final active =
                        _total.inMinutes == m && !_running;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _presetChip(m, active),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Circular countdown
              Expanded(
                flex: 3,
                child: Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: CustomPaint(
                      painter: _TimerCirclePainter(
                        fraction: fraction,
                      ),
                      child: Center(
                        child: Text(
                          _format(_remaining),
                          style: const TextStyle(
                            color: FlamingoColors.text,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_running && !_finished)
                    _timerBtn('START', FlamingoColors.primary, _start)
                  else if (_running)
                    _timerBtn('PAUSE', FlamingoColors.accent, _pause)
                  else
                    _timerBtn('AGAIN', FlamingoColors.primary, () {
                      _remaining = _total;
                      _finished = false;
                      setState(() {});
                    }),
                  const SizedBox(width: 20),
                  _timerBtn('CANCEL', FlamingoColors.muted, _cancel),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────

  Widget _presetChip(int minutes, bool active) {
    return Material(
      color: active
          ? FlamingoColors.primary.withValues(alpha: 0.2)
          : FlamingoColors.card,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _setDuration(minutes),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('$minutes min',
              style: TextStyle(
                  color:
                      active ? FlamingoColors.primary : FlamingoColors.muted,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _timerBtn(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2)),
        ),
      ),
    );
  }
}

// ── Circular progress painter ──────────────────────────────

class _TimerCirclePainter extends CustomPainter {
  final double fraction;

  _TimerCirclePainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 16;
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * fraction;

    // Track ring
    final trackPaint = Paint()
      ..color = FlamingoColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Progress arc
    final progressColor = fraction < 0.2
        ? FlamingoColors.accent
        : FlamingoColors.primary;
    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint);

    // Outer glow
    final glowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint);

    // Inner ring
    final innerPaint = Paint()
      ..color = FlamingoColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), radius - 20, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerCirclePainter old) =>
      old.fraction != fraction;
}
