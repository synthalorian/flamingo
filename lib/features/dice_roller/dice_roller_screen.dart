import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

const List<int> _allSides = [4, 6, 8, 10, 12, 20];

class DiceRollerScreen extends StatefulWidget {
  const DiceRollerScreen({super.key});

  @override
  State<DiceRollerScreen> createState() => _DiceRollerScreenState();
}

class _DiceRollerScreenState extends State<DiceRollerScreen> {
  final math.Random _rng = math.Random.secure();
  int _setA_count = 1;
  int _setA_sides = 6;
  int _setB_count = 2;
  int _setB_sides = 6;
  bool _rolling = false;

  void _roll() {
    setState(() => _rolling = true);
    Vibration.vibrate(duration: 100);
    // Small delay so the user sees the "rolling" state
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _rolling = false);
    });
  }

  List<int> _results(int count, int sides) {
    return List.generate(count, (_) => _rng.nextInt(sides) + 1);
  }

  Widget _dieBlock(int value, {double size = 52}) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: FlamingoColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FlamingoColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: FlamingoColors.primary.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            color: FlamingoColors.primary,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _diceSet({
    required String label,
    required bool active,
  }) {
    final count = label == 'A' ? _setA_count : _setB_count;
    final sides = label == 'A' ? _setA_sides : _setB_sides;
    final results = _rolling ? _results(count, sides) : <int>[];

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? FlamingoColors.primary.withValues(alpha: 0.08)
              : FlamingoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? FlamingoColors.primary.withValues(alpha: 0.3)
                : FlamingoColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SET $label',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? FlamingoColors.primary : FlamingoColors.muted,
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Text('d$sides · $count dice',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FlamingoColors.muted,
                  fontSize: 11,
                )),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: _rolling || results.isEmpty
                  ? [const Text('—', style: TextStyle(color: FlamingoColors.muted))]
                  : List.generate(results.length, (i) => _dieBlock(results[i])),
            ),
            const SizedBox(height: 8),
            // Sides selector
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 3,
              runSpacing: 3,
              children: _allSides.map((s) {
                final isActive = (label == 'A' ? _setA_sides : _setB_sides) == s;
                return Material(
                  color: isActive
                      ? FlamingoColors.accent.withValues(alpha: 0.2)
                      : FlamingoColors.card,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        if (label == 'A') {
                          _setA_sides = s;
                        } else {
                          _setB_sides = s;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text('d$s',
                          style: TextStyle(
                            color: isActive ? FlamingoColors.accent : FlamingoColors.muted,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Slider(
              value: label == 'A' ? _setA_count.toDouble() : _setB_count.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              activeColor: FlamingoColors.primary,
              inactiveColor: FlamingoColors.card,
              onChanged: (v) {
                setState(() {
                  if (label == 'A') {
                    _setA_count = v.round();
                  } else {
                    _setB_count = v.round();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: FlamingoColors.scaffoldBg,
        elevation: 0,
        title: const Text('DICE ROLLER',
            style: TextStyle(
                color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Two dice sets side-by-side
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _diceSet(label: 'A', active: !_rolling),
                    const SizedBox(width: 8),
                    _diceSet(label: 'B', active: !_rolling),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Summary line
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _rolling
                      ? 'ROLLING...'
                      : 'Tap ROLL (+equal sides plays both)',
                  style: const TextStyle(
                    color: FlamingoColors.muted,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Material(
                color: FlamingoColors.primary.withValues(alpha: 0.15),
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _rolling
                      ? null
                      : () {
                          if (_setA_sides == _setB_sides) {
                            _roll();
                          } else {
                            setState(() => _rolling = true);
                            Vibration.vibrate(duration: 100);
                            Future.delayed(
                                const Duration(milliseconds: 200), () {
                              if (!mounted) return;
                              setState(() => _rolling = false);
                            });
                          }
                        },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
                    child: Text(
                      _rolling ? 'ROLLING' : 'ROLL',
                      style: TextStyle(
                        color: _rolling ? FlamingoColors.muted : FlamingoColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
