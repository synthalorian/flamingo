import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

enum FlashMode { on, strobe, sos }

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen>
    with SingleTickerProviderStateMixin {
  bool _isOn = false;
  bool _hasFlashlight = true;
  bool _permissionDenied = false;
  FlashMode _mode = FlashMode.on;
  double _strobeFreq = 8.0; // Hz

  Timer? _strobeTimer;
  bool _strobeState = false;

  late AnimationController _pulseCtrl;
  late AnimationController _breatheCtrl;
  late Animation<double> _breatheAnim;

  // SOS pattern: . . . - - - . . .  (dot=200ms, dash=600ms, gap=200ms)
  static const _sosPattern = [
    Duration(milliseconds: 200), // dot
    Duration(milliseconds: 200),
    Duration(milliseconds: 200),
    Duration(milliseconds: 600), // dash
    Duration(milliseconds: 600),
    Duration(milliseconds: 600),
    Duration(milliseconds: 200), // dot
    Duration(milliseconds: 200),
    Duration(milliseconds: 200),
  ];
  int _sosIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _breatheAnim = CurvedAnimation(
      parent: _breatheCtrl,
      curve: Curves.easeInOut,
    );
    _checkFlashlight();
    _requestPermission();
  }

  Future<void> _checkFlashlight() async {
    final has = await TorchLight.isTorchAvailable();
    if (!mounted) return;
    setState(() => _hasFlashlight = has);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _permissionDenied = status.isPermanentlyDenied);
  }

  Future<void> _setTorch(bool on) async {
    try {
      if (on) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Torch error: $e')),
      );
    }
  }

  Future<void> _toggleTorch() async {
    if (!_hasFlashlight) return;

    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        setState(() => _permissionDenied = true);
        return;
      }
    }

    if (_isOn) {
      await _stopAll();
    } else {
      setState(() => _isOn = true);
      await Vibration.vibrate(duration: 50);
      _pulseCtrl.forward(from: 0);
      _breatheCtrl.repeat(reverse: true);
      _startMode();
    }
  }

  Future<void> _stopAll() async {
    _strobeTimer?.cancel();
    _strobeTimer = null;
    _breatheCtrl.stop();
    await _setTorch(false);
    await Vibration.vibrate(duration: 30);
    if (mounted) setState(() => _isOn = false);
  }

  void _startMode() {
    switch (_mode) {
      case FlashMode.on:
        _setTorch(true);
        break;
      case FlashMode.strobe:
        _startStrobe();
        break;
      case FlashMode.sos:
        _startSos();
        break;
    }
  }

  void _startStrobe() {
    final interval = Duration(milliseconds: (1000 / _strobeFreq).round() ~/ 2);
    _strobeState = true;
    _setTorch(true);
    _strobeTimer = Timer.periodic(interval, (_) async {
      _strobeState = !_strobeState;
      await _setTorch(_strobeState);
    });
  }

  void _startSos() {
    _sosIndex = 0;
    _runSosCycle();
  }

  void _runSosCycle() {
    if (!_isOn || _mode != FlashMode.sos) return;
    if (_sosIndex >= _sosPattern.length) {
      _sosIndex = 0;
      // Gap between SOS cycles
      Future.delayed(const Duration(milliseconds: 400), _runSosCycle);
      return;
    }
    final duration = _sosPattern[_sosIndex];
    final shouldBeOn = _sosIndex.isEven;
    _setTorch(shouldBeOn);
    _sosIndex++;
    Future.delayed(duration, _runSosCycle);
  }

  void _setMode(FlashMode mode) {
    if (mode == _mode && _isOn) return;
    setState(() => _mode = mode);
    if (_isOn) {
      _strobeTimer?.cancel();
      _startMode();
    }
  }

  @override
  void dispose() {
    _strobeTimer?.cancel();
    _pulseCtrl.dispose();
    _breatheCtrl.dispose();
    TorchLight.disableTorch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String modeLabel;
    IconData modeIcon;
    switch (_mode) {
      case FlashMode.on:
        modeLabel = 'ON';
        modeIcon = Icons.flash_on;
      case FlashMode.strobe:
        modeLabel = 'STROBE';
        modeIcon = Icons.flash_on_rounded;
      case FlashMode.sos:
        modeLabel = 'SOS';
        modeIcon = Icons.sos;
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _isOn ? 8 : 3,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'FLASHLIGHT',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),

                const Spacer(flex: 1),

                // Status icon with breathe animation
                AnimatedBuilder(
                  animation: _breatheAnim,
                  builder: (context, child) {
                    final breatheScale = _isOn
                        ? 0.9 + 0.1 * _breatheAnim.value
                        : 1.0;
                    return Transform.scale(
                      scale: breatheScale,
                      child: Column(
                        children: [
                          Icon(
                            modeIcon,
                            size: 72,
                            color: _isOn ? cs.primary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            modeLabel,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: _isOn ? cs.primary : cs.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: _isOn
                                  ? [
                                      Shadow(
                                        color: cs.primary.withValues(alpha: 0.5),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Main toggle button
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseCtrl, _breatheAnim]),
                  builder: (context, child) {
                    final pulse = _pulseCtrl.value;
                    final breathe = _breatheAnim.value;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse rings
                        if (_isOn) ...[
                          _pulseRing(cs.primary, 200 + 80 * pulse, 0.12),
                          _pulseRing(
                            cs.secondary,
                            180 + 60 * ((pulse + 0.5) % 1.0),
                            0.08,
                          ),
                        ],
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isOn
                                  ? [cs.primary, cs.primary.withValues(alpha: 0.5)]
                                  : [cs.surfaceContainerHigh, cs.surfaceContainerLow],
                            ),
                            boxShadow: _isOn
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.3 + 0.3 * breathe),
                                      blurRadius: 40 + 20 * breathe,
                                      spreadRadius: 8 + 4 * breathe,
                                    ),
                                  ]
                                : [
                                    BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(120),
                              onTap: _hasFlashlight && !_permissionDenied
                                  ? _toggleTorch
                                  : null,
                              child: Center(
                                child: Icon(
                                  Icons.power_settings_new,
                                  size: 56,
                                  color: _isOn ? Colors.black87 : cs.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Mode selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      _modeChip(cs, 'On', FlashMode.on, Icons.flash_on),
                      const SizedBox(width: 8),
                      _modeChip(cs, 'Strobe', FlashMode.strobe, Icons.flash_on_rounded),
                      const SizedBox(width: 8),
                      _modeChip(cs, 'SOS', FlashMode.sos, Icons.sos),
                    ],
                  ),
                ),

                // Strobe frequency slider (only visible in strobe mode)
                if (_mode == FlashMode.strobe)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_strobeFreq.toStringAsFixed(0)} Hz',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Speed',
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
                          ),
                          child: Slider(
                            value: _strobeFreq,
                            min: 2,
                            max: 20,
                            divisions: 18,
                            label: '${_strobeFreq.round()} Hz',
                            onChanged: (v) {
                              setState(() => _strobeFreq = v);
                              if (_isOn && _mode == FlashMode.strobe) {
                                _strobeTimer?.cancel();
                                _startStrobe();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Status info
                if (!_hasFlashlight)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'No flashlight hardware detected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                if (_permissionDenied)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Camera permission denied. Enable in Settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                if (_isOn)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                            boxShadow: [
                              BoxShadow(color: cs.primary.withValues(alpha: 0.6), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _mode == FlashMode.sos
                              ? 'SOS ACTIVE'
                              : _mode == FlashMode.strobe
                                  ? 'STROBE ACTIVE'
                                  : 'TORCH ACTIVE',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 11,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(ColorScheme cs, String label, FlashMode mode, IconData icon) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? cs.primary.withValues(alpha: 0.12)
                : cs.surfaceContainerHigh.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? cs.primary.withValues(alpha: 0.4)
                  : cs.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: active ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pulseRing(Color color, double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: opacity), width: 2),
      ),
    );
  }
}
