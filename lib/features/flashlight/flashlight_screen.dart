import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

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

  late AnimationController _pulseCtrl;
  late AnimationController _breatheCtrl;
  late Animation<double> _breatheAnim;

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

    try {
      if (_isOn) {
        await TorchLight.disableTorch();
        await Vibration.vibrate(duration: 30);
        _breatheCtrl.stop();
        setState(() => _isOn = false);
      } else {
        await TorchLight.enableTorch();
        await Vibration.vibrate(duration: 50);
        _breatheCtrl.repeat(reverse: true);
        _pulseCtrl.forward(from: 0);
        setState(() => _isOn = true);
      }
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Torch error: $e'),
          backgroundColor: cs.surfaceContainerHigh,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _breatheCtrl.dispose();
    if (_isOn) TorchLight.disableTorch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: _isOn ? 8 : 3,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

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
                            _isOn ? Icons.flash_on : Icons.flash_off,
                            size: 80,
                            color: _isOn ? cs.primary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isOn ? 'ON' : 'OFF',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: _isOn ? cs.primary : cs.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: _isOn
                                  ? [
                                      Shadow(
                                        color: cs.primary.withValues(
                                          alpha: 0.5,
                                        ),
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

                const SizedBox(height: 48),

                // Main toggle button with concentric pulse rings
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseCtrl, _breatheAnim]),
                  builder: (context, child) {
                    final pulse = _pulseCtrl.value;
                    final breathe = _breatheAnim.value;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring 1
                        if (_isOn)
                          _pulseRing(cs.primary, 200 + 80 * pulse, 0.12),
                        // Outer pulse ring 2
                        if (_isOn)
                          _pulseRing(
                            cs.secondary,
                            180 + 60 * ((pulse + 0.5) % 1.0),
                            0.08,
                          ),

                        // Main button with breathe glow
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isOn
                                  ? [
                                      cs.primary,
                                      cs.primary.withValues(alpha: 0.5),
                                    ]
                                  : [
                                      cs.surfaceContainerHigh,
                                      cs.surfaceContainerLow,
                                    ],
                            ),
                            boxShadow: _isOn
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withValues(
                                        alpha: 0.3 + 0.3 * breathe,
                                      ),
                                      blurRadius: 40 + 20 * breathe,
                                      spreadRadius: 8 + 4 * breathe,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(120),
                              onTap: _hasFlashlight && !_permissionDenied
                                  ? _toggleTorch
                                  : null,
                              child: Container(
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.power_settings_new,
                                  size: 64,
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

                // Info text
                if (!_hasFlashlight)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'No flashlight hardware detected on this device.',
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
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TORCH ACTIVE',
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

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pulseRing(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: opacity), width: 2),
      ),
    );
  }
}
