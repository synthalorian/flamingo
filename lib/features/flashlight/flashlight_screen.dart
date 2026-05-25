import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  bool _isOn = false;
  bool _hasFlashlight = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
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
      } else {
        await TorchLight.enableTorch();
        await Vibration.vibrate(duration: 50);
      }
      if (mounted) setState(() => _isOn = !_isOn);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Torch error: $e'),
          backgroundColor: FlamingoColors.primaryDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Status
              Icon(
                _isOn ? Icons.flash_on : Icons.flash_off,
                size: 80,
                color: _isOn ? FlamingoColors.glowPink : FlamingoColors.muted,
              ),
              const SizedBox(height: 16),
              Text(
                _isOn ? 'ON' : 'OFF',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _isOn ? FlamingoColors.glowPink : FlamingoColors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // Toggle button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isOn
                        ? [FlamingoColors.glowPink, FlamingoColors.primaryDark]
                        : [FlamingoColors.surface, FlamingoColors.card],
                  ),
                  boxShadow: _isOn
                      ? [
                          BoxShadow(
                            color: FlamingoColors.glowPink.withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(120),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(120),
                    onTap: _hasFlashlight && !_permissionDenied ? _toggleTorch : null,
                    child: Container(
                      width: 160,
                      height: 160,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.power_settings_new,
                        size: 64,
                        color: _isOn
                            ? FlamingoColors.scaffoldBg
                            : FlamingoColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Info text
              if (!_hasFlashlight)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'No flashlight hardware detected on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FlamingoColors.muted),
                  ),
                ),
              if (_permissionDenied)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Camera permission was denied. Enable it in Settings to use the flashlight.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FlamingoColors.muted),
                  ),
                ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isOn) TorchLight.disableTorch();
    super.dispose();
  }
}
