import 'dart:async';

import 'package:flutter/services.dart';

/// Thin MethodChannel bridge to `BatteryTemperature.flutter`.
/// Android side registers the channel under the name below; iOS always returns -1.
class BatteryChannel {
  static const _ch = MethodChannel('battery_thermometer/temp');

  /// Returns the battery temperature in °C, or `null` if the platform
  /// plugin is missing (common on dev/CI builds).
  static Future<double?> getTemperatureC() async {
    try {
      final int? raw = await _ch.invokeMethod<int>('getTemp');
      return raw?.toDouble(); // hundredths °C sent from Android
    } on PlatformException {
      return null; // channel missing → sink gracefully
    }
  }
}
