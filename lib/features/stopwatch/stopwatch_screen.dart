import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  bool _running = false;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<Duration> _laps = [];

  void _tick(Timer timer) {
    setState(() {});
  }

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 10), _tick);
    });
  }

  void _stop() {
    if (!_running) return;
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _stopwatch = Stopwatch();
      _laps.clear();
    });
  }

  void _lap() {
    if (!_running) return;
    setState(() => _laps.insert(0, _stopwatch.elapsed));
  }

  String _formatDuration(Duration d) {
    final ms = d.inMilliseconds;
    final min = (ms ~/ 60000).toString().padLeft(2, '0');
    final sec = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final centi = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$min:$sec.$centi';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;

    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Time display
              Text(
                _formatDuration(elapsed),
                style: TextStyle(
                  color: FlamingoColors.text,
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              // Status indicator
              if (_running)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: FlamingoColors.glowPink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('RUNNING', style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 3)),
                  ],
                )
              else if (elapsed.inMilliseconds > 0)
                Text('PAUSED', style: TextStyle(color: FlamingoColors.muted, fontSize: 12, letterSpacing: 3)),
              const SizedBox(height: 32),

              // Primary controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionBtn(
                    label: _running ? 'STOP' : 'START',
                    color: _running ? FlamingoColors.accent : FlamingoColors.primary,
                    onTap: _running ? _stop : _start,
                  ),
                  const SizedBox(width: 16),
                  _actionBtn(
                    label: 'LAP',
                    color: FlamingoColors.neonBlue,
                    onTap: _running ? _lap : null,
                  ),
                  const SizedBox(width: 16),
                  _actionBtn(
                    label: 'RESET',
                    color: FlamingoColors.muted,
                    onTap: _reset,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Divider(color: FlamingoColors.cardBorder, thickness: 1),
              const SizedBox(height: 8),

              // Laps
              Expanded(
                child: _laps.isEmpty
                    ? Center(
                        child: Text(
                          'No laps yet\nTap LAP while running',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FlamingoColors.muted, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _laps.length,
                        itemBuilder: (context, i) {
                          final totalUpToLap = i < _laps.length - 1
                              ? _laps.sublist(i + 1).fold<Duration>(
                                  Duration.zero, (sum, d) => sum + d)
                              : Duration.zero;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: FlamingoColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lap ${_laps.length - i}',
                                  style: TextStyle(color: FlamingoColors.muted, fontSize: 13),
                                ),
                                Text(
                                  _formatDuration(_laps[i]),
                                  style: TextStyle(color: FlamingoColors.neonBlue, fontSize: 15, fontFamily: 'monospace'),
                                ),
                                Text(
                                  '+${_formatDuration(totalUpToLap)}',
                                  style: TextStyle(color: FlamingoColors.accent, fontSize: 13, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({required String label, required Color color, VoidCallback? onTap}) {
    return Material(
      color: color.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
