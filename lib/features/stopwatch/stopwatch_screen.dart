import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/pulse_dot.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen>
    with SingleTickerProviderStateMixin {
  bool _running = false;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<Duration> _laps = [];
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  void _tick(Timer timer) => setState(() {});

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 10), _tick);
    });
  }

  void _stop() {
    if (!_running) return;
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _stopwatch = Stopwatch();
      _laps.clear();
    });
  }

  void _lap() {
    if (!_running) return;
    setState(() => _laps.insert(0, _stopwatch.elapsed));
  }

  String _formatDuration(Duration d) {
    final ms = d.inMilliseconds;
    final min = (ms ~/ 60000).toString().padLeft(2, '0');
    final sec = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final centi = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$min:$sec.$centi';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final elapsed = _stopwatch.elapsed;
    final totalMs = elapsed.inMilliseconds;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _running ? 5 : 2,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Title
                Text(
                  'STOPWATCH',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),

                // Analog sweep display
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sweeping arc
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(260, 260),
                            painter: _StopwatchArcPainter(
                              elapsedMs: totalMs,
                              running: _running,
                              primaryColor: cs.primary,
                              accentColor: cs.tertiary,
                              surfaceColor: cs.surfaceContainerLow,
                              mutedColor: cs.onSurfaceVariant,
                              glowIntensity: _glowAnim.value,
                            ),
                          );
                        },
                      ),

                      // Center time display
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(elapsed),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 42,
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
                          const SizedBox(height: 6),
                          if (_running)
                            PulseDot(
                              color: cs.primary,
                              size: 8,
                              minOpacity: 0.4,
                            )
                          else if (elapsed.inMilliseconds > 0)
                            Text(
                              'PAUSED',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                                letterSpacing: 3,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ctrlBtn(
                      cs,
                      label: _running ? 'STOP' : 'START',
                      color: _running ? cs.tertiary : cs.primary,
                      onTap: _running ? _stop : _start,
                    ),
                    const SizedBox(width: 12),
                    _ctrlBtn(
                      cs,
                      label: 'LAP',
                      color: cs.secondary,
                      onTap: _running ? _lap : null,
                    ),
                    const SizedBox(width: 12),
                    _ctrlBtn(
                      cs,
                      label: 'RESET',
                      color: cs.onSurfaceVariant,
                      onTap: _reset,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                        cs.secondary.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Laps
                Expanded(
                  child: _laps.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 48,
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No laps yet',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap LAP while running',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _laps.length,
                          itemBuilder: (context, i) {
                            return _lapRow(cs, i);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lapRow(ColorScheme cs, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: i == 0
            ? cs.primary.withValues(alpha: 0.06)
            : cs.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: i == 0
            ? Border.all(color: cs.primary.withValues(alpha: 0.15), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (i == 0)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              Text(
                'Lap ${_laps.length - i}',
                style: TextStyle(
                  color: i == 0 ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: i == 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            _formatDuration(_laps[i]),
            style: TextStyle(
              color: cs.secondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(
    ColorScheme cs, {
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isActive = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isActive ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: isActive ? 0.3 : 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : color.withValues(alpha: 0.3),
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _StopwatchArcPainter extends CustomPainter {
  final int elapsedMs;
  final bool running;
  final Color primaryColor, accentColor, surfaceColor, mutedColor;
  final double glowIntensity;

  _StopwatchArcPainter({
    required this.elapsedMs,
    required this.running,
    required this.primaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.mutedColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 20;

    // Track ring
    final trackPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, trackPaint);

    // Progress arc (1 minute = full circle)
    final sweepAngle = (elapsedMs % 60000) / 60000 * 2 * math.pi;
    final arcPaint = Paint()
      ..color = running ? primaryColor : accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Glow on arc
    if (running) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.15 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // Tick marks at each second
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final isFive = i % 5 == 0;
      final innerR = isFive ? r - 12 : r - 6;
      canvas.drawLine(
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        Offset(cx + innerR * math.cos(angle), cy + innerR * math.sin(angle)),
        Paint()
          ..color = isFive
              ? primaryColor.withValues(alpha: 0.4)
              : mutedColor.withValues(alpha: 0.15)
          ..strokeWidth = isFive ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StopwatchArcPainter old) =>
      old.elapsedMs != elapsedMs ||
      old.running != running ||
      old.glowIntensity != glowIntensity;
}
