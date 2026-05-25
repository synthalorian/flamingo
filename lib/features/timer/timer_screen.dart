import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/pulse_dot.dart';

const List<int> kPresets = [1, 2, 5, 10, 15, 30];

enum TimerSound { none, notification, alarm }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  Duration _total = const Duration(minutes: 5);
  Duration _remaining = const Duration(minutes: 5);
  bool _running = false;
  bool _finished = false;
  Timer? _timer;
  TimerSound _sound = TimerSound.notification;
  final AudioPlayer _player = AudioPlayer();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  void _start() {
    if (_running || _remaining.inSeconds <= 0) return;
    setState(() {
      _running = true;
      _finished = false;
    });
    _pulseCtrl.repeat(reverse: true);
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
    _pulseCtrl.stop();
    setState(() => _running = false);
  }

  void _cancel() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _running = false;
      _remaining = _total;
      _finished = false;
    });
  }

  Future<void> _onComplete() async {
    _pulseCtrl.stop();
    setState(() {
      _running = false;
      _finished = true;
    });
    Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 300]);

    try {
      if (_sound != TimerSound.none) {
        await _player.play(AssetSource('sounds/click.wav'));
      }
    } catch (_) {}

    _showDoneDialog();
  }

  void _showDoneDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      useRootNavigator: false,
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.timer_off, color: cs.primary),
            const SizedBox(width: 8),
            Text("Time's Up!", style: TextStyle(color: cs.primary)),
          ],
        ),
        content: Text(
          "Your timer has finished.",
          style: TextStyle(color: cs.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _remaining = _total;
                _finished = false;
              });
            },
            child: Text('OK', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }

  void _setDuration(int minutes) {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _total = Duration(minutes: minutes);
      _remaining = Duration(minutes: minutes);
      _running = false;
      _finished = false;
    });
  }

  void _onSoundChanged(TimerSound newSound) {
    setState(() => _sound = newSound);
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fraction = _total.inSeconds > 0
        ? (_remaining.inSeconds / _total.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _running ? 4 : 2,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Preset chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: kPresets.map((m) {
                      final active = _total.inMinutes == m && !_running;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _presetChip(cs, m, active),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Sound picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sound:',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _soundChip(cs, 'None', TimerSound.none),
                    const SizedBox(width: 6),
                    _soundChip(cs, 'Notif', TimerSound.notification),
                    const SizedBox(width: 6),
                    _soundChip(cs, 'Alarm', TimerSound.alarm),
                  ],
                ),

                const SizedBox(height: 16),

                // Circular countdown
                Expanded(
                  flex: 3,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return SizedBox(
                          width: 260,
                          height: 260,
                          child: CustomPaint(
                            painter: _TimerCirclePainter(
                              fraction: fraction,
                              running: _running,
                              finished: _finished,
                              pulseIntensity: _pulseAnim.value,
                              primaryColor: cs.primary,
                              tertiaryColor: cs.tertiary,
                              surfaceColor: cs.surfaceContainerLow,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _format(_remaining),
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w300,
                                      fontFamily: 'monospace',
                                      letterSpacing: 2,
                                      shadows: _running
                                          ? [
                                              Shadow(
                                                color: cs.primary.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  if (_running)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: PulseDot(
                                        color: cs.primary,
                                        size: 6,
                                        minOpacity: 0.3,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_running && !_finished)
                      _timerBtn(cs, 'START', cs.primary, _start)
                    else if (_running)
                      _timerBtn(cs, 'PAUSE', cs.tertiary, _pause)
                    else
                      _timerBtn(cs, 'AGAIN', cs.primary, () {
                        _remaining = _total;
                        _finished = false;
                        setState(() {});
                      }),
                    const SizedBox(width: 16),
                    _timerBtn(cs, 'CANCEL', cs.onSurfaceVariant, _cancel),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetChip(ColorScheme cs, int minutes, bool active) {
    final color = active ? cs.primary : cs.onSurfaceVariant;
    return GestureDetector(
      onTap: () => _setDuration(minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.2),
                    cs.primary.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: active ? null : cs.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _soundChip(ColorScheme cs, String label, TimerSound value) {
    final active = _sound == value;
    final color = active ? cs.tertiary : cs.onSurfaceVariant;
    return GestureDetector(
      onTap: () => _onSoundChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? cs.tertiary.withValues(alpha: 0.15)
              : cs.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? cs.tertiary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _timerBtn(
    ColorScheme cs,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _TimerCirclePainter extends CustomPainter {
  final double fraction;
  final bool running, finished;
  final double pulseIntensity;
  final Color primaryColor, tertiaryColor, surfaceColor;

  _TimerCirclePainter({
    required this.fraction,
    required this.running,
    required this.finished,
    required this.pulseIntensity,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 18;
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * fraction;

    final progressColor = finished
        ? tertiaryColor
        : fraction < 0.2
        ? tertiaryColor
        : primaryColor;

    // Outer glow ring
    if (running) {
      final glowRing = Paint()
        ..color = progressColor.withValues(alpha: 0.05 + 0.05 * pulseIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 + 4 * pulseIntensity;
      canvas.drawCircle(Offset(cx, cy), radius + 4, glowRing);
    }

    // Track ring
    final trackPaint = Paint()
      ..color = surfaceColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Glow on progress
    if (running) {
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.2 * pulseIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // Inner ring
    final innerPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), radius - 22, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerCirclePainter old) =>
      old.fraction != fraction ||
      old.running != running ||
      old.finished != finished ||
      old.pulseIntensity != pulseIntensity;
}
