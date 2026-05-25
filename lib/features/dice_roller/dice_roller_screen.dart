import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

const List<int> _allSides = [4, 6, 8, 10, 12, 20];

/// Beautiful animated die face with per-die-type styling.
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
  late AnimationController _bounceCtrl;
  late AnimationController _spinCtrl;
  late Animation<double> _bounceAnim;
  late Animation<double> _spinAnim;
  int _displayValue = 1;
  Timer? _rollTimer;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _spinCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.elasticOut,
    );
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOutCubic);
    _displayValue = widget.result;
    if (widget.rolling) {
      _startRoll();
    }
  }

  void _startRoll() {
    _bounceCtrl.forward(from: 0);
    _spinCtrl.forward(from: 0);
    int tick = 0;
    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(milliseconds: 35), (t) {
      if (!widget.rolling || tick >= 16) {
        t.cancel();
        if (!mounted) return;
        setState(() => _displayValue = widget.result);
        return;
      }
      if (!mounted) return;
      setState(() {
        _displayValue = math.Random().nextInt(widget.sides) + 1;
      });
      tick++;
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) {
      _startRoll();
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _spinCtrl.dispose();
    _rollTimer?.cancel();
    super.dispose();
  }

  Color _dieColor(int sides) {
    switch (sides) {
      case 4:
        return const Color(0xFFFF69B4); // hot pink
      case 6:
        return const Color(0xFF00D4FF); // cyan
      case 8:
        return const Color(0xFFB026FF); // purple
      case 10:
        return const Color(0xFFFFD700); // gold
      case 12:
        return const Color(0xFFFF4500); // orange-red
      case 20:
        return const Color(0xFF39FF14); // neon green
      default:
        return const Color(0xFFFF69B4);
    }
  }

  IconData _dieIcon(int sides) {
    switch (sides) {
      case 4:
        return Icons.change_history;
      case 6:
        return Icons.stop;
      case 8:
        return Icons.diamond;
      case 10:
        return Icons.hexagon;
      case 12:
        return Icons.square;
      case 20:
        return Icons.circle;
      default:
        return Icons.casino;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dieColor = _dieColor(widget.sides);

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnim, _spinAnim]),
      builder: (context, child) {
        final bounceScale = 0.8 + _bounceAnim.value * 0.2;
        final spinAngle = _spinAnim.value * math.pi * 2;
        final isRolling = widget.rolling;

        return Transform.scale(
          scale: bounceScale,
          child: Transform.rotate(
            angle: spinAngle,
            child: Container(
              width: widget.size,
              height: widget.size,
              margin: EdgeInsets.all(widget.size * 0.06),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    dieColor.withValues(alpha: 0.9),
                    dieColor.withValues(alpha: 0.4),
                    dieColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dieColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: dieColor.withValues(alpha: isRolling ? 0.4 : 0.2),
                    blurRadius: isRolling ? 16 : 8,
                    spreadRadius: isRolling ? 4 : 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Die type indicator (small icon in corner)
                  Positioned(
                    top: 2,
                    right: 3,
                    child: Icon(
                      _dieIcon(widget.sides),
                      size: widget.size * 0.18,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  // Value
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_displayValue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.size * 0.38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'd${widget.sides}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: widget.size * 0.13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
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

class _DiceRollerScreenState extends State<DiceRollerScreen>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random.secure();
  int _setA_count = 1;
  int _setA_sides = 6;
  int _setB_count = 2;
  int _setB_sides = 6;
  bool _rolling = false;
  bool _dualMode = false;

  List<int> _resultsA = [];
  List<int> _resultsB = [];

  // Animation for roll button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _roll() {
    setState(() => _rolling = true);
    Vibration.vibrate(duration: 50);

    _resultsA = List.generate(
      _setA_count,
      (_) => _rng.nextInt(_setA_sides) + 1,
    );
    if (_dualMode) {
      _resultsB = List.generate(
        _setB_count,
        (_) => _rng.nextInt(_setB_sides) + 1,
      );
    }

    final totalDice = _setA_count + (_dualMode ? _setB_count : 0);
    final duration = (200 + totalDice * 40).clamp(500, 1200);

    Future.delayed(Duration(milliseconds: duration), () {
      if (!mounted) return;
      setState(() => _rolling = false);
      Vibration.vibrate(duration: 30);
    });
  }

  void _rollAgain() {
    if (_rolling) return;
    _roll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DICE ROLLER',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: 4,
          colors: [cs.primary, cs.tertiary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Mode toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeChip(cs, 'Single', false),
                    const SizedBox(width: 8),
                    _modeChip(cs, 'Dual', true),
                  ],
                ),
                const SizedBox(height: 10),

                // Dice sets
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _diceSet(
                            cs,
                            'A',
                            _setA_count,
                            _setA_sides,
                            _resultsA,
                            (c) => _setA_count = c,
                            (s) => _setA_sides = s,
                          ),
                        ),
                        if (_dualMode) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _diceSet(
                              cs,
                              'B',
                              _setB_count,
                              _setB_sides,
                              _resultsB,
                              (c) => _setB_count = c,
                              (s) => _setB_sides = s,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Animated Roll button
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    final pulse = _pulseAnim.value;
                    return GestureDetector(
                      onTap: _rolling ? null : _rollAgain,
                      child: Container(
                        width: 200,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              cs.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(
                                alpha: _rolling ? 0.2 : 0.3 + 0.2 * pulse,
                              ),
                              blurRadius: _rolling ? 12 : 16 + 8 * pulse,
                              spreadRadius: _rolling ? 2 : 2 + 2 * pulse,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_rolling)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(
                                Icons.casino,
                                color: Colors.white,
                                size: 24,
                              ),
                            const SizedBox(width: 10),
                            Text(
                              _rolling ? 'ROLLING...' : 'ROLL DICE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Quick tap to roll hint
                if (!_rolling && (_resultsA.isNotEmpty || _resultsB.isNotEmpty))
                  GestureDetector(
                    onTap: _rollAgain,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Tap to roll again',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(ColorScheme cs, String label, bool isDual) {
    final active = _dualMode == isDual;
    return GestureDetector(
      onTap: () => setState(() => _dualMode = isDual),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.2),
                    cs.primary.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: active ? null : cs.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? cs.primary : cs.onSurfaceVariant,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _diceSet(
    ColorScheme cs,
    String label,
    int count,
    int sides,
    List<int> results,
    ValueChanged<int> onCountChanged,
    ValueChanged<int> onSidesChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SET $label',
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'd$sides · $count ${count == 1 ? "die" : "dice"}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Dice display
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: results.isEmpty
                      ? [
                          Icon(
                            Icons.casino_outlined,
                            size: 36,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                        ]
                      : List.generate(results.length, (i) {
                          return _AnimatedDie(
                            sides: sides,
                            result: results[i],
                            rolling: _rolling,
                            size: 56,
                          );
                        }),
                ),
              ),
            ),
          ),

          // Total
          if (results.isNotEmpty && !_rolling)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: ${results.fold<int>(0, (a, b) => a + b)}',
                style: TextStyle(
                  color: cs.tertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
              final isActive = sides == s;
              return GestureDetector(
                onTap: () => onSidesChanged(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.tertiary.withValues(alpha: 0.15)
                        : cs.surfaceContainerLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? cs.tertiary.withValues(alpha: 0.3)
                          : cs.outlineVariant.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    'd$s',
                    style: TextStyle(
                      color: isActive ? cs.tertiary : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),

          // Count selector
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: List.generate(6, (i) {
              final c = i + 1;
              final isActive = count == c;
              return GestureDetector(
                onTap: () => onCountChanged(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.surfaceContainerLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? cs.primary.withValues(alpha: 0.3)
                          : cs.outlineVariant.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '\u00d7$c',
                    style: TextStyle(
                      color: isActive ? cs.primary : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
