import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/crt_background.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen>
    with SingleTickerProviderStateMixin {
  double _hue = 0;
  double _saturation = 1.0;
  double _brightness = 1.0;
  late AnimationController _pulseCtrl;

  Color get _color =>
      HSLColor.fromAHSL(1, _hue, _saturation, _brightness).toColor();

  String get _hex =>
      '#${_color.value.toRadixString(16).padLeft(8, '0').substring(2)}';

  String get _rgbStr => '${_color.red}, ${_color.green}, ${_color.blue}';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _copyHex() {
    Clipboard.setData(ClipboardData(text: _hex));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied $_hex'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _color,
        ),
      );
    }
  }

  void _copyRgb() {
    Clipboard.setData(ClipboardData(text: _rgbStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied RGB($_rgbStr)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'COLOR PICKER',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Color preview with animated glow
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  final pulse = _pulseCtrl.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _color.withValues(alpha: 0.3 + pulse * 0.3),
                            blurRadius: 20 + pulse * 20,
                            spreadRadius: 4 + pulse * 4,
                          ),
                          BoxShadow(
                            color: _color.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _hex.toUpperCase(),
                              style: TextStyle(
                                color: _color.computeLuminance() > 0.5
                                    ? Colors.black87
                                    : Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RGB($_rgbStr)',
                              style: TextStyle(
                                color:
                                    (_color.computeLuminance() > 0.5
                                            ? Colors.black87
                                            : Colors.white)
                                        .withValues(alpha: 0.7),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Hue slider with gradient track
              _buildSliderSection(
                label: 'HUE',
                value: _hue / 360,
                onChanged: (v) =>
                    setState(() => _hue = (v * 360).round().toDouble()),
                gradientColors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.indigo,
                  Colors.purple,
                  Colors.red,
                ],
                thumbColor: _color,
              ),

              const SizedBox(height: 18),

              // Saturation slider
              _buildSliderSection(
                label: 'SAT',
                value: _saturation,
                onChanged: (v) => setState(() => _saturation = v),
                gradientColors: [
                  HSLColor.fromAHSL(1, _hue, 0, _brightness).toColor(),
                  HSLColor.fromAHSL(1, _hue, 1, _brightness).toColor(),
                ],
                thumbColor: _color,
              ),

              const SizedBox(height: 18),

              // Brightness slider
              _buildSliderSection(
                label: 'BRT',
                value: _brightness,
                onChanged: (v) => setState(() => _brightness = v),
                gradientColors: [
                  Colors.black,
                  HSLColor.fromAHSL(1, _hue, _saturation, 1).toColor(),
                ],
                thumbColor: _color,
              ),

              const SizedBox(height: 32),

              // Copy buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _copyBtn('COPY HEX', Icons.copy, _copyHex, cs),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _copyBtn('COPY RGB', Icons.copy_all, _copyRgb, cs),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required List<Color> gradientColors,
    required Color thumbColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _GradientSlider(
                  value: value,
                  onChanged: onChanged,
                  gradientColors: gradientColors,
                  thumbColor: thumbColor,
                  width: constraints.maxWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyBtn(
    String label,
    IconData icon,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return Material(
      color: _color.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: _color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final List<Color> gradientColors;
  final Color thumbColor;
  final double width;

  const _GradientSlider({
    required this.value,
    required this.onChanged,
    required this.gradientColors,
    required this.thumbColor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Gradient track
          Container(
            height: 28,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: gradientColors),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          // Thumb
          Positioned(
            left: value * (width - 28),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final newValue = (details.localPosition.dx / (width - 28))
                    .clamp(0.0, 1.0);
                onChanged(newValue);
              },
              onTapDown: (details) {
                final newValue = (details.localPosition.dx / (width - 28))
                    .clamp(0.0, 1.0);
                onChanged(newValue);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: thumbColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: thumbColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
