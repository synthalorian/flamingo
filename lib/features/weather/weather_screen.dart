import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

/// Uses Open-Meteo API (free, no API key needed) for weather data.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _weather;
  Position? _position;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _loadCached();
    _fetchWeather();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('weather_cache');
    if (cached != null && mounted) {
      setState(() {
        _weather = jsonDecode(cached) as Map<String, dynamic>;
        _locationName = prefs.getString('weather_location') ?? '';
      });
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get location
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      // Reverse geocode
      final locs = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final locationName = locs.isNotEmpty
          ? '${locs.first.locality ?? locs.first.subAdministrativeArea ?? ''}, ${locs.first.country ?? ''}'
          : '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';

      // Fetch weather from Open-Meteo (free, no key)
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${pos.latitude}'
        '&longitude=${pos.longitude}'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,pressure_msl'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum,wind_speed_10m_max'
        '&timezone=auto'
        '&forecast_days=6',
      );

      final weatherResp = await http.get(weatherUri).timeout(const Duration(seconds: 10));
      if (weatherResp.statusCode != 200) {
        throw Exception('Weather API error: ${weatherResp.statusCode}');
      }
      final weatherData = jsonDecode(weatherResp.body) as Map<String, dynamic>;

      // Fetch air quality
      final aqUri = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality'
        '?latitude=${pos.latitude}'
        '&longitude=${pos.longitude}'
        '&current=european_aqi,pm2_5,pm10',
      );

      Map<String, dynamic>? aqData;
      try {
        final aqResp = await http.get(aqUri).timeout(const Duration(seconds: 5));
        if (aqResp.statusCode == 200) {
          aqData = jsonDecode(aqResp.body) as Map<String, dynamic>;
        }
      } catch (_) {}

      final result = {
        'weather': weatherData,
        'airQuality': aqData,
      };

      // Cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weather_cache', jsonEncode(result));
      await prefs.setString('weather_location', locationName);

      if (mounted) {
        setState(() {
          _position = pos;
          _weather = result;
          _locationName = locationName;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 57) return '🌧️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '🌧️';
    if (code <= 86) return '🌨️';
    return '⛈️';
  }

  String _weatherLabel(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain';
    if (code <= 86) return 'Snow';
    return 'Storm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final weatherData = _weather?['weather'] as Map<String, dynamic>?;
    final current = weatherData?['current'] as Map<String, dynamic>?;
    final daily = weatherData?['daily'] as Map<String, dynamic>?;
    final aqData = _weather?['airQuality'] as Map<String, dynamic>?;
    final aqCurrent = aqData?['current'] as Map<String, dynamic>?;
    final weatherCode = (current?['weather_code'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: current != null ? 3 : 1,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text('WEATHER', style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12, letterSpacing: 4,
                      )),
                      const Spacer(),
                      GestureDetector(
                        onTap: _fetchWeather,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _loading
                              ? SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                                )
                              : Icon(Icons.refresh_rounded, size: 18, color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null && _weather == null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text('Could not load weather', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(_error!, style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11),
                              textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _fetchWeather,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text('RETRY', style: TextStyle(
                                  color: cs.primary, fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 12,
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (current != null) ...[
                  // Current weather
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Column(
                      children: [
                        // Location
                        Text(_locationName, style: TextStyle(
                          color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w500,
                        )),
                        const SizedBox(height: 4),

                        // Temperature
                        Text(
                          '${(current['temperature_2m'] as num).round()}°',
                          style: TextStyle(
                            color: cs.primary, fontSize: 72, fontWeight: FontWeight.w200,
                            fontFamily: 'monospace',
                          ),
                        ),

                        // Condition emoji + label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_weatherEmoji(weatherCode), style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(_weatherLabel(weatherCode), style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 16,
                            )),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Details grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _detailItem(cs, '${(current['apparent_temperature'] as num).round()}°', 'Feels like'),
                            _detailItem(cs, '${current['relative_humidity_2m']}%', 'Humidity'),
                            _detailItem(cs, '${(current['wind_speed_10m'] as num).round()} km/h', 'Wind'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _detailItem(cs, '${(current['pressure_msl'] as num).round()} hPa', 'Pressure'),
                            _detailItem(cs, aqCurrent != null ? '${aqCurrent['european_aqi']}' : '--', 'AQI',
                              color: aqCurrent != null
                                  ? _aqiColor((aqCurrent['european_aqi'] as num?)?.toInt() ?? 0)
                                  : null),
                            _detailItem(cs, aqCurrent != null
                                ? '${(aqCurrent['pm2_5'] as num?)?.toStringAsFixed(0) ?? '--'}'
                                : '--', 'PM2.5'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5-day forecast
                  if (daily != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text('FORECAST', style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 11, letterSpacing: 3,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          itemCount: ((daily['time'] as List?)?.length ?? 0).clamp(0, 6),
                          itemBuilder: (ctx, i) {
                            final times = daily['time'] as List?;
                            final maxTemps = daily['temperature_2m_max'] as List?;
                            final minTemps = daily['temperature_2m_min'] as List?;
                            final codes = daily['weather_code'] as List?;
                            final precip = daily['precipitation_sum'] as List?;
                            final winds = daily['wind_speed_10m_max'] as List?;

                            if (times == null || i >= times.length) return const SizedBox();

                            final date = DateTime.tryParse(times[i] as String? ?? '');
                            final dayName = date != null
                                ? (i == 0 ? 'Today' : DateFormat('EEE').format(date))
                                : '--';
                            final code = (codes?[i] as num?)?.toInt() ?? 0;
                            final maxT = (maxTemps?[i] as num?)?.round() ?? 0;
                            final minT = (minTemps?[i] as num?)?.round() ?? 0;
                            final precipV = (precip?[i] as num?) ?? 0;
                            final windV = (winds?[i] as num?)?.round() ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      child: Text(dayName, style: TextStyle(
                                        color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600,
                                      )),
                                    ),
                                    Text(_weatherEmoji(code), style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_weatherLabel(code), style: TextStyle(
                                        color: cs.onSurfaceVariant, fontSize: 11,
                                      )),
                                    ),
                                    Text('$maxT°', style: TextStyle(
                                      color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600,
                                    )),
                                    const SizedBox(width: 4),
                                    Text('/ $minT°', style: TextStyle(
                                      color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12,
                                    )),
                                    const SizedBox(width: 12),
                                    if (precipV > 0)
                                      Row(
                                        children: [
                                          Icon(Icons.water_drop, size: 12, color: cs.primary.withValues(alpha: 0.6)),
                                          Text('${precipV.toStringAsFixed(0)}mm', style: TextStyle(
                                            color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10,
                                          )),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],

                if (_loading && _weather == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(ColorScheme cs, String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          color: color ?? cs.primary, fontSize: 18, fontWeight: FontWeight.w300, fontFamily: 'monospace',
        )),
        Text(label, style: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1,
        )),
      ],
    );
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 20) return Colors.greenAccent;
    if (aqi <= 40) return Colors.lightGreenAccent;
    if (aqi <= 60) return Colors.yellowAccent;
    if (aqi <= 80) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
