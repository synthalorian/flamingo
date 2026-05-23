import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  double _hue = 0;
  double _saturation = 1.0;
  double _brightness = 1.0;

  Color get _color => HSLColor.fromAHSL(1, _hue, _saturation, _brightness).toColor();

  String get _hex => '#${_color.value.toRadixString(16).padLeft(8, '0').substring(2)}';

  String get _rgbStr => '${_color.red}, ${_color.green}, ${_color.blue}';

  void _copyHex() {
    Clipboard.setData(ClipboardData(text: _hex));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied $_hex')),
      );
    }
  }

  void _copyRgb() {
    Clipboard.setData(ClipboardData(text: _rgbStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied $_rgbStr')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('COLOR PICKER', style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
              const SizedBox(height: 24),

              // Hue slider
              Row(
                children: [
                  // Hue slider (wide)
                  Expanded(
                    child: Column(
                      children: [
                        // Preview swatch
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: _color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _color.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _hex.toUpperCase(),
                                style: const TextStyle(
                                  color: FlamingoColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Hue slider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: FlamingoColors.text,
                              inactiveTrackColor: FlamingoColors.cardBorder,
                              thumbColor: FlamingoColors.primary,
                              trackHeight: 20,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              overlayColor: FlamingoColors.primary.withValues(alpha: 0.3),
                            ),
                            child: Slider(
                              value: _hue / 360,
                              onChanged: (v) => setState(() => _hue = (v * 360).round().toDouble()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Saturation + Brightness vertical
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        const Text('SAT', style: TextStyle(color: FlamingoColors.muted, fontSize: 10)),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: FlamingoColors.accent,
                                  inactiveTrackColor: FlamingoColors.cardBorder,
                                  thumbColor: FlamingoColors.accent,
                                  trackHeight: 16,
                                ),
                                child: Slider(
                                  value: _saturation,
                                  onChanged: (v) => setState(() => _saturation = v),
                                ),
                              ),
                              const Text('BRT', style: TextStyle(color: FlamingoColors.muted, fontSize: 10)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: FlamingoColors.neonBlue,
                                    inactiveTrackColor: FlamingoColors.cardBorder,
                                    thumbColor: FlamingoColors.neonBlue,
                                    trackHeight: 16,
                                  ),
                                  child: Slider(
                                    value: _brightness,
                                    onChanged: (v) => setState(() => _brightness = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // RGB label
              Text('RGB($_rgbStr)', style: const TextStyle(color: FlamingoColors.text, fontSize: 16, fontFamily: 'monospace')),
              const SizedBox(height: 24),

              // Copy buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _copyBtn('COPY HEX', _copyHex),
                  const SizedBox(width: 16),
                  _copyBtn('COPY RGB', _copyRgb),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _copyBtn(String label, VoidCallback onTap) {
    return Material(
      color: FlamingoColors.primary.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(label,
              style: TextStyle(color: FlamingoColors.primary, fontWeight: FontWeight.w600, letterSpacing: 1)),
        ),
      ),
    );
  }
}
