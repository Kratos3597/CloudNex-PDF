import 'package:flutter/material.dart';
import '../../../core/theme/pdf_pro_theme.dart';

class InkDrawingOverlay extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(List<List<Offset>> paths, double strokeWidth, Color color) onConfirm;

  const InkDrawingOverlay({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<InkDrawingOverlay> createState() => _InkDrawingOverlayState();
}

class _InkDrawingOverlayState extends State<InkDrawingOverlay> {
  final List<List<Offset>> _paths = [];
  final double _strokeWidth = 3.0;
  Color _color = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Drawing Area
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _paths.add([details.localPosition]);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _paths.last.add(details.localPosition);
              });
            },
            child: CustomPaint(
              painter: InkPainter(_paths, _color, _strokeWidth),
              size: Size.infinite,
            ),
          ),
        ),
        // Toolbar
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: PdfProTheme.proGlassDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_rounded, color: PdfProTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text("INK_TOOL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    _colorBtn(Colors.black),
                    _colorBtn(Colors.red),
                    _colorBtn(Colors.blue),
                    const VerticalDivider(),
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 20),
                      onPressed: _paths.isNotEmpty ? () => setState(() => _paths.removeLast()) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: PdfProTheme.errorRed, size: 20),
                      onPressed: () => setState(() => _paths.clear()),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        // Action buttons
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: "cancel_ink",
                mini: true,
                onPressed: widget.onCancel,
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, color: PdfProTheme.errorRed),
              ),
              const SizedBox(width: 24),
              FloatingActionButton.extended(
                heroTag: "confirm_ink",
                onPressed: () => widget.onConfirm(_paths, _strokeWidth, _color),
                backgroundColor: PdfProTheme.primaryBlue,
                label: const Text("BURN TO PDF", style: TextStyle(color: Colors.white)),
                icon: const Icon(Icons.draw_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorBtn(Color c) {
    return GestureDetector(
      onTap: () => setState(() => _color = c),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: _color == c ? Colors.white : Colors.transparent, width: 2),
          boxShadow: [if (_color == c) const BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }
}

class InkPainter extends CustomPainter {
  final List<List<Offset>> paths;
  final Color color;
  final double strokeWidth;

  InkPainter(this.paths, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final path in paths) {
      if (path.isEmpty) continue;
      final p = Path();
      p.moveTo(path[0].dx, path[0].dy);
      for (int i = 1; i < path.length; i++) {
        p.lineTo(path[i].dx, path[i].dy);
      }
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(InkPainter oldDelegate) => true;
}
