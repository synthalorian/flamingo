import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class MagnifierScreen extends StatefulWidget {
  const MagnifierScreen({super.key});

  @override
  State<MagnifierScreen> createState() => _MagnifierScreenState();
}

class _MagnifierScreenState extends State<MagnifierScreen> {
  CameraController? _ctrl;
  List<CameraDescription> _cameras = [];
  bool _loading = true;
  String? _error;
  bool _torchOn = false;
  double _zoom = 1.0;
  int _index = 0;
  static const _levels = [1.0, 2.0, 4.0, 8.0];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Permissions: camera + flash
    final camOk = await Permission.camera.request();
    if (!camOk.isGranted) {
      setState(() => _error = 'Camera permission denied');
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No camera found');
        return;
      }
      // Prefer back camera
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _ctrl = CameraController(
        back,
        ResolutionPreset.max,
        enableAudio: false,
      );
      await _ctrl!.initialize();
      if (!mounted) return;
      setState(() => _loading = false);
    } on CameraException catch (e) {
      setState(() => _error = 'Camera error: ${e.description}');
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    if (_ctrl == null) return;
    final on = !_torchOn;
    try {
      await _ctrl!.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } on CameraException catch (_) {}
    setState(() => _torchOn = on);
  }

  void _handlePinch(ScaleUpdateDetails details) {
    final newZoom = (_zoom * details.scale).clamp(1.0, 8.0);
    setState(() => _zoom = newZoom);
    _ctrl?.setZoomLevel(_zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: FlamingoColors.scaffoldBg,
        elevation: 0,
        title: Text('MAGNIFIER',
            style: TextStyle(
                color: FlamingoColors.muted, fontSize: 12, letterSpacing: 4)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              Icons.highlight_rounded,
              color: _torchOn ? FlamingoColors.accent : FlamingoColors.muted,
            ),
          ),
        ],
      ),
      body: CrtBackground(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: FlamingoColors.primary,
                  strokeWidth: 2,
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FlamingoColors.muted)),
                    ),
                  )
                : Stack(
                    children: [
                      // Pinch-to-zoom gesture detector over camera feed
                      GestureDetector(
                        onScaleUpdate: _handlePinch,
                        onScaleEnd: (_) => setState(() {}),
                        child: CameraPreview(_ctrl!),
                      ),
                      // Zoom label percentage
                      Positioned(
                        top: 8,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: FlamingoColors.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(_zoom * 100).toInt()}%',
                            style: TextStyle(
                              color: FlamingoColors.primary,
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Pinch hint — only show when not pinching
                      if (_zoom == 1.0)
                        Positioned(
                          bottom: 100,
                          right: 16,
                          child: Text('Pinch to zoom',
                              style: TextStyle(
                                  color: FlamingoColors.muted
                                      .withValues(alpha: 0.6),
                                  fontSize: 11)),
                        ),
                    ],
                  ),
      ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: FlamingoColors.surface.withValues(alpha: 0.9),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _levels.length,
                      (i) => MagChip(
                        label: '${(_levels[i] * 100).toInt()}%',
                        active: i == _index,
                        onTap: () {
                          setState(() {
                            _index = i;
                            _zoom = _levels[i];
                          });
                          _ctrl?.setZoomLevel(_zoom);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Pinch or tap to change magnification',
                      style: TextStyle(
                          color: FlamingoColors.muted.withValues(alpha: 0.6),
                          fontSize: 11)),
                ],
              ),
            ),
    );
  }
}

class MagChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const MagChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: active
            ? FlamingoColors.primary.withValues(alpha: 0.25)
            : FlamingoColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: active ? FlamingoColors.primary : FlamingoColors.muted,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
