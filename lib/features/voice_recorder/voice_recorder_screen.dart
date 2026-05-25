import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

class _Recording {
  final String path;
  final String name;
  final DateTime date;
  final Duration duration;

  _Recording({
    required this.path,
    required this.name,
    required this.date,
    required this.duration,
  });

  String get sizeDisplay {
    try {
      final file = File(path);
      final kb = file.lengthSync() / 1024;
      if (kb > 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
      return '${kb.toStringAsFixed(0)} KB';
    } catch (_) {
      return '--';
    }
  }

  String get durationDisplay {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  StreamSubscription<Uint8List>? _recordSub;

  bool _recording = false;
  bool _playing = false;
  _Recording? _currentRecording;
  List<_Recording> _recordings = [];

  int _recordElapsed = 0;
  Timer? _recordTimer;

  /// Accumulated raw PCM16 bytes during recording (since startStream doesn't write a file).
  final _pcmBuffer = <int>[];

  // Waveform buffer
  final _waveform = <double>[];

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _recordTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final dir = await _recordingsDir();
    if (!dir.existsSync()) return;
    final files = dir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.wav'))
      .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    _recordings = files.map((f) {
      final name = f.path.split('/').last.replaceAll('.wav', '');
      final parts = name.split('_');
      final durSec = parts.length > 1 ? int.tryParse(parts.last) ?? 0 : 0;
      return _Recording(
        path: f.path,
        name: name.substring(0, name.length - parts.last.length - 1),
        date: f.lastModifiedSync(),
        duration: Duration(seconds: durSec),
      );
    }).toList();
    if (mounted) setState(() {});
  }

  Future<Directory> _recordingsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/recordings');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required'), behavior: SnackBarBehavior.floating),
        );
      }
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

      _pcmBuffer.clear();
      _waveform.clear();
      _recordElapsed = 0;
      _recordSub = stream.listen((data) => _onAudioData(data));

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordElapsed++);
      });

      setState(() => _recording = true);
    } catch (e) {
      debugPrint('Record error: $e');
    }
  }

  void _onAudioData(Uint8List data) {
    // Accumulate the raw PCM16 bytes for file saving
    _pcmBuffer.addAll(data);

    // Extract level for waveform
    double maxLevel = 0;
    for (int i = 1; i < data.length; i += 2) {
      final sample = (data[i - 1] | (data[i] << 8)).toSigned(16);
      final level = sample.abs() / 32768.0;
      if (level > maxLevel) maxLevel = level;
    }
    _waveform.add(maxLevel);
    while (_waveform.length > _maxWaveform) {
      _waveform.removeAt(0);
    }
    if (mounted) setState(() {});
  }

  /// Write accumulated PCM16 data to a WAV file.
  Future<String> _savePcmToWav() async {
    final dir = await _recordingsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/recording_$timestamp.wav';

    final numSamples = _pcmBuffer.length ~/ 2;
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;
    final sampleRate = 44100;

    final wav = ByteData(44 + dataSize);
    int offset = 0;

    void writeU8(int v) { wav.setUint8(offset++, v); }
    void writeU16(int v) { wav.setUint16(offset, v, Endian.little); offset += 2; }
    void writeU32(int v) { wav.setUint32(offset, v, Endian.little); offset += 4; }

    // RIFF header
    writeU8(0x52); writeU8(0x49); writeU8(0x46); writeU8(0x46); // "RIFF"
    writeU32(fileSize);
    writeU8(0x57); writeU8(0x41); writeU8(0x56); writeU8(0x45); // "WAVE"

    // fmt sub-chunk
    writeU8(0x66); writeU8(0x6D); writeU8(0x74); writeU8(0x20); // "fmt "
    writeU32(16);          // chunk size
    writeU16(1);           // PCM
    writeU16(1);           // mono
    writeU32(sampleRate);  // sample rate
    writeU32(sampleRate * 2); // byte rate
    writeU16(2);           // block align
    writeU16(16);          // bits per sample

    // data sub-chunk
    writeU8(0x64); writeU8(0x61); writeU8(0x74); writeU8(0x61); // "data"
    writeU32(dataSize);

    // Write PCM samples
    for (int i = 0; i < _pcmBuffer.length; i++) {
      wav.setUint8(offset + i, _pcmBuffer[i]);
    }

    await File(path).writeAsBytes(wav.buffer.asUint8List());
    return path;
  }

  Future<void> _stopRecording() async {
    _recordSub?.cancel();
    _recordSub = null;
    _recordTimer?.cancel();
    _recordTimer = null;

    try {
      await _recorder.stop();

      if (_pcmBuffer.isNotEmpty) {
        final path = await _savePcmToWav();
        final rec = _Recording(
          path: path,
          name: 'Recording ${DateTime.now().toString().substring(0, 16)}',
          date: DateTime.now(),
          duration: Duration(seconds: _recordElapsed),
        );
        _recordings.insert(0, rec);
        _currentRecording = rec;
      }
    } catch (e) {
      debugPrint('Stop error: $e');
    }

    if (mounted) setState(() => _recording = false);
  }

  Future<void> _playRecording(_Recording rec) async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    try {
      await _player.stop();
      await _player.setSource(DeviceFileSource(rec.path));
      await _player.resume();
      setState(() => _playing = true);
    } catch (e) {
      debugPrint('Play error: $e');
    }
  }

  Future<void> _deleteRecording(_Recording rec) async {
    try {
      File(rec.path).deleteSync();
      _recordings.remove(rec);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final elapsedMin = (_recordElapsed ~/ 60).toString().padLeft(2, '0');
    final elapsedSec = (_recordElapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _recording ? 5 : 2,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text('VOICE RECORDER', style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 12, letterSpacing: 4,
                )),

                const SizedBox(height: 24),

                // Waveform / recording status
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        levels: _waveform,
                        active: _recording,
                        primaryColor: _recording ? Colors.redAccent : cs.primary,
                        mutedColor: cs.onSurfaceVariant,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Timer
                if (_recording)
                  Text('$elapsedMin:$elapsedSec', style: TextStyle(
                    color: Colors.redAccent, fontSize: 36, fontWeight: FontWeight.w200,
                    fontFamily: 'monospace',
                  )),

                const SizedBox(height: 24),

                // Record / Stop button
                GestureDetector(
                  onTap: _recording ? _stopRecording : _startRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _recording ? Colors.redAccent : cs.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_recording ? Colors.redAccent : cs.primary).withValues(alpha: 0.3),
                          blurRadius: 20, spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _recording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.black87, size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _recording ? 'Tap to stop' : 'Tap to record',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),

                const SizedBox(height: 24),

                // Recordings list header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('RECORDINGS', style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11, letterSpacing: 3,
                      )),
                      const SizedBox(width: 8),
                      Text('${_recordings.length}', style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11,
                      )),
                      const Spacer(),
                      if (_recordings.isNotEmpty)
                        GestureDetector(
                          onTap: _loadRecordings,
                          child: Icon(Icons.refresh_rounded, size: 16, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Recordings list
                Expanded(
                  child: _recordings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_none, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                              const SizedBox(height: 8),
                              Text('No recordings yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _recordings.length,
                          itemBuilder: (ctx, i) {
                            final rec = _recordings[i];
                            final isCurrentPlaying = _playing;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    // Play button
                                    GestureDetector(
                                      onTap: () => _playRecording(rec),
                                      child: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCurrentPlaying
                                              ? cs.primary.withValues(alpha: 0.2)
                                              : cs.surfaceContainerHigh,
                                        ),
                                        child: Icon(
                                          isCurrentPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                          color: isCurrentPlaying ? cs.primary : cs.onSurfaceVariant, size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rec.name.length > 24 ? '${rec.name.substring(0, 24)}...' : rec.name,
                                            style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${rec.durationDisplay} • ${rec.sizeDisplay}',
                                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _deleteRecording(rec),
                                      child: Icon(Icons.delete_outline, size: 18,
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

const _maxWaveform = 80;

class _WaveformPainter extends CustomPainter {
  final List<double> levels;
  final bool active;
  final Color primaryColor, mutedColor;

  _WaveformPainter({
    required this.levels,
    required this.active,
    required this.primaryColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? primaryColor : mutedColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (levels.isEmpty) {
      // Draw flat line
      paint.color = mutedColor.withValues(alpha: 0.2);
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }

    final barWidth = size.width / _maxWaveform;
    for (int i = 0; i < levels.length && i < _maxWaveform; i++) {
      final height = levels[i].clamp(0.0, 1.0) * size.height * 0.8;
      final x = i * barWidth;
      final alpha = active ? (0.4 + 0.6 * levels[i]) : 0.2;
      paint.color = active
          ? primaryColor.withValues(alpha: alpha.clamp(0.0, 1.0))
          : mutedColor.withValues(alpha: 0.15);
      paint.style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTRB(
          x + 1,
          size.height / 2 - height / 2,
          x + barWidth - 2,
          size.height / 2 + height / 2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.levels != levels || old.active != active;
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
