import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';

class DrawingBoardScreen extends StatefulWidget {
  const DrawingBoardScreen({super.key});

  @override
  State<DrawingBoardScreen> createState() => _DrawingBoardScreenState();
}

class _DrawingBoardScreenState extends State<DrawingBoardScreen> {
  final _strokes = <_Stroke>[];
  final _undoStack = <_Stroke>[];
  Color _currentColor = Colors.white;
  double _strokeWidth = 3.0;
  Offset? _currentPoint;
  _Stroke? _currentStroke;
  final _repaintKey = GlobalKey();
  bool _saving = false;

  static const _colors = [
    Colors.white,
    Color(0xFF90CAF9),
    Color(0xFF81C784),
    Color(0xFFFFF176),
    Color(0xFFFF8A65),
    Color(0xFFE57373),
    Color(0xFFCE93D8),
    Color(0xFF4DD0E1),
    Colors.black,
    Color(0xFF9E9E9E),
  ];

  static const _strokeWidths = [2.0, 4.0, 8.0, 14.0, 24.0];

  void _onPanStart(DragStartDetails d) {
    final renderBox =
        _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(d.globalPosition);
    _currentStroke = _Stroke(
      color: _currentColor,
      width: _strokeWidth,
      points: [localPos],
    );
    _currentPoint = localPos;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final renderBox =
        _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _currentStroke == null) return;
    final localPos = renderBox.globalToLocal(d.globalPosition);
    _currentStroke!.points.add(localPos);
    _currentPoint = localPos;
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentStroke != null) {
      _strokes.add(_currentStroke!);
      _undoStack.clear();
      _currentStroke = null;
      _currentPoint = null;
      setState(() {});
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      _undoStack.add(_strokes.removeLast());
      setState(() {});
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      _strokes.add(_undoStack.removeLast());
      setState(() {});
    }
  }

  void _clear() {
    _strokes.clear();
    _undoStack.clear();
    _currentStroke = null;
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Drawing saved!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: 2,
          colors: [cs.primary, cs.secondary],
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'DRAWING BOARD',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          letterSpacing: 4,
                        ),
                      ),
                      const Spacer(),
                      _toolBtn(cs, Icons.undo_rounded, _undo, _strokes.isEmpty),
                      const SizedBox(width: 4),
                      _toolBtn(
                        cs,
                        Icons.redo_rounded,
                        _redo,
                        _undoStack.isEmpty,
                      ),
                      const SizedBox(width: 4),
                      _toolBtn(cs, Icons.delete_outline, _clear, _strokes.isEmpty),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: _saving
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.primary,
                                  ),
                                )
                              : Icon(Icons.save_rounded,
                                  color: cs.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Canvas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              painter: _DrawingPainter(
                                strokes: _strokes,
                                currentStroke: _currentStroke,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom toolbar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        cs.surfaceContainerHigh.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Color palette
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: _colors.map((c) {
                            final active = _currentColor == c;
                            return GestureDetector(
                              onTap: () => setState(() => _currentColor = c),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.2),
                                    width: active ? 2.5 : 1,
                                  ),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: c.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stroke width selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: _strokeWidths.map((w) {
                            final active = _strokeWidth == w;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _strokeWidth = w),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? cs.primary.withValues(alpha: 0.15)
                                      : cs.surfaceContainerHigh
                                          .withValues(alpha: 0.5),
                                  border: Border.all(
                                    color: active
                                        ? cs.primary.withValues(alpha: 0.5)
                                        : cs.outlineVariant
                                            .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: w.clamp(2.0, 20.0),
                                    height: w.clamp(2.0, 20.0),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(
    ColorScheme cs,
    IconData icon,
    VoidCallback onTap,
    bool disabled,
  ) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.transparent
              : cs.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: disabled
              ? null
              : Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
        ),
        child: Icon(
          icon,
          color: disabled
              ? cs.onSurfaceVariant.withValues(alpha: 0.2)
              : cs.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;

  _Stroke({
    required this.color,
    required this.width,
    required this.points,
  });
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Grid dots
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04);
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1, gridPaint);
      }
    }

    void drawStroke(_Stroke stroke) {
      if (stroke.points.isEmpty) return;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    for (final s in strokes) {
      drawStroke(s);
    }
    if (currentStroke != null) {
      drawStroke(currentStroke!);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}
