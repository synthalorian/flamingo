import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

const List<int> _allSides = [4, 6, 8, 10, 12, 20];

/// Animated die face that shows a rolling animation with a final result.
class _AnimatedDie extends StatefulWidget {
  final int sides;
  final int result;
  final bool rolling;
  final double size;

  const _AnimatedDie({
    required this.sides,
    required this.result,
    required this.rolling,
    required this.size,
  });

  @override
  State<_AnimatedDie> createState() => _AnimatedDieState();
}

class _AnimatedDieState extends State<_AnimatedDie>
    with TickerProviderStateMixin {
  late AnimationController _rollController;
  late Animation<double> _rollAnim;
  int _displayValue = 1;

  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rollAnim = CurvedAnimation(
      parent: _rollController,
      curve: Curves.elasticOut,
    );
    _displayValue = widget.result;
    if (widget.rolling) {
      _rollController.forward();
      _animateDice();
    }
  }

  void _animateDice() {
    if (!widget.rolling) return;
    // Rapid-fire random numbers during roll
    int tick = 0;
    Timer.periodic(const Duration(milliseconds: 40), (t) {
      if (!widget.rolling || tick >= 14) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          _displayValue = widget.result;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _displayValue = math.Random.secure().nextInt(widget.sides) + 1;
      });
      tick++;
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling != oldWidget.rolling) {
      if (widget.rolling) {
        _rollController.forward();
        _animateDice();
      }
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rollAnim,
      builder: (context, child) {
        final scale = _rollAnim.value;
        final rotation = _rollAnim.value * math.pi * 2;

        return Transform.scale(
          scale: 0.8 + scale * 0.2,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: widget.size,
              height: widget.size,
              margin: EdgeInsets.all(widget.size * 0.08),
              decoration: BoxDecoration(
                color: FlamingoColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FlamingoColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: FlamingoColors.primary.withValues(alpha: 0.2 * scale),
                    blurRadius: 6 * scale,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_displayValue',
                  style: TextStyle(
                    color: FlamingoColors.primary,
                    fontSize: widget.size * 0.42,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
  bool _dualMode = false;

  // Results for each set
  List<int> _resultsA = [];
  List<int> _resultsB = [];

  void _roll() {
    setState(() => _rolling = true);
    Vibration.vibrate(duration: 100);

    // Generate all results upfront
    _resultsA = List.generate(_setA_count, (_) => _rng.nextInt(_setA_sides) + 1);
    if (_dualMode) {
      _resultsB = List.generate(_setB_count, (_) => _rng.nextInt(_setB_sides) + 1);
    }

    // Duration scales with total dice count for satisfying roll
    final totalDice = _setA_count + (_dualMode ? _setB_count : 0);
    final duration = (100 + totalDice * 30).clamp(200, 800);

    Future.delayed(Duration(milliseconds: duration), () {
      if (!mounted) return;
      setState(() => _rolling = false);
    });
  }

  Widget _modeChip(String label, bool isDual) {
    final active = _dualMode == isDual;
    return Material(
      color: active
          ? FlamingoColors.primary.withValues(alpha: 0.2)
          : FlamingoColors.card,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _dualMode = isDual),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: active ? FlamingoColors.primary : FlamingoColors.muted,
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              letterSpacing: 1,
            ),
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
    final results = label == 'A' ? _resultsA : _resultsB;

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
            Text('d$sides · ${count == 1 ? "1 die" : "$count dice"}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FlamingoColors.muted,
                  fontSize: 11,
                )),
            const SizedBox(height: 8),
            // Dice display
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: results.isEmpty
                  ? [Text('—', style: TextStyle(color: FlamingoColors.muted))]
                  : List.generate(results.length, (i) {
                      return _AnimatedDie(
                        sides: sides,
                        result: results[i],
                        rolling: _rolling,
                        size: 52,
                      );
                    }),
            ),
            // Total line
            if (results.isNotEmpty && !_rolling)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Total: ${results.fold<int>(0, (a, b) => a + b)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FlamingoColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
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
            // Count selector — quick chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: List.generate(6, (i) {
                final c = i + 1;
                final isActive = (label == 'A' ? _setA_count : _setB_count) == c;
                return Material(
                  color: isActive
                      ? FlamingoColors.primary.withValues(alpha: 0.2)
                      : FlamingoColors.card,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        if (label == 'A') {
                          _setA_count = c;
                        } else {
                          _setB_count = c;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        '×$c',
                        style: TextStyle(
                          color: isActive ? FlamingoColors.primary : FlamingoColors.muted,
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                );
              }),
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
        title: Text('DICE ROLLER',
            style: TextStyle(
                color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Mode toggle + dice sets
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    // Mode toggle chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _modeChip('Single', false),
                        const SizedBox(width: 8),
                        _modeChip('Dual', true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Dice sets
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _diceSet(label: 'A', active: !_rolling),
                        ),
                        if (_dualMode) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _diceSet(label: 'B', active: !_rolling),
                          ),
                        ],
                      ],
                    ),
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
                      : (_dualMode ? 'Tap ROLL' : 'Tap to roll'),
                  style: TextStyle(
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
                  onTap: _rolling ? null : _roll,
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
