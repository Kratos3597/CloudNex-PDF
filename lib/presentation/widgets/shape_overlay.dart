import 'package:flutter/material.dart';
import '../../core/theme/pdf_pro_theme.dart';

enum ShapeType { rectangle, circle, line }

class ShapeOverlay extends StatefulWidget {
  final ShapeType type;
  final VoidCallback onCancel;
  final Function(Offset position, Size size) onConfirm;

  const ShapeOverlay({
    super.key,
    required this.type,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<ShapeOverlay> createState() => _ShapeOverlayState();
}

class _ShapeOverlayState extends State<ShapeOverlay> {
  Offset _position = const Offset(150, 150);
  Size _size = const Size(100, 100);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            child: Container(
              width: _size.width,
              height: _size.height,
              decoration: BoxDecoration(
                border: Border.all(color: PdfProTheme.primaryBlue, width: 2),
                borderRadius: widget.type == ShapeType.circle ? BorderRadius.circular(_size.width) : null,
                color: PdfProTheme.primaryBlue.withValues(alpha: 0.1),
              ),
              child: Stack(
                children: [
                  if (widget.type == ShapeType.line)
                    Center(
                      child: Container(
                        height: 2,
                        color: PdfProTheme.primaryBlue,
                      ),
                    ),
                  // Resize handle
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _size = Size(
                            (_size.width + details.delta.dx).clamp(20.0, 500.0),
                            (_size.height + details.delta.dy).clamp(20.0, 500.0),
                          );
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: PdfProTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: "cancel_shape",
                mini: true,
                onPressed: widget.onCancel,
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, color: PdfProTheme.errorRed),
              ),
              const SizedBox(width: 24),
              FloatingActionButton.extended(
                heroTag: "confirm_shape",
                onPressed: () => widget.onConfirm(_position, _size),
                backgroundColor: PdfProTheme.primaryBlue,
                label: Text("PLACE ${widget.type.name.toUpperCase()}", style: const TextStyle(color: Colors.white)),
                icon: const Icon(Icons.check, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
