import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/pdf_pro_theme.dart';

class SignaturePadView extends StatefulWidget {
  const SignaturePadView({super.key});

  @override
  State<SignaturePadView> createState() => _SignaturePadViewState();
}

class StrokePoint {
  final Offset offset;
  final double pressure;
  StrokePoint(this.offset, this.pressure);
}

class _SignaturePadViewState extends State<SignaturePadView> {
  final List<List<StrokePoint>> _strokes = [];

  /// Compiles drawn coordinate vector lines into a transparent PNG byte array
  /// Optimized for S25 Ultra high-fidelity S Pen data
  Future<Uint8List?> _exportCanvasToPngBytes() async {
    if (_strokes.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 800, 400)); // High res export

    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      
      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = stroke[i];
        final p2 = stroke[i + 1];
        
        // S25 Ultra S Pen Feature: Pressure-sensitive thickness
        final paint = Paint()
          ..color = Colors.black 
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (p1.pressure * 8.0).clamp(2.0, 10.0); // Variable width based on S Pen pressure

        canvas.drawLine(p1.offset * 2, p2.offset * 2, paint);
      }
    }

    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(800, 400);
    final ByteData? pngBytes =
        await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: PdfProTheme.primaryBlue, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('S Pen Signature Core', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('Pressure-Sensitive Enabled', style: TextStyle(fontSize: 10, color: PdfProTheme.successGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: PdfProTheme.textLight),
                  onPressed: () => setState(() => _strokes.clear()),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Active drawing zone with Palm Rejection simulation
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: PdfProTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Listener(
                    onPointerDown: (event) {
                      // Logic: Only start a stroke if it's a stylus or high-pressure touch
                      if (event.kind == PointerDeviceKind.stylus || event.pressure > 0) {
                        setState(() {
                          _strokes.add([StrokePoint(event.localPosition, event.pressure)]);
                        });
                      }
                    },
                    onPointerMove: (event) {
                      if (_strokes.isNotEmpty && (event.kind == PointerDeviceKind.stylus || event.pressure > 0)) {
                        setState(() {
                          _strokes.last.add(StrokePoint(event.localPosition, event.pressure));
                        });
                      }
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: SPenPainter(_strokes),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Discard', style: TextStyle(color: PdfProTheme.textLight)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PdfProTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final bytes = await _exportCanvasToPngBytes();
                    if (context.mounted) Navigator.of(context).pop(bytes);
                  },
                  child: const Text('Capture Signature', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SPenPainter extends CustomPainter {
  final List<List<StrokePoint>> strokes;
  SPenPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      
      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = stroke[i];
        final p2 = stroke[i + 1];
        
        final paint = Paint()
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (p1.pressure * 6.0).clamp(1.5, 8.0);

        canvas.drawLine(p1.offset, p2.offset, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SPenPainter oldDelegate) => true;
}
