import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/utils/audio_generator.dart';

enum AmbientSound { whiteNoise, rain, ocean, forest }

class AmbientSoundsScreen extends StatefulWidget {
  const AmbientSoundsScreen({super.key});

  @override
  State<AmbientSoundsScreen> createState() => _AmbientSoundsScreenState();
}

class _AmbientSoundsScreenState extends State<AmbientSoundsScreen> {
  final _player = AudioPlayer();
  AmbientSound? _activeSound;
  double _volume = 0.5;
  bool _playing = false;

  final _soundInfo = {
    AmbientSound.whiteNoise: ('White Noise', Icons.graphic_eq, const Color(0xFF90CAF9)),
    AmbientSound.rain: ('Rain', Icons.water_drop, const Color(0xFF64B5F6)),
    AmbientSound.ocean: ('Ocean', Icons.waves, const Color(0xFF4DD0E1)),
    AmbientSound.forest: ('Forest', Icons.forest, const Color(0xFF81C784)),
  };

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(AmbientSound sound) async {
    await _player.stop();

    final bytes = switch (sound) {
      AmbientSound.whiteNoise => AudioGenerator.generateWhiteNoise(30),
      AmbientSound.rain => AudioGenerator.generateRain(30),
      AmbientSound.ocean => AudioGenerator.generateOcean(30),
      AmbientSound.forest => AudioGenerator.generateForest(30),
    };

    await _player.setSource(BytesSource(bytes));
    _player.setVolume(_volume);
    _player.setReleaseMode(ReleaseMode.loop);
    await _player.resume();

    setState(() {
      _activeSound = sound;
      _playing = true;
    });
  }

  void _stop() {
    _player.stop();
    setState(() {
      _activeSound = null;
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _playing ? 5 : 2,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'AMBIENT SOUNDS',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Relaxing background audio',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 32),

                // Sound selection grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: _soundInfo.entries.map((entry) {
                      final sound = entry.key;
                      final info = entry.value;
                      final active = _activeSound == sound && _playing;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => active ? _stop() : _play(sound),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? info.$3.withValues(alpha: 0.15)
                                  : cs.surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: active
                                    ? info.$3.withValues(alpha: 0.5)
                                    : cs.outlineVariant.withValues(alpha: 0.1),
                                width: active ? 1.5 : 1,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: info.$3.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? info.$3.withValues(alpha: 0.2)
                                        : cs.onSurfaceVariant
                                            .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    info.$2,
                                    color: active ? info.$3 : cs.onSurfaceVariant,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        info.$1,
                                        style: TextStyle(
                                          color: active
                                              ? info.$3
                                              : cs.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        active ? 'Playing' : 'Tap to play',
                                        style: TextStyle(
                                          color: active
                                              ? info.$3.withValues(alpha: 0.7)
                                              : cs.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (active)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: info.$3,
                                      boxShadow: [
                                        BoxShadow(
                                          color: info.$3.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
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

                const SizedBox(height: 24),

                // Volume slider
                if (_playing) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.volume_down_rounded,
                              color: cs.onSurfaceVariant,
                              size: 18,
                            ),
                            Text(
                              '${(_volume * 100).round()}%',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: cs.primary,
                            inactiveTrackColor: cs.surfaceContainerHigh,
                            thumbColor: cs.primary,
                            overlayColor: cs.primary.withValues(alpha: 0.12),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(
                            value: _volume,
                            onChanged: (v) {
                              setState(() => _volume = v);
                              _player.setVolume(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stop button
                  GestureDetector(
                    onTap: _stop,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.error.withValues(alpha: 0.2),
                            cs.error.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stop_rounded,
                            color: cs.error,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'STOP',
                            style: TextStyle(
                              color: cs.error,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!_playing)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      'Choose a sound to play • loops continuously',
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 11,
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
