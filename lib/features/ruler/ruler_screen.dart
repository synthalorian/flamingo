import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';

class RulerScreen extends StatefulWidget {
  const RulerScreen({super.key});

  @override
  State<RulerScreen> createState() => _RulerScreenState();
}

class _RulerScreenState extends State<RulerScreen> {
  double _pxPerCm = 37.8;
  bool _swapped = false;
  final double _rulerLengthCm = 20.0;

  void _toggle() => setState(() {
    _swapped = !_swapped;
  });

  String get _unitLabel => _swapped ? 'in' : 'cm';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Ruler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Toggle cm / inch',
            icon: Icon(_swapped ? Icons.straighten : Icons.horizontal_rule),
            color: cs.primary,
            onPressed: _toggle,
          ),
        ],
      ),
      body: CrtBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Calibration section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_pxPerCm.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 28,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          'px / $_unitLabel',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: cs.primary,
                        inactiveTrackColor: cs.surfaceContainerHigh,
                        thumbColor: cs.primary,
                        trackHeight: 5,
                      ),
                      child: Slider(
                        min: 28,
                        max: 60,
                        value: _pxPerCm,
                        onChanged: (v) => setState(() => _pxPerCm = v),
                      ),
                    ),
                    Text(
                      'Compare to a physical ruler \u2014 adjust as needed',
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Ruler widget
              Expanded(
                child: _Ruler(
                  pxPerUnit: _pxPerCm.clamp(28, 60),
                  mode: _swapped ? _RulerMode.inch : _RulerMode.cm,
                  lengthCm: _rulerLengthCm,
                  primaryGlow: cs.primary,
                  secondaryGlow: cs.secondary,
                  surfaceLow: cs.surfaceContainerLow,
                  outlineVariant: cs.outlineVariant,
                  onSurface: cs.onSurface,
                  onSurfaceVariant: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Scroll horizontally to measure longer lengths',
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RulerMode { cm, inch }

class _Ruler extends StatelessWidget {
  const _Ruler({
    required this.pxPerUnit,
    required this.mode,
    required this.lengthCm,
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.surfaceLow,
    required this.outlineVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  final double pxPerUnit;
  final _RulerMode mode;
  final double lengthCm;
  final Color primaryGlow;
  final Color secondaryGlow;
  final Color surfaceLow;
  final Color outlineVariant;
  final Color onSurface;
  final Color onSurfaceVariant;

  static const _tickHeightBig = 22.0;
  static const _tickHeightMid = 14.0;
  static const _tickHeightSmall = 8.0;
  static const _rulerThickness = 48.0;

  @override
  Widget build(BuildContext context) {
    final int divisions;
    final double subUnitSize;
    final String unitSymbol;

    if (mode == _RulerMode.cm) {
      divisions = 10;
      subUnitSize = pxPerUnit / 10.0;
      unitSymbol = 'cm';
    } else {
      divisions = 16;
      subUnitSize = (pxPerUnit * 2.54) / 16.0;
      unitSymbol = 'in';
    }

    final totalWidth = pxPerUnit * lengthCm;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '0',
                style: TextStyle(
                  color: primaryGlow,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Text(
                '$unitSymbol',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: _rulerThickness,
            width: totalWidth.toDouble(),
            decoration: BoxDecoration(
              color: surfaceLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: outlineVariant.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: primaryGlow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                for (int i = 0; i <= (lengthCm * divisions).round(); i++)
                  Positioned(
                    left: (i * subUnitSize).toDouble(),
                    top: 0,
                    child: _Tick(
                      height: i % divisions == 0
                          ? _tickHeightBig
                          : i % (divisions ~/ 2) == 0
                          ? _tickHeightMid
                          : _tickHeightSmall,
                      isBig: i % divisions == 0,
                      isHalf: i % (divisions ~/ 2) == 0,
                      isLabel: i % divisions == 0 && i > 0,
                      label: i % divisions == 0
                          ? (mode == _RulerMode.cm
                                ? '${(i ~/ divisions)}'
                                : _inchLabel(i))
                          : '',
                      primary: primaryGlow,
                      onSurface: onSurface,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  '${lengthCm.toInt()} $unitSymbol',
                  style: TextStyle(
                    color: primaryGlow,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _inchLabel(int i) {
    final Map<int, String> labels = {
      1: '1/16',
      2: '1/8',
      3: '3/16',
      4: '1/4',
      5: '5/16',
      6: '3/8',
      7: '7/16',
      8: '1/2',
      9: '9/16',
      10: '5/8',
      11: '11/16',
      12: '3/4',
      13: '13/16',
      14: '7/8',
      15: '15/16',
    };
    return labels[i]!;
  }
}

class _Tick extends StatelessWidget {
  const _Tick({
    required this.height,
    required this.isBig,
    required this.isHalf,
    required this.isLabel,
    required this.label,
    required this.primary,
    required this.onSurface,
  });

  final double height;
  final bool isBig;
  final bool isHalf;
  final bool isLabel;
  final String label;
  final Color primary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isBig ? 1.5 : 1,
          height: height,
          color: isBig
              ? primary
              : isHalf
              ? onSurface.withValues(alpha: 0.4)
              : onSurface.withValues(alpha: 0.2),
        ),
        if (isLabel && label.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 3, top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              label,
              style: TextStyle(
                color: primary,
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
