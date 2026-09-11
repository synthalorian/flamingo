import 'package:flamingo/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool registry: one merged Thermometer, no fakes', () {
    final ids = AppConstants.tools.map((t) => t.id).toList();

    // simulated ambient tool is gone (Pixel has no ambient sensor)
    expect(ids.contains('thermometer'), isFalse);
    expect(ids.contains('guitarTuner'), isFalse);

    // battery-sensor tool carries the Thermometer name
    final thermo = AppConstants.tools.firstWhere(
      (t) => t.id == 'batteryThermometer',
    );
    expect(thermo.title, 'Thermometer');
  });
}
