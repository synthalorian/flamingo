import 'dart:math';
import 'dart:typed_data';

/// Generates WAV audio data for ambient sounds programmatically.
/// No external audio assets needed.
class AudioGenerator {
  static const _sampleRate = 44100;

  /// Generate white noise WAV bytes (duration in seconds, looping safe).
  static Uint8List generateWhiteNoise(int durationSec) {
    final numSamples = _sampleRate * durationSec;
    final samples = Int16List(numSamples);
    final random = Random(42);
    for (int i = 0; i < numSamples; i++) {
      samples[i] = ((random.nextDouble() * 2 - 1) * 32767 * 0.25).toInt();
    }
    return _toWav(samples);
  }

  /// Generate rain-like filtered noise.
  static Uint8List generateRain(int durationSec) {
    final numSamples = _sampleRate * durationSec;
    final samples = Int16List(numSamples);
    final random = Random(42);
    double b0 = 0, b1 = 0, b2 = 0;
    for (int i = 0; i < numSamples; i++) {
      final w = random.nextDouble() * 2 - 1;
      b0 = 0.997 * b0 + w * 0.003;
      b1 = 0.999 * b1 + w * 0.001;
      b2 = 0.995 * b2 + w * 0.005;
      final s = (b0 + b1 + b2) / 3;
      samples[i] = (s * 32767 * 0.35).clamp(-32767, 32767).toInt();
    }
    return _toWav(samples);
  }

  /// Generate ocean/wave-like sounds with slow amplitude modulation.
  static Uint8List generateOcean(int durationSec) {
    final numSamples = _sampleRate * durationSec;
    final samples = Int16List(numSamples);
    final random = Random(42);
    double noise = 0;
    for (int i = 0; i < numSamples; i++) {
      final w = random.nextDouble() * 2 - 1;
      noise = 0.999 * noise + w * 0.001;
      final t = i / _sampleRate;
      final amp = 0.4 + 0.4 * (0.5 + 0.5 * sin(t * 2 * pi * 0.12));
      samples[i] = (noise * amp * 32767 * 0.5).clamp(-32767, 32767).toInt();
    }
    return _toWav(samples);
  }

  /// Generate forest ambient with noise and occasional bird-like chirps.
  static Uint8List generateForest(int durationSec) {
    final numSamples = _sampleRate * durationSec;
    final samples = Int16List(numSamples);
    final random = Random(42);
    final chirpRand = Random(123);

    for (int i = 0; i < numSamples; i++) {
      final w = random.nextDouble() * 2 - 1;
      final t = i / _sampleRate;
      double sample = w * 0.04;

      // Occasional chirps
      if (chirpRand.nextDouble() < 0.0004) {
        final freq = 2000 + chirpRand.nextDouble() * 1200;
        final dur = 0.08 + chirpRand.nextDouble() * 0.12;
        if ((t % (2 + chirpRand.nextDouble() * 3)) < dur) {
          final chirpFade = 1 - ((t % dur) / dur);
          sample += sin(2 * pi * freq * t) * 0.12 * chirpFade;
        }
      }

      samples[i] = (sample * 32767).clamp(-32767, 32767).toInt();
    }
    return _toWav(samples);
  }

  static Uint8List _toWav(Int16List samples) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;
    final wav = ByteData(44 + dataSize);
    int offset = 0;

    wav.setUint8(offset++, 0x52); // R
    wav.setUint8(offset++, 0x49); // I
    wav.setUint8(offset++, 0x46); // F
    wav.setUint8(offset++, 0x46); // F
    wav.setUint32(offset, fileSize, Endian.little); offset += 4;
    wav.setUint8(offset++, 0x57); // W
    wav.setUint8(offset++, 0x41); // A
    wav.setUint8(offset++, 0x56); // V
    wav.setUint8(offset++, 0x45); // E
    wav.setUint8(offset++, 0x66); // f
    wav.setUint8(offset++, 0x6D); // m
    wav.setUint8(offset++, 0x74); // t
    wav.setUint8(offset++, 0x20); // (space)
    wav.setUint32(offset, 16, Endian.little); offset += 4;
    wav.setUint16(offset, 1, Endian.little); offset += 2;
    wav.setUint16(offset, 1, Endian.little); offset += 2;
    wav.setUint32(offset, _sampleRate, Endian.little); offset += 4;
    wav.setUint32(offset, _sampleRate * 2, Endian.little); offset += 4;
    wav.setUint16(offset, 2, Endian.little); offset += 2;
    wav.setUint16(offset, 16, Endian.little); offset += 2;
    wav.setUint8(offset++, 0x64); // d
    wav.setUint8(offset++, 0x61); // a
    wav.setUint8(offset++, 0x74); // t
    wav.setUint8(offset++, 0x61); // a
    wav.setUint32(offset, dataSize, Endian.little); offset += 4;

    for (int i = 0; i < numSamples; i++) {
      wav.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }
    return wav.buffer.asUint8List();
  }
}
