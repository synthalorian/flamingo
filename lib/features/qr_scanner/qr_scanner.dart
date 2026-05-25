import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

import '../../core/widgets/crt_background.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController();

  void _showResult(String text) {
    final cs = Theme.of(context).colorScheme;
    Vibration.vibrate(duration: 30);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.qr_code, color: cs.primary, size: 24),
            const SizedBox(width: 8),
            Text('QR Code Detected', style: TextStyle(color: cs.primary)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            text,
            style: TextStyle(
              color: cs.onSurface,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.copy, color: cs.primary, size: 18),
            label: Text('Copy', style: TextStyle(color: cs.primary)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied to clipboard'),
                  backgroundColor: cs.surfaceContainerHigh,
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'QR SCANNER',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              // Camera viewfinder
              Expanded(
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        for (final bar in capture.barcodes) {
                          if (bar.rawValue != null) {
                            _showResult(bar.rawValue!);
                            break;
                          }
                        }
                      },
                    ),
                    // Scanner overlay with animated corners
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: CustomPaint(
                          painter: _ScannerOverlay2(
                            primaryColor: cs.primary,
                            accentColor: cs.tertiary,
                            mutedColor: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    // Instruction overlay
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.center_focus_strong,
                                color: cs.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Point camera at QR code',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ScannerOverlay2 extends CustomPainter {
  final Color primaryColor, accentColor, mutedColor;

  _ScannerOverlay2({
    required this.primaryColor,
    required this.accentColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 2;
    final h = size.height / 2;
    final boxSize = 220.0;
    final half = boxSize / 2;
    final rect = Rect.fromLTWH(w - half, h - half, boxSize, boxSize);
    final cornerLen = 30.0;
    final strokeWidth = 3.0;

    // Dim background with cutout
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      bgPath,
      Paint()
        ..color = mutedColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );

    // Scan line (horizontal)
    final scanPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(rect.left + 10, rect.center.dy),
      Offset(rect.right - 10, rect.center.dy),
      scanPaint,
    );

    // Corner brackets
    final cornerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left + cornerLen, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left, rect.top + cornerLen),
      cornerPaint,
    );
    // Top-right
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right - cornerLen, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right, rect.top + cornerLen),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left + cornerLen, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left, rect.bottom - cornerLen),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right - cornerLen, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right, rect.bottom - cornerLen),
      cornerPaint,
    );

    // Corner glow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left + cornerLen * 0.7, rect.top),
      glowPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left, rect.top + cornerLen * 0.7),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
