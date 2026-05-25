import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated background with floating neon particles.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final List<Color> colors;
  final double particleSize;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.particleCount = 8,
    this.colors = const [
      Color(0xFFFF69B4),
      Color(0xFF00D4FF),
      Color(0xFFB026FF),
    ],
    this.particleSize = 3,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _particles = <_Particle>[];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle._random(widget.colors));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  time: _ctrl.value,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.opacity,
  });

  factory _Particle._random(List<Color> colors) {
    final rng = math.Random();
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      vx: (rng.nextDouble() - 0.5) * 0.02,
      vy: (rng.nextDouble() - 0.5) * 0.02,
      size: 1.5 + rng.nextDouble() * 3,
      color: colors[rng.nextInt(colors.length)],
      opacity: 0.1 + rng.nextDouble() * 0.2,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;

  _ParticlePainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0 || p.x > 1) p.vx = -p.vx;
      if (p.y < 0 || p.y > 1) p.vy = -p.vy;

      final px = p.x * size.width;
      final py = p.y * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), p.size, paint);

      // Glow
      final glow = Paint()
        ..color = p.color.withValues(alpha: p.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(px, py), p.size * 3, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
