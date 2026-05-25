import 'dart:async';

import 'package:flutter/services.dart';

/// Thin MethodChannel bridge to battery temperature API.
/// Android returns temperature in **tenths** of a degree (e.g. 325 = 32.5°C).
/// iOS / dev builds always return null.
class BatteryChannel {
  static const _ch = MethodChannel('battery_thermometer/temp');

  /// Returns battery temperature in °C, or `null` if the platform
  /// plugin is missing (iOS, dev/CI builds).
  static Future<double?> getTemperatureC() async {
    try {
      final int? raw = await _ch.invokeMethod<int>('getTemp');
      if (raw == null) return null;
      return raw.toDouble() / 10.0; // tenths °C → °C
    } on PlatformException {
      return null; // channel missing → sink gracefully
    }
  }
}
