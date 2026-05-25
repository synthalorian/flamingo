import 'package:flutter/material.dart';

/// A pulsing dot indicator for showing active states.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final double minOpacity;

  const PulseDot({
    super.key,
    this.color = const Color(0xFFFF69B4),
    this.size = 10,
    this.minOpacity = 0.3,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final opacity =
            widget.minOpacity + (1 - widget.minOpacity) * _anim.value;
        final scale = 0.8 + 0.2 * _anim.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: opacity * 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A neon gradient divider line.
class NeonDivider extends StatelessWidget {
  final List<Color> colors;
  final double height;
  final double opacity;

  const NeonDivider({
    super.key,
    this.colors = const [Color(0xFFFF69B4), Color(0xFF00D4FF)],
    this.height = 2,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withValues(alpha: opacity)).toList(),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: opacity * 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
