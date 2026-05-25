import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  static const _workMin = 25;
  static const _shortBreakMin = 5;
  static const _longBreakMin = 15;
  static const _roundsBeforeLongBreak = 4;

  bool _running = false;
  bool _isWork = true;
  int _roundsCompleted = 0;
  int _totalSessions = 0;

  Duration _remaining = Duration(minutes: _workMin);
  Timer? _timer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
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

  void _reset() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _running = false;
      _isWork = true;
      _roundsCompleted = 0;
      _remaining = Duration(minutes: _workMin);
    });
  }

  Future<void> _onComplete() async {
    _pulseCtrl.stop();

    Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 400]);
    try {
      await _player.play(AssetSource('sounds/click.wav'));
    } catch (_) {}

    if (_isWork) {
      _roundsCompleted++;
      _totalSessions++;
      final breakDuration = _roundsCompleted >= _roundsBeforeLongBreak
          ? _longBreakMin
          : _shortBreakMin;

      if (_roundsCompleted >= _roundsBeforeLongBreak) {
        _roundsCompleted = 0;
      }

      setState(() {
        _isWork = false;
        _remaining = Duration(minutes: breakDuration);
        _running = false;
      });
    } else {
      setState(() {
        _isWork = true;
        _remaining = Duration(minutes: _workMin);
        _running = false;
      });
    }
  }

  void _skipPhase() {
    _timer?.cancel();
    _pulseCtrl.stop();
    if (_isWork) {
      _onComplete();
    } else {
      setState(() {
        _isWork = true;
        _remaining = Duration(minutes: _workMin);
      });
    }
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

    final total = Duration(
      minutes: _isWork ? _workMin : (_roundsCompleted >= _roundsBeforeLongBreak ? _longBreakMin : _shortBreakMin),
    );
    final fraction = total.inSeconds > 0
        ? (_remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    final accentColor = _isWork ? cs.primary : cs.tertiary;
    final phaseLabel = _isWork ? 'FOCUS' : 'BREAK';

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _running ? 4 : 2,
          colors: [accentColor, cs.secondary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'POMODORO',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 24),

                // Phase badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phaseLabel,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Circular timer
                Expanded(
                  flex: 3,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return SizedBox(
                          width: 260,
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow ring
                              if (_running)
                                CustomPaint(
                                  size: const Size(260, 260),
                                  painter: _PomodoroGlowPainter(
                                    fraction: fraction,
                                    pulseIntensity: _pulseAnim.value,
                                    accentColor: accentColor,
                                  ),
                                ),

                              // Main progress ring
                              CustomPaint(
                                size: const Size(260, 260),
                                painter: _PomodoroRingPainter(
                                  fraction: fraction,
                                  accentColor: accentColor,
                                  surfaceColor: cs.surfaceContainerLow,
                                ),
                              ),

                              // Center content
                              Column(
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
                                      shadows: [
                                        Shadow(
                                          color: accentColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.repeat,
                                        color: cs.onSurfaceVariant,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Session $_totalSessions',
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 11,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Round dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _roundsCompleted;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? accentColor
                            : cs.surfaceContainerHigh,
                        border: Border.all(
                          color: filled
                              ? accentColor.withValues(alpha: 0.5)
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rounds',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 24),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _running ? _pause : _start,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _running
                                ? [
                                    accentColor.withValues(alpha: 0.2),
                                    accentColor.withValues(alpha: 0.05),
                                  ]
                                : [
                                    accentColor.withValues(alpha: 0.2),
                                    accentColor.withValues(alpha: 0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: accentColor,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _running ? 'PAUSE' : 'START',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: cs.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _skipPhase,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.skip_next_rounded,
                              color: cs.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SKIP',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  _isWork
                      ? 'Focus on your task — ${_roundsCompleted < _roundsBeforeLongBreak ? (_roundsBeforeLongBreak - _roundsCompleted).toString() : _roundsBeforeLongBreak} rounds until long break'
                      : 'Take a breather — ${_roundsCompleted < _roundsBeforeLongBreak ? 'short break time' : 'long break!'}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PomodoroRingPainter extends CustomPainter {
  final double fraction;
  final Color accentColor, surfaceColor;

  _PomodoroRingPainter({
    required this.fraction,
    required this.accentColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 20;
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * fraction;

    // Track
    final trackPaint = Paint()
      ..color = surfaceColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(cx, cy), r, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Inner ring
    final innerPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r - 16, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _PomodoroRingPainter old) =>
      old.fraction != fraction;
}

class _PomodoroGlowPainter extends CustomPainter {
  final double fraction;
  final double pulseIntensity;
  final Color accentColor;

  _PomodoroGlowPainter({
    required this.fraction,
    required this.pulseIntensity,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 20;
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * fraction;

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.08 + 0.06 * pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 + 4 * pulseIntensity
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PomodoroGlowPainter old) =>
      old.fraction != fraction || old.pulseIntensity != pulseIntensity;
}
