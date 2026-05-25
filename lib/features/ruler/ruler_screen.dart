
import 'package:flutter/material.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

/// Apparent PPI: Android uses ~160 logical ppi baseline.
/// Real devices vary — user can calibrate by matching to a known ruler.
class RulerScreen extends StatefulWidget {
  const RulerScreen({super.key});

  @override
  State<RulerScreen> createState() => _RulerScreenState();
}

class _RulerScreenState extends State<RulerScreen> {
  double _pxPerCm = 37.8; // default: ~96 dpi
  bool _swapped = false; // false = cm, true = inch
  final double _rulerLengthCm = 20.0;
// removed _unitLabel field — now a getter

  void _toggle() => setState(() {
        _swapped = !_swapped;
      });

  String get _unitLabel => _swapped ? 'in' : 'cm';

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Ruler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FlamingoColors.text,
        actions: [
          IconButton(
            tooltip: 'Toggle cm / inch',
            icon: Icon(_swapped ? Icons.straighten : Icons.horizontal_rule),
            color: FlamingoColors.primary,
            onPressed: _toggle,
          ),
        ],
      ),
      body: CrtBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Calibration slider hint
              Text(
                '${_pxPerCm.toStringAsFixed(1)} px/${_unitLabel}',
                style: TextStyle(
                  color: FlamingoColors.accent,
                  fontSize: 14,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use a known ruler — adjust as needed',
                style: TextStyle(color: FlamingoColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Slider(
                min: 28,
                max: 60,
                value: _pxPerCm,
                label: '${_pxPerCm.toStringAsFixed(0)} px/cm',
                activeColor: FlamingoColors.primary,
                inactiveColor: FlamingoColors.cardBorder,
                onChanged: (v) => setState(() => _pxPerCm = v),
              ),
              const SizedBox(height: 32),
              // Ruler widget
              _Ruler(
                pxPerUnit: _pxPerCm.clamp(28, 60),
                mode: _swapped ? _RulerMode.inch : _RulerMode.cm,
                lengthCm: _rulerLengthCm,
              ),
              const Spacer(),
              Text(
                'Scroll to measure longer lengths',
                style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 1),
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
  });

  final double pxPerUnit;
  final _RulerMode mode;
  final double lengthCm;

  static const _tickHeightBig = 20.0;
  static const _tickHeightMid = 12.0;
  static const _tickHeightSmall = 6.0;
  static const _rulerThickness = 40.0;

  @override
  Widget build(BuildContext context) {
    final int divisions;
    final double subUnitSize;
    final String unitSymbol;

    if (mode == _RulerMode.cm) {
      divisions = 10; // mm
      subUnitSize = pxPerUnit / 10.0;
      unitSymbol = 'cm';
    } else {
      divisions = 16; // 1/16 inch
      subUnitSize = (pxPerUnit * 2.54) / 16.0;
      unitSymbol = 'in';
    }

    // Full pixel width of the ruler
    final totalWidth = pxPerUnit * lengthCm;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('0  $unitSymbol',
              style: TextStyle(
                color: FlamingoColors.accent,
                fontSize: 11,
                fontFamily: 'monospace',
                letterSpacing: 1,
              )),
          const SizedBox(height: 2),
          Container(
            height: _rulerThickness,
            width: totalWidth.toDouble(),
            decoration: BoxDecoration(
              color: FlamingoColors.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: FlamingoColors.cardBorder),
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
                      cmRange: i,
                    ),
                  ),
              ],
            ),
          ),
          Text('${lengthCm.toInt()} $unitSymbol',
              style: TextStyle(
                color: FlamingoColors.accent,
                fontSize: 11,
                fontFamily: 'monospace',
                letterSpacing: 1,
              )),
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
  const _Tick({required this.height, required this.isBig, required this.isHalf, required this.isLabel, required this.label, required this.cmRange});

  final double height;
  final bool isBig;
  final bool isHalf;
  final bool isLabel;
  final String label;
  final int cmRange;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 1,
          height: height,
          color: isBig
              ? FlamingoColors.primary
              : isHalf
                  ? FlamingoColors.text.withValues(alpha: 0.5)
                  : FlamingoColors.text.withValues(alpha: 0.25),
        ),
        if (isLabel && label.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 2),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            child: Text(
              label,
              style: TextStyle(
                color: FlamingoColors.primary,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }
}
