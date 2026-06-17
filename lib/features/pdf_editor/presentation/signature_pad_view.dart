import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/cyberpunk_theme.dart';

class SignaturePadView extends StatefulWidget {
  const SignaturePadView({super.key});

  @override
  State<SignaturePadView> createState() => _SignaturePadViewState();
}

class _SignaturePadViewState extends State<SignaturePadView> {
  final List<Offset?> _points = [];

  /// Compiles drawn coordinate vector lines into a transparent PNG byte array
  Future<Uint8List?> _exportCanvasToPngBytes() async {
    if (_points.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 200));

    final paint = Paint()
      ..color = Colors.black // Clean dark ink for legal contrast
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(400, 200);
    final ByteData? pngBytes =
        await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: CyberpunkTheme.glassBlurFilter,
          child: Container(
            width: double.infinity,
            decoration: CyberpunkTheme.glassDecoration(
              borderColor: CyberpunkTheme.neonCyan.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.gesture,
                        color: CyberpunkTheme.neonCyan, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'BIOMETRIC DRAW CORE',
                      style: TextStyle(
                          color: CyberpunkTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active drawing zone
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _points.add(details.localPosition);
                          });
                        },
                        onPanEnd: (_) => setState(() => _points.add(null)),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: VectorLinePainter(_points),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Operation Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _points.clear()),
                      child: const Text('PURGE',
                          style: TextStyle(color: CyberpunkTheme.neonPink)),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('CANCEL',
                              style: TextStyle(
                                  color: CyberpunkTheme.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                CyberpunkTheme.neonCyan.withValues(alpha: 0.2),
                            side: const BorderSide(
                                color: CyberpunkTheme.neonCyan),
                          ),
                          onPressed: () async {
                            final bytes = await _exportCanvasToPngBytes();
                            if (context.mounted)
                              Navigator.of(context).pop(bytes);
                          },
                          child: const Text('INJECT',
                              style: TextStyle(
                                  color: CyberpunkTheme.textPrimary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VectorLinePainter extends CustomPainter {
  final List<Offset?> points;
  VectorLinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant VectorLinePainter oldDelegate) => true;
}
