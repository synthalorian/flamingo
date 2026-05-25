import 'package:flutter/material.dart';

/// A glowing action button with configurable neon effect.
class GlowingButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final Color? textColor;
  final double width;
  final double height;
  final double fontSize;
  final double borderRadius;

  const GlowingButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = const Color(0xFFFF69B4),
    this.textColor,
    this.width = double.infinity,
    this.height = 56,
    this.fontSize = 14,
    this.borderRadius = 28,
  });

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glowOpacity = 0.15 * _pulseAnim.value;
        return GestureDetector(
          onTapDown: widget.onTap != null
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.onTap != null
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onTap?.call();
                }
              : null,
          onTapCancel: widget.onTap != null
              ? () => setState(() => _pressed = false)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _pressed ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.color.withValues(alpha: _pressed ? 0.6 : 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: glowOpacity),
                  blurRadius: 20 * _pulseAnim.value,
                  spreadRadius: 2 * _pulseAnim.value,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.textColor ?? widget.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.textColor ?? widget.color,
                    fontWeight: FontWeight.w600,
                    fontSize: widget.fontSize,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
