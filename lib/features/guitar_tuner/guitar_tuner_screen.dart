import 'dart:async';
import 'dart:math' as math;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

/// Standard tuning frequencies for guitar and bass.
class _Tuning {
  final String label;
  final List<_StringDef> strings;

  const _Tuning({required this.label, required this.strings});
}

class _StringDef {
  final String name;
  final double freq;

  const _StringDef({required this.name, required this.freq});
}

const _guitarTuning = _Tuning(
  label: 'Guitar',
  strings: [
    _StringDef(name: 'E', freq: 82.41),
    _StringDef(name: 'A', freq: 110.0),
    _StringDef(name: 'D', freq: 146.83),
    _StringDef(name: 'G', freq: 196.0),
    _StringDef(name: 'B', freq: 246.94),
    _StringDef(name: 'E', freq: 329.63),
  ],
);

const _bassTuning = _Tuning(
  label: 'Bass',
  strings: [
    _StringDef(name: 'E', freq: 41.20),
    _StringDef(name: 'A', freq: 55.0),
    _StringDef(name: 'D', freq: 73.42),
    _StringDef(name: 'G', freq: 98.0),
  ],
);

/// All 12 chromatic note names.
const _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F',
  'F#', 'G', 'G#', 'A', 'A#', 'B',
];

/// Return the chromatic note name for a MIDI note number.
String _midiToNoteName(double midi) {
  final note = (midi.round() % 12 + 12) % 12;
  return _noteNames[note];
}

class GuitarTunerScreen extends StatefulWidget {
  const GuitarTunerScreen({super.key});

  @override
  State<GuitarTunerScreen> createState() => _GuitarTunerScreenState();
}

class _GuitarTunerScreenState extends State<GuitarTunerScreen> {
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  bool _listening = false;

  _Tuning _tuning = _guitarTuning;
  int _selectedString = 2; // Start on D

  double _detectedFreq = 0;
  double _centsOff = 0;
  bool _hasSignal = false;

  // Audio buffer for pitch detection
  static const _sampleRate = 44100;
  static const _bufferSize = 4096;
  final _buffer = <double>[];

