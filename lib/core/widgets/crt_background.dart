import 'package:flutter/material.dart';
import '../theme/flamingo_theme.dart';

/// A subtle CRT scanline overlay.
class CrtBackground extends StatelessWidget {
  const CrtBackground({super.key, required this.child});

  /// The widget below this in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        CustomPaint(
          size: Size.infinite,
          painter: _ScanlinePainter(),
        ),
        child,
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FlamingoColors.glowPink.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const double spacing = 3.0;
    for (double y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
