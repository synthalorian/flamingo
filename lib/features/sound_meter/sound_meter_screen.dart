import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

class SoundMeterScreen extends StatefulWidget {
  const SoundMeterScreen({super.key});

  @override
  State<SoundMeterScreen> createState() => _SoundMeterScreenState();
}

class _SoundMeterScreenState extends State<SoundMeterScreen>
    with SingleTickerProviderStateMixin {
  bool _recording = false;
  double _volume = 0;
  double _dbSpl = 0;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;
  final List<double> _waveform = List.filled(40, 0);

  // Full-scale mic input on phones ≈ 94 dB SPL (standard approximation).
  static const double _dbSplOffset = 94.0;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  Future<void> _startRecord() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mic.isPermanentlyDenied) await openAppSettings();
      return;
    }

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );
      _audioSub = stream.listen(_onAudioData);
      setState(() => _recording = true);
    } catch (_) {
      setState(() => _recording = false);
    }
  }

  void _onAudioData(Uint8List data) {
    if (!_recording || !mounted || data.length < 2) return;

    // RMS of PCM16 little-endian samples.
    final samples = data.buffer.asByteData();
    var sum = 0.0;
    final count = samples.lengthInBytes ~/ 2;
    for (int i = 0; i < count; i++) {
      final s = samples.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
    }
    final rms = math.sqrt(sum / count);

    // dBFS -> approximate SPL, clamped to the 0..120 display range.
    final dbfs = 20 * math.log(rms + 1e-9) / math.ln10;
    final spl = (dbfs + _dbSplOffset).clamp(0.0, 120.0);

    // Perceptual 0..1 level for VU/waveform, smoothed against jitter.
    final level = (spl / 120.0).clamp(0.0, 1.0);
    final smoothed = _volume * 0.6 + level * 0.4;

    for (int i = 0; i < _waveform.length - 1; i++) {
      _waveform[i] = _waveform[i + 1];
    }
    _waveform[_waveform.length - 1] = level;

    setState(() {
      _volume = smoothed;
      _dbSpl = spl;
    });
  }

  Future<void> _stopRecord() async {
    _recording = false;
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    setState(() {
      _volume = 0;
      _dbSpl = 0;
      _waveform.fillRange(0, _waveform.length, 0);
    });
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    _recorder.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  double get _db => _dbSpl;

  String get _levelLabel {
    final db = _db;
    if (!_recording) return '—';
    if (db < 30) return 'Very Quiet';
    if (db < 50) return 'Quiet';
    if (db < 60) return 'Moderate';
    if (db < 70) return 'Loud';
    if (db < 80) return 'Very Loud';
    return 'Extreme';
  }

  Color _levelColor(ColorScheme cs) {
    if (!_recording) return cs.onSurfaceVariant;
    final db = _db;
    if (db < 40) return cs.primary;
    if (db < 60) return cs.secondary;
    if (db < 75) return cs.tertiary;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final levelColor = _levelColor(cs);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _recording ? 5 : 2,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SOUND METER',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // dB readout
                  Text(
                    _recording ? '${_db.toStringAsFixed(1)}' : '—',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                      shadows: _recording
                          ? [
                              Shadow(
                                color: levelColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Text(
                    'dB',
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Level label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _levelLabel,
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Waveform visualization
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (context, child) {
                      return SizedBox(
                        width: 300,
                        height: 80,
                        child: CustomPaint(
                          painter: _WaveformPainter(
                            waveform: _waveform,
                            color: levelColor,
                            glowIntensity: _glowAnim.value,
                            recording: _recording,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // VU Meter bar
                  Container(
                    width: 300,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        width: 300 * (_recording ? _volume : 0),
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              cs.secondary,
                              cs.tertiary,
                              Colors.redAccent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Scale markers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '45',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '90',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '120',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Button
                  GestureDetector(
                    onTap: _recording ? _stopRecord : _startRecord,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: (_recording ? cs.tertiary : cs.primary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (_recording ? cs.tertiary : cs.primary)
                              .withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _recording ? Icons.stop : Icons.mic,
                            color: _recording ? cs.tertiary : cs.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _recording ? 'STOP' : 'MEASURE',
                            style: TextStyle(
                              color: _recording ? cs.tertiary : cs.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Live mic · analyzed on-device only',
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;
  final double glowIntensity;
  final bool recording;

  _WaveformPainter({
    required this.waveform,
    required this.color,
    required this.glowIntensity,
    required this.recording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!recording) return;

    final barWidth = size.width / waveform.length;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.1 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < waveform.length; i++) {
      final x = i * barWidth;
      final val = waveform[i];
      final barHeight = val * size.height;

      // Glow
      canvas.drawRect(
        Rect.fromLTWH(x + 1, size.height - barHeight, barWidth - 2, barHeight),
        glowPaint,
      );

      // Bar
      canvas.drawRect(
        Rect.fromLTWH(x + 1, size.height - barHeight, barWidth - 2, barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => true;
}
