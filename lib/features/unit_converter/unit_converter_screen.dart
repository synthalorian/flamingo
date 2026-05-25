import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  _ConvCategory _cat = _ConvCategory.length;
  String _fromU = 'km';
  String _toU = 'miles';
  final TextEditingController _inputCtrl = TextEditingController();
  double? _result;

  static const Map<_ConvCategory, List<String>> _units = {
    _ConvCategory.length: ['km', 'miles', 'm', 'ft', 'cm', 'in', 'mm'],
    _ConvCategory.weight: ['kg', 'lb', 'g', 'oz'],
    _ConvCategory.temp: ['c', 'f', 'k'],
    _ConvCategory.volume: ['L', 'mL', 'gal', 'cup'],
  };

  static const Map<String, String> _unitLabel = {
    'km': 'km',
    'miles': 'mi',
    'm': 'm',
    'ft': 'ft',
    'cm': 'cm',
    'in': 'in',
    'mm': 'mm',
    'kg': 'kg',
    'lb': 'lb',
    'g': 'g',
    'oz': 'oz',
    'c': '°C',
    'f': '°F',
    'k': 'K',
    'L': 'L',
    'mL': 'mL',
    'gal': 'US gal',
    'cup': 'cup',
  };

  static const Map<_ConvCategory, String> _catLabel = {
    _ConvCategory.length: 'Length',
    _ConvCategory.weight: 'Weight',
    _ConvCategory.temp: 'Temperature',
    _ConvCategory.volume: 'Volume',
  };

  static const Map<String, IconData> _catIcon = {
    'Length': Icons.straighten,
    'Weight': Icons.monitor_weight,
    'Temperature': Icons.thermostat,
    'Volume': Icons.opacity,
  };

  static const Map<(String, String), double> _factor = {
    ('km', 'km'): 1.0,
    ('km', 'miles'): 0.621371,
    ('km', 'm'): 1000,
    ('km', 'ft'): 3280.84,
    ('km', 'cm'): 100000,
    ('km', 'in'): 39370.1,
    ('km', 'mm'): 1e6,
    ('miles', 'km'): 1.60934,
    ('miles', 'miles'): 1.0,
    ('miles', 'm'): 1609.34,
    ('miles', 'ft'): 5280,
    ('miles', 'cm'): 160934,
    ('miles', 'in'): 63360,
    ('miles', 'mm'): 1.609e6,
    ('m', 'km'): 0.001,
    ('m', 'miles'): 0.000621371,
    ('m', 'm'): 1.0,
    ('m', 'ft'): 3.28084,
    ('m', 'cm'): 100,
    ('m', 'in'): 39.3701,
    ('m', 'mm'): 1000,
    ('ft', 'km'): 0.0003048,
    ('ft', 'miles'): 0.000189394,
    ('ft', 'm'): 0.3048,
    ('ft', 'ft'): 1.0,
    ('ft', 'cm'): 30.48,
    ('ft', 'in'): 12,
    ('ft', 'mm'): 304.8,
    ('cm', 'km'): 1e-5,
    ('cm', 'miles'): 6.2137e-6,
    ('cm', 'm'): 0.01,
    ('cm', 'ft'): 0.0328084,
    ('cm', 'cm'): 1.0,
    ('cm', 'in'): 0.393701,
    ('cm', 'mm'): 10,
    ('in', 'km'): 2.54e-5,
    ('in', 'miles'): 1.5783e-5,
    ('in', 'm'): 0.0254,
    ('in', 'ft'): 1 / 12,
    ('in', 'cm'): 2.54,
    ('in', 'in'): 1.0,
    ('in', 'mm'): 25.4,
    ('mm', 'km'): 1e-6,
    ('mm', 'miles'): 6.2137e-7,
    ('mm', 'm'): 0.001,
    ('mm', 'ft'): 0.00328084,
    ('mm', 'cm'): 0.1,
    ('mm', 'in'): 0.0393701,
    ('mm', 'mm'): 1.0,
    ('kg', 'kg'): 1.0,
    ('kg', 'lb'): 2.20462,
    ('kg', 'g'): 1000,
    ('kg', 'oz'): 35.274,
    ('lb', 'kg'): 0.453592,
    ('lb', 'lb'): 1.0,
    ('lb', 'g'): 453.592,
    ('lb', 'oz'): 16,
    ('g', 'kg'): 0.001,
    ('g', 'lb'): 0.00220462,
    ('g', 'g'): 1.0,
    ('g', 'oz'): 0.035274,
    ('oz', 'kg'): 0.0283495,
    ('oz', 'lb'): 0.0625,
    ('oz', 'g'): 28.3495,
    ('oz', 'oz'): 1.0,
    ('L', 'L'): 1.0,
    ('L', 'mL'): 1000,
    ('L', 'gal'): 0.264172,
    ('L', 'cup'): 4.22675,
    ('mL', 'L'): 0.001,
    ('mL', 'mL'): 1.0,
    ('mL', 'gal'): 0.000264172,
    ('mL', 'cup'): 0.00422675,
    ('gal', 'L'): 3.78541,
    ('gal', 'mL'): 3785.41,
    ('gal', 'gal'): 1.0,
    ('gal', 'cup'): 16,
    ('cup', 'L'): 0.236588,
    ('cup', 'mL'): 236.588,
    ('cup', 'gal'): 0.0625,
    ('cup', 'cup'): 1.0,
  };

  double? _convertTemp(double v, String from, String to) {
    double toC(double val, String unit) {
      switch (unit) {
        case 'c':
          return val;
        case 'f':
          return (val - 32) * 5 / 9;
        case 'k':
          return val - 273.15;
        default:
          return 0;
      }
    }

    double fromC(double c, String unit) {
      switch (unit) {
        case 'c':
          return c;
        case 'f':
          return c * 9 / 5 + 32;
        case 'k':
          return c + 273.15;
        default:
          return 0;
      }
    }

    return fromC(toC(v, from), to);
  }

  void _doConvert() {
    final v = double.tryParse(_inputCtrl.text) ?? 0;
    if (_cat == _ConvCategory.temp) {
      setState(() => _result = _convertTemp(v, _fromU, _toU));
    } else {
      final f = _factor[(_fromU, _toU)];
      setState(() => _result = f != null ? v * f : null);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _switchCategory(_ConvCategory c) {
    setState(() {
      _cat = c;
      final u = _units[c]!;
      _fromU = u.first;
      _toU = u.length > 1 ? u.last : u.first;
      _inputCtrl.clear();
      _result = null;
    });
  }

  void _swapUnits() {
    setState(() {
      final tmp = _fromU;
      _fromU = _toU;
      _toU = tmp;
      _result = null;
    });
    _doConvert();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final units = _units[_cat]!;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Unit Converter'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category tabs with icons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _ConvCategory.values.map((c) {
                      final sel = c == _cat;
                      final label = _catLabel[c]!;
                      final icon = _catIcon[label]!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: sel
                              ? cs.primary.withValues(alpha: 0.15)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _switchCategory(c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel
                                      ? cs.primary.withValues(alpha: 0.4)
                                      : cs.outlineVariant.withValues(
                                          alpha: 0.15,
                                        ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 16,
                                    color: sel
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: sel
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // From row
                _convRow(
                  label: 'FROM',
                  value: _inputCtrl.text,
                  unit: _fromU,
                  units: units,
                  onChanged: (v) => setState(() => _inputCtrl.text = v),
                  onUnitChanged: (u) => setState(() => _fromU = u),
                  cs: cs,
                  isInput: true,
                ),
                const SizedBox(height: 4),

                // Swap button
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.swap_vert, color: cs.primary, size: 20),
                      onPressed: _swapUnits,
                      splashRadius: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // To row
                _convRow(
                  label: 'TO',
                  value: _result != null ? _fmt(_result!) : null,
                  unit: _toU,
                  units: units,
                  onChanged: null,
                  onUnitChanged: (u) => setState(() => _toU = u),
                  result: _result,
                  cs: cs,
                  isInput: false,
                ),

                const Spacer(),

                // Convert button
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: cs.primary.withValues(alpha: 0.15),
                    surfaceTintColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _doConvert,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calculate, size: 18, color: cs.primary),
                            const SizedBox(width: 10),
                            Text(
                              'CONVERT',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _convRow({
    required String label,
    required String? value,
    required String unit,
    required List<String> units,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onUnitChanged,
    double? result,
    required ColorScheme cs,
    required bool isInput,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInput
              ? cs.primary.withValues(alpha: 0.2)
              : cs.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _unitLabel[unit] ?? unit,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: isInput
                    ? TextField(
                        controller: _inputCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 28,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        onChanged: (v) => setState(() {}),
                      )
                    : Text(
                        result != null ? _fmt(result) : '—',
                        style: TextStyle(
                          color: result != null
                              ? cs.secondary
                              : cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 28,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              // Unit selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unit,
                    dropdownColor: cs.surfaceContainerLow,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    icon: Icon(Icons.expand_more, size: 18, color: cs.primary),
                    items: List.generate(
                      units.length,
                      (i) => DropdownMenuItem(
                        value: units[i],
                        child: Text(_unitLabel[units[i]] ?? units[i]),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null && onUnitChanged != null) onUnitChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ConvCategory { length, weight, temp, volume }
