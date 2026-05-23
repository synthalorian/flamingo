import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class PasswordGenScreen extends StatefulWidget {
  const PasswordGenScreen({super.key});

  @override
  State<PasswordGenScreen> createState() => _PasswordGenScreenState();
}

class _PasswordGenScreenState extends State<PasswordGenScreen> {
  int _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _digits = true;
  bool _symbols = true;
  String _password = '';

  void _generate() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
 final symbols = r"!@#\$%^&*()_+-=";

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

    setState(() => _password = result);
    Vibration.vibrate(duration: 30);
  }

  void _copy() {
    if (_password.isEmpty || _password.startsWith('Select')) return;
    Clipboard.setData(ClipboardData(text: _password));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
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

  @override
  Widget build(BuildContext context) {
    final strengthColor = _entropy <= 0
        ? FlamingoColors.muted
        : _entropy < 40
            ? Colors.redAccent
            : _entropy < 80
                ? FlamingoColors.accent
                : FlamingoColors.primary;

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('PASSWORD GENERATOR',
                    style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
                const SizedBox(height: 32),

                // Password output
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FlamingoColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _password.isEmpty || _password.startsWith('Select')
                                ? '••••••••••••••••'
                                : _password,
                            style: const TextStyle(
                              color: FlamingoColors.text,
                              fontSize: 18,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            color: FlamingoColors.primary,
                            onPressed: _copy,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Entropy bar
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _entropy.clamp(0, 128) / 128,
                              backgroundColor: FlamingoColors.cardBorder,
                              valueColor: AlwaysStoppedAnimation(strengthColor),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_entropy} bits',
                            style: TextStyle(color: strengthColor, fontSize: 13, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Length slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Text('Length:', style: TextStyle(color: FlamingoColors.muted)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: FlamingoColors.primary,
                            inactiveTrackColor: FlamingoColors.cardBorder,
                            thumbColor: FlamingoColors.primary,
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _length.toDouble(),
                            onChanged: (v) => setState(() => _length = v.round()),
                            onChangeStart: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      Text('$_length', style: const TextStyle(color: FlamingoColors.text, fontSize: 18, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Charset toggles
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _toggleChip('A-Z', _uppercase, () => setState(() => _uppercase = !_uppercase)),
                    _toggleChip('a-z', _lowercase, () => setState(() => _lowercase = !_lowercase)),
                    _toggleChip('0-9', _digits, () => setState(() => _digits = !_digits)),
                    _toggleChip('!@#', _symbols, () => setState(() => _symbols = !_symbols)),
                  ],
                ),
                const Spacer(),

                // Generate button
                Material(
                  color: FlamingoColors.primary.withValues(alpha: 0.15),
                  surfaceTintColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _generate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                      child: const Text('GENERATE',
                          style: TextStyle(color: FlamingoColors.primary, fontWeight: FontWeight.w600, letterSpacing: 3)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? FlamingoColors.primary.withValues(alpha: 0.2) : FlamingoColors.card,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  color: active ? FlamingoColors.primary : FlamingoColors.muted,
                  fontSize: 14)),
        ),
      ),
    );
  }
}
