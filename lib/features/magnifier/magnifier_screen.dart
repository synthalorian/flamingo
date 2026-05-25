import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _ctrl = CameraController(back, ResolutionPreset.max, enableAudio: false);
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
    _syncIndex();
    _ctrl?.setZoomLevel(_zoom);
  }

  void _syncIndex() {
    // Find nearest level
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _levels.length; i++) {
      final d = (_levels[i] - _zoom).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    _index = best;
  }

  void _setLevel(int i) {
    setState(() {
      _index = i;
      _zoom = _levels[i];
    });
    _ctrl?.setZoomLevel(_zoom);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'MAGNIFIER',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              Icons.highlight_rounded,
              color: _torchOn ? cs.primary : cs.onSurfaceVariant,
            ),
            splashRadius: 20,
          ),
        ],
      ),
      body: CrtBackground(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: cs.primary,
                  strokeWidth: 2,
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  GestureDetector(
                    onScaleUpdate: _handlePinch,
                    onScaleEnd: (_) => setState(() {}),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CameraPreview(_ctrl!),
                    ),
                  ),
                  // Crosshair
                  Center(
                    child: CustomPaint(
                      size: const Size(40, 40),
                      painter: _CrosshairPainter(
                        color: cs.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  // Zoom overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${(_zoom * 100).toInt()}%',
                        style: TextStyle(
                          color: cs.primary,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _levels.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _MagChip(
                          label: '${(_levels[i] * 100).toInt()}%',
                          active: i == _index,
                          onTap: () => _setLevel(i),
                          cs: cs,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pinch,
                        size: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pinch or tap to zoom',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), 18, paint);
    // Cross hairs
    canvas.drawLine(Offset(cx - 28, cy), Offset(cx - 8, cy), paint);
    canvas.drawLine(Offset(cx + 8, cy), Offset(cx + 28, cy), paint);
    canvas.drawLine(Offset(cx, cy - 28), Offset(cx, cy - 8), paint);
    canvas.drawLine(Offset(cx, cy + 8), Offset(cx, cy + 28), paint);
    // Center dot
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter old) => old.color != color;
}

class _MagChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _MagChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? cs.primary.withValues(alpha: 0.25)
          : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: active ? cs.primary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
