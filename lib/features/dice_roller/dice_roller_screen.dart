import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class DiceRollerScreen extends StatefulWidget {
  const DiceRollerScreen({super.key});

  @override
  State<DiceRollerScreen> createState() => _DiceRollerScreenState();
}

class _DiceRollerScreenState extends State<DiceRollerScreen> {
  final math.Random _rng = math.Random.secure();
  int _diceCount = 1;
  int _sides = 6;
  List<int> _results = [];
  bool _rolling = false;

  void _roll() {
    setState(() {
      _rolling = true;
      _results = List.generate(_diceCount, (_) => _rng.nextInt(_sides) + 1);
    });
    Vibration.vibrate(duration: 100);
  }

  Widget _die(int value, {double size = 64}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FlamingoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlamingoColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: FlamingoColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            color: FlamingoColors.primary,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text('DICE ROLLER',
                  style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Dice: $_diceCount', style: const TextStyle(color: FlamingoColors.text, fontSize: 15)),
                    const Text('|', style: TextStyle(color: FlamingoColors.muted)),
                    Text('d$_sides', style: const TextStyle(color: FlamingoColors.text, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _rolling || _results.isEmpty
                        ? _diceCount > 0
                            ? List.generate(_results.length, (i) => _die(_results[i]))
                            : [const Text('Tap ROLL to roll dice', style: TextStyle(color: FlamingoColors.muted))]
                        : List.generate(_results.length, (i) => _die(_results[i])),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: FlamingoColors.primary.withValues(alpha: 0.15),
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _roll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                    child: const Text('ROLL',
                        style: TextStyle(color: FlamingoColors.primary, fontWeight: FontWeight.w600, letterSpacing: 3)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
