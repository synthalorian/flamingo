import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  int _bpm = 120;
  bool _running = false;
  Timer? _tick;
  bool _flash = false;
  int _beat = 0;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _tick?.cancel();
      setState(() { _running = false; _flash = false; _beat = 0; });
    } else {
      _tick = Timer.periodic(Duration(milliseconds: (60000 / _bpm).round()), (_) {
        Vibration.vibrate(duration: 15);
        setState(() {
          _flash = !_flash;
          _beat++;
        });
      });
      setState(() => _running = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('METRONOME',
                    style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 36),
                      color: FlamingoColors.primary,
                      onPressed: _running ? null : () => setState(() => _bpm = (_bpm - 5).clamp(40, 200)),
                    ),
                    const SizedBox(width: 32),
                    Text(
                      '$_bpm',
                      style: TextStyle(
                        color: FlamingoColors.text,
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 36),
                      color: FlamingoColors.primary,
                      onPressed: _running ? null : () => setState(() => _bpm = (_bpm + 5).clamp(40, 200)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('BPM', style: TextStyle(color: FlamingoColors.muted, fontSize: 13)),
                const SizedBox(height: 32),

                // Flash indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: _flash ? 24 : 16,
                  height: _flash ? 24 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _flash
                        ? (_beat % 4 == 0 ? FlamingoColors.accent : FlamingoColors.primary)
                        : FlamingoColors.cardBorder,
                    boxShadow: _flash
                        ? [BoxShadow(
                            color: (_beat % 4 == 0 ? FlamingoColors.accent : FlamingoColors.primary).withValues(alpha: 0.6),
                            blurRadius: 24,
                            spreadRadius: 4,
                          )]
                        : null,
                  ),
                ),
                const SizedBox(height: 32),

                // Start button
                Material(
                  color: _running
                      ? FlamingoColors.accent.withValues(alpha: 0.15)
                      : FlamingoColors.primary.withValues(alpha: 0.15),
                  surfaceTintColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _toggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                      child: Text(
                        _running ? 'STOP' : 'START',
                        style: TextStyle(
                          color: _running ? FlamingoColors.accent : FlamingoColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}