import 'package:flutter/material.dart';

/// A container with configurable neon glow effect.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final List<BoxShadow>? extraShadows;
  final Decoration? decoration;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFFF69B4),
    this.blurRadius = 20,
    this.spreadRadius = 2,
    this.opacity = 0.4,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.extraShadows,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration:
          decoration ??
          BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: opacity),
                blurRadius: blurRadius,
                spreadRadius: spreadRadius,
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: opacity * 0.5),
                blurRadius: blurRadius * 1.5,
                spreadRadius: spreadRadius * 0.5,
              ),
              ...?extraShadows,
            ],
          ),
      child: child,
    );
  }
}

/// A gradient-bordered container with neon glow.
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderWidth;
  final double glowOpacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;

  const GradientBorderContainer({
    super.key,
    required this.child,
    this.gradientColors = const [Color(0xFFFF69B4), Color(0xFF00D4FF)],
    this.borderWidth = 1.5,
    this.glowOpacity = 0.3,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: gradientColors.first.withValues(alpha: glowOpacity),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: glowOpacity * 0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
