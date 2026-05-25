import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../core/widgets/crt_background.dart';

class PasswordGenScreen extends StatefulWidget {
  const PasswordGenScreen({super.key});

  @override
  State<PasswordGenScreen> createState() => _PasswordGenScreenState();
}

class _PasswordGenScreenState extends State<PasswordGenScreen>
    with SingleTickerProviderStateMixin {
  int _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _digits = true;
  bool _symbols = true;
  String _password = '';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _generated = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const symbols = r"!@#\$%^&*()_+-=";

    String pool = '';
    if (_uppercase) pool += upper;
    if (_lowercase) pool += lower;
    if (_digits) pool += digits;
    if (_symbols) pool += symbols;

    if (pool.isEmpty) {
      setState(() => _password = 'Select at least one charset');
      return;
    }

    final rng = math.Random.secure();
    final chars = List.generate(_length, (_) => pool[rng.nextInt(pool.length)]);
    final result = chars.join();

    setState(() {
      _password = result;
      _generated = true;
    });
    _pulseCtrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _pulseCtrl.stop();
    });

    Vibration.vibrate(duration: 30);
  }

  void _copy() {
    if (_password.isEmpty || _password.startsWith('Select')) return;
    Clipboard.setData(ClipboardData(text: _password));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get _entropy {
    int poolSize = 0;
    if (_uppercase) poolSize += 26;
    if (_lowercase) poolSize += 26;
    if (_digits) poolSize += 10;
    if (_symbols) poolSize += 10;
    if (poolSize == 0) return 0;
    return (_length * math.log(poolSize) / math.log(2)).floor();
  }

  Color _strengthColor(int e, ColorScheme cs) {
    if (e <= 0) return cs.onSurfaceVariant;
    if (e < 40) return Colors.redAccent;
    if (e < 60) return Colors.orangeAccent;
    if (e < 80) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  String _strengthLabel(int e) {
    if (e <= 0) return '';
    if (e < 40) return 'Weak';
    if (e < 60) return 'Fair';
    if (e < 80) return 'Strong';
    return 'Excellent';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sc = _strengthColor(_entropy, cs);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'PASSWORD GENERATOR',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Password output with glow
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _generated ? _pulseAnim.value : 1.0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sc.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: sc.withValues(alpha: 0.1),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _password.isEmpty ||
                                            _password.startsWith('Select')
                                        ? '••••••••••••••••'
                                        : _password,
                                    style: TextStyle(
                                      color: _password.startsWith('Select')
                                          ? Colors.redAccent
                                          : cs.onSurface,
                                      fontSize: 20,
                                      fontFamily: 'monospace',
                                      letterSpacing: _generated ? 2 : 1,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    color: cs.primary,
                                    onPressed: _copy,
                                    splashRadius: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Strength bar + label
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: _entropy.clamp(0, 128) / 128,
                                      backgroundColor: cs.surfaceContainerHigh,
                                      valueColor: AlwaysStoppedAnimation(sc),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _strengthLabel(_entropy),
                                  style: TextStyle(
                                    color: sc,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_entropy} bits',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Length slider
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LENGTH',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$_length',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 22,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: cs.primary,
                          inactiveTrackColor: cs.surfaceContainerHigh,
                          thumbColor: cs.primary,
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                          overlayColor: cs.primary.withValues(alpha: 0.3),
                        ),
                        child: Slider(
                          value: _length.toDouble(),
                          min: 4,
                          max: 64,
                          onChanged: (v) => setState(() => _length = v.round()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Charset toggles
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHARSET',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _toggleChip(
                              'A-Z',
                              _uppercase,
                              () => setState(() => _uppercase = !_uppercase),
                              cs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _toggleChip(
                              'a-z',
                              _lowercase,
                              () => setState(() => _lowercase = !_lowercase),
                              cs,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _toggleChip(
                              '0-9',
                              _digits,
                              () => setState(() => _digits = !_digits),
                              cs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _toggleChip(
                              '!@#',
                              _symbols,
                              () => setState(() => _symbols = !_symbols),
                              cs,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: cs.primary.withValues(alpha: 0.15),
                    surfaceTintColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _generate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 18, color: cs.primary),
                            const SizedBox(width: 10),
                            Text(
                              'GENERATE',
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

  Widget _toggleChip(
    String label,
    bool active,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return Material(
      color: active
          ? cs.primary.withValues(alpha: 0.2)
          : cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? cs.primary : cs.onSurfaceVariant,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
