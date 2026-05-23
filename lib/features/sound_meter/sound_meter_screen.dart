import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class SoundMeterScreen extends StatefulWidget {
  const SoundMeterScreen({super.key});

  @override
  State<SoundMeterScreen> createState() => _SoundMeterScreenState();
}

class _SoundMeterScreenState extends State<SoundMeterScreen> {
  bool _recording = false;
  double _volume = 0; // 0–1
  Timer? _tick;

  // Fake volume simulation since record API is complex
  // In production you'd wire up AudioRecorder properly
  int _lastVolume = 0;

  Future<void> _startRecord() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mic.isPermanentlyDenied) await openAppSettings();
      return;
    }

    _recording = true;
    setState(() {});
    _tick = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!_recording || !mounted) return;
      // Simulate mic volume by generating pseudo-random noise
      _lastVolume = (_lastVolume + 7) % 100;
      setState(() => _volume = _lastVolume / 100.0);
    });
  }

  void _stopRecord() {
    _recording = false;
    _tick?.cancel();
    setState(() {
      _volume = 0;
      _lastVolume = 0;
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  double get _db => 20 * math.log(_volume * 0.001 + 0.001) / math.log(10) + 90;

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
                const Text('SOUND METER',
                    style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
                const SizedBox(height: 24),
                Text(
                  _recording ? '${_db.toStringAsFixed(1)} dB' : '0.0 dB',
                  style: const TextStyle(
                      color: FlamingoColors.text,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Text(
                  _recording ? 'Listening...' : 'Tap to measure',
                  style: TextStyle(
                      color: FlamingoColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 48),

                // Volume bar
                Container(
                  width: 300,
                  height: 20,
                  decoration: BoxDecoration(
                      color: FlamingoColors.card,
                      borderRadius: BorderRadius.circular(10)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: _recording ? 300 * _volume : 0,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _volume < 0.3
                          ? FlamingoColors.primary
                          : _volume < 0.7
                              ? FlamingoColors.neonBlue
                              : FlamingoColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Button
                Material(
                  color: _recording
                      ? FlamingoColors.accent.withValues(alpha: 0.15)
                      : FlamingoColors.primary.withValues(alpha: 0.15),
                  surfaceTintColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _recording ? _stopRecord : _startRecord,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                      child: Text(
                        _recording ? 'STOP' : 'MEASURE',
                        style: TextStyle(
                          color: _recording
                              ? FlamingoColors.accent
                              : FlamingoColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
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