  @override
  void dispose() {
    _stopListening();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for the tuner'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          autoGain: true,
        ),
      );

      _sub = stream.listen(
        _processAudioData,
        onError: (e) {
          debugPrint('Tuner audio error: $e');
        },
      );

      setState(() => _listening = true);
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start tuner: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
    _recorder.stop();
    _buffer.clear();
    setState(() {
      _listening = false;
      _hasSignal = false;
      _detectedFreq = 0;
      _centsOff = 0;
    });
  }

  void _processAudioData(Uint8List samples) {
    // Convert PCM16 bytes to float samples
    for (int i = 1; i < samples.length; i += 2) {
      final sample = (samples[i - 1] | (samples[i] << 8)).toSigned(16);
      _buffer.add(sample / 32768.0);
    }

    // Keep buffer at a reasonable size
    while (_buffer.length > _bufferSize * 2) {
      _buffer.removeRange(0, _bufferSize);
    }

    if (_buffer.length < _bufferSize) return;

    // Take the most recent buffer_size samples
    final chunk = _buffer.sublist(_buffer.length - _bufferSize, _buffer.length);

    // Calculate RMS level
    double sumSq = 0;
    for (final s in chunk) {
      sumSq += s * s;
    }
    final rms = math.sqrt(sumSq / chunk.length);

    if (rms < 0.005) {
      // Too quiet
      if (_hasSignal) {
        setState(() {
          _hasSignal = false;
          _detectedFreq = 0;
          _centsOff = 0;
        });
      }
      return;
    }

    // Use wide-range autocorrelation for pitch detection
    // Search from C1 (33 Hz, lag ~1336) up to C7 (2093 Hz, lag ~21)
    final minLag = 20;
    final maxLag = (_sampleRate / 30).round().clamp(minLag + 1, _bufferSize ~/ 2);

    double bestLag = 0;
    double bestCorr = 0;

    for (int lag = minLag; lag <= maxLag && lag < chunk.length ~/ 2; lag++) {
      double corr = 0;
      double norm = 0;
      for (int i = 0; i < chunk.length - lag; i++) {
        corr += chunk[i] * chunk[i + lag];
        norm += chunk[i] * chunk[i] + chunk[i + lag] * chunk[i + lag];
      }
      if (norm > 0) {
        corr /= math.sqrt(norm);
      }
      if (corr > bestCorr) {
        bestCorr = corr;
        bestLag = lag.toDouble();
      }
    }

    if (bestLag < 2 || bestCorr < 0.1) {
      if (_hasSignal) {
        setState(() {
          _hasSignal = false;
          _detectedFreq = 0;
          _centsOff = 0;
        });
      }
      return;
    }

    // Parabolic interpolation for sub-sample accuracy
    double fineLag = bestLag;
    if (bestLag > 1 && bestLag < chunk.length ~/ 2 - 1) {
      final prevCorr = _autocorr(chunk, bestLag.round() - 1);
      final currCorr = _autocorr(chunk, bestLag.round());
      final nextCorr = _autocorr(chunk, bestLag.round() + 1);
      if (prevCorr > 0 && nextCorr > 0) {
        final a = (prevCorr + nextCorr - 2 * currCorr) / 2;
        final b = (nextCorr - prevCorr) / 2;
        if (a.abs() > 1e-12) {
          fineLag = bestLag.round() - b / (2 * a);
        }
      }
    }

    final detectedFreq = _sampleRate / fineLag;

    // Find closest target string
    final targetFreq = _tuning.strings[_selectedString].freq;
    final cents = 1200 * (math.log(detectedFreq / targetFreq) / math.log(2));

    if (mounted) {
      setState(() {
        _hasSignal = true;
        _detectedFreq = detectedFreq;
        _centsOff = cents.clamp(-50, 50);
      });
    }
  }

  double _autocorr(List<double> data, int lag) {
    double corr = 0;
    double norm = 0;
    for (int i = 0; i < data.length - lag; i++) {
      corr += data[i] * data[i + lag];
      norm += data[i] * data[i] + data[i + lag] * data[i + lag];
    }
    return norm > 0 ? corr / math.sqrt(norm) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final targetString = _tuning.strings[_selectedString];
    final noteName = _hasSignal
        ? _midiToNoteName(12 * (math.log(_detectedFreq / 440) / math.log(2)) + 69)
        : targetString.name;

    String statusText;
    Color statusColor;
    if (!_listening) {
      statusText = 'Tap to start';
      statusColor = cs.onSurfaceVariant;
    } else if (!_hasSignal) {
      statusText = 'Play a string...';
      statusColor = cs.onSurfaceVariant;
    } else if (_centsOff.abs() < 3) {
      statusText = '✓ In Tune!';
      statusColor = Colors.greenAccent;
    } else if (_centsOff > 0) {
      statusText = '♯ Sharp — tune down';
      statusColor = const Color(0xFFFF8A65);
    } else {
      statusText = '♭ Flat — tune up';
      statusColor = const Color(0xFF64B5F6);
    }

    final needlePos = (_centsOff / 50).clamp(-1.0, 1.0);
    final deviation = needlePos.abs();

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _listening ? 4 : 2,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'TUNER',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _listening ? 'Mic active — play a string' : 'Guitar / Bass tuner',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 20),

                // Tuning selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeBtn(cs, 'Guitar', _tuning == _guitarTuning, () {
                      setState(() {
                        _tuning = _guitarTuning;
                        if (_selectedString >= _guitarTuning.strings.length) {
                          _selectedString = _guitarTuning.strings.length - 1;
                        }
                      });
                    }),
                    const SizedBox(width: 12),
                    _modeBtn(cs, 'Bass', _tuning == _bassTuning, () {
                      setState(() {
                        _tuning = _bassTuning;
                        if (_selectedString >= _bassTuning.strings.length) {
                          _selectedString = _bassTuning.strings.length - 1;
                        }
                      });
                    }),
                  ],
                ),

                const SizedBox(height: 24),

                // String selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: _tuning.strings.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final s = entry.value;
                      final active = idx == _selectedString;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedString = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            height: 72,
                            decoration: BoxDecoration(
                              color: active
                                  ? cs.primary.withValues(alpha: 0.15)
                                  : cs.surfaceContainerHigh.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? cs.primary.withValues(alpha: 0.5)
                                    : cs.outlineVariant.withValues(alpha: 0.1),
                                width: active ? 1.5 : 1,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: cs.primary.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    color: active ? cs.primary : cs.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.freq.toStringAsFixed(1)}Hz',
                                  style: TextStyle(
                                    color: active
                                        ? cs.primary.withValues(alpha: 0.7)
                                        : cs.onSurfaceVariant,
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),

                // Main tuning display area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Note name
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            noteName,
                            key: ValueKey('${_hasSignal}_${_selectedString}'),
                            style: TextStyle(
                              color: _hasSignal
                                  ? deviation < 0.1
                                      ? Colors.greenAccent
                                      : cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
                              fontSize: 64,
                              fontWeight: FontWeight.w200,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),
                        Text(
                          '${targetString.freq.toStringAsFixed(1)} Hz',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Meter display
                        SizedBox(
                          width: 260,
                          height: 100,
                          child: CustomPaint(
                            painter: _TunerMeterPainter(
                              needlePos: needlePos,
                              active: _hasSignal && _listening,
                              deviation: deviation,
                              primaryColor: deviation < 0.1
                                  ? Colors.greenAccent
                                  : cs.primary,
                              mutedColor: cs.onSurfaceVariant,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Status text
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_hasSignal && _listening) ...[
                                Icon(
                                  _centsOff.abs() < 3
                                      ? Icons.check_circle_outline
                                      : _centsOff > 0
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                  color: statusColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (_listening && _hasSignal)
                                Text(
                                  '${_centsOff.toStringAsFixed(1)}¢ ${_centsOff > 0 ? '♯' : '♭'}',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              if (!_hasSignal || !_listening)
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Frequency readout
                        if (_hasSignal)
                          Text(
                            '${_detectedFreq.toStringAsFixed(2)} Hz detected',
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Start/Stop button
                GestureDetector(
                  onTap: _listening ? _stopListening : _startListening,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _listening
                            ? [
                                cs.error.withValues(alpha: 0.2),
                                cs.error.withValues(alpha: 0.05),
                              ]
                            : [
                                cs.primary.withValues(alpha: 0.2),
                                cs.primary.withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _listening
                            ? cs.error.withValues(alpha: 0.3)
                            : cs.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _listening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: _listening ? cs.error : cs.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _listening ? 'STOP' : 'START TUNER',
                          style: TextStyle(
                            color: _listening ? cs.error : cs.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _modeBtn(ColorScheme cs, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? cs.primary : cs.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TunerMeterPainter extends CustomPainter {
  final double needlePos;
  final bool active;
  final double deviation;
  final Color primaryColor, mutedColor;

  _TunerMeterPainter({
    required this.needlePos,
    required this.active,
    required this.deviation,
    required this.primaryColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final meterWidth = size.width - 40;
    final meterHeight = 4;
    final left = cx - meterWidth / 2;
    final right = cx + meterWidth / 2;
    final top = cy - meterHeight / 2;
    final bottom = cy + meterHeight / 2;

    final meterRect = Rect.fromLTRB(left, top, right, bottom);

    if (!active) {
      // Dim, inactive track
      final inactivePaint = Paint()
        ..color = mutedColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(meterRect, const Radius.circular(2)),
        inactivePaint,
      );

      // Center dot
      canvas.drawCircle(
        Offset(cx, cy),
        4,
        Paint()..color = mutedColor.withValues(alpha: 0.2),
      );
      return;
    }

    // Background track
    final trackPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(meterRect, const Radius.circular(2)),
      trackPaint,
    );

    // Gradient fill from left to needle
    if (needlePos >= 0) {
      // Sharp side
      final fillRect = Rect.fromLTRB(cx, top, cx + needlePos.abs() * meterWidth / 2, bottom);
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.orangeAccent.withValues(alpha: 0.6),
            primaryColor,
          ],
        ).createShader(Rect.fromLTRB(cx, 0, right, 0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(2)),
        fillPaint,
      );
    } else {
      // Flat side
      final fillRect = Rect.fromLTRB(cx - needlePos.abs() * meterWidth / 2, top, cx, bottom);
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            primaryColor,
            Colors.lightBlueAccent.withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromLTRB(left, 0, cx, 0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(2)),
        fillPaint,
      );
    }

    // Center mark (in-tune zone)
    final centerPaint = Paint()
      ..color = deviation < 0.1 ? Colors.greenAccent : mutedColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 6, centerPaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = -4; i <= 4; i++) {
      if (i == 0) continue;
      final x = cx + i * (meterWidth / 10);
      final tickHeight = i.abs() % 2 == 1 ? 4.0 : 8.0;
      canvas.drawLine(
        Offset(x, cy - tickHeight),
        Offset(x, cy + tickHeight),
        tickPaint,
      );
    }

    // Needle
    final needleX = cx + needlePos * meterWidth / 2;
    final needlePaint = Paint()
      ..color = deviation < 0.1 ? Colors.greenAccent : primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(needleX, cy), 3, needlePaint);

    // Glow on needle
    if (active) {
      final glowPaint = Paint()
        ..color = (deviation < 0.1 ? Colors.greenAccent : primaryColor)
            .withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(needleX, cy), 8, glowPaint);
    }

    // Labels
    final labelStyle = TextStyle(
      color: mutedColor.withValues(alpha: 0.3),
      fontSize: 9,
      fontFamily: 'monospace',
    );

    // Left label (♭)
    final leftPainter = TextPainter(
      text: TextSpan(text: '♭', style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    leftPainter.layout();
    leftPainter.paint(canvas, Offset(left, bottom + 8));

    // Right label (♯)
    final rightPainter = TextPainter(
      text: TextSpan(text: '♯', style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    rightPainter.layout();
    rightPainter.paint(canvas, Offset(right - rightPainter.width, bottom + 8));
  }

  @override
  bool shouldRepaint(covariant _TunerMeterPainter old) =>
      old.needlePos != needlePos || old.active != active || old.deviation != deviation;
}

extension on int {
  int toSigned(int bits) {
    final max = 1 << (bits - 1);
    final mask = (1 << bits) - 1;
    int value = this & mask;
    if (value >= max) value -= (1 << bits);
    return value;
  }
}
