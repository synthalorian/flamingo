import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController();

  void _showResult(String text) {
    Vibration.vibrate(duration: 30);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlamingoColors.card,
        title: Text('QR Code Detected',
            style: TextStyle(color: FlamingoColors.primary)),
        content: SelectableText(text,
            style: TextStyle(color: FlamingoColors.text)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: Text('Copy',
                style: TextStyle(color: FlamingoColors.neonBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(color: FlamingoColors.muted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Camera viewfinder
              Expanded(
                child: Stack(
                  children: [
                    MobileScanner(controller: _controller, onDetect: (capture) {
                      for (final bar in capture.barcodes) {
                        if (bar.rawValue != null) {
                          _showResult(bar.rawValue!);
                          break;
                        }
                      }
                    }),
                    // Overlay
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: CustomPaint(
                          painter: _ScannerOverlay(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Instructions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Point camera at a QR code',
                  style: TextStyle(color: FlamingoColors.muted, fontSize: 14),
                  textAlign: TextAlign.center,
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

class _ScannerOverlay extends CustomPainter {
  static const _borderWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 2;
    final h = size.height / 2;
    final box = Rect.fromLTWH(w - 110, h - 110, 220, 220);

    // Dim background
    final bg = Paint()
      ..color = FlamingoColors.scaffoldBg.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Cut out the scan box
    canvas.drawPath(
        Path()
          ..addRect(box)
          ..fillType = PathFillType.evenOdd,
        Paint()..style = PaintingStyle.fill..color = Colors.transparent);

    // Border glow
    final border = Paint()
      ..color = FlamingoColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
    canvas.drawPath(Path()..addRect(box)..fillType = PathFillType.evenOdd, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
