import 'package:flutter/material.dart';
import '../../../core/theme/pdf_pro_theme.dart';

class InteractiveTextOverlay extends StatefulWidget {
  final String initialText;
  final VoidCallback onCancel;
  final Function(String text, Offset position, Size size, double fontSize, Color color) onConfirm;

  const InteractiveTextOverlay({
    super.key,
    this.initialText = "",
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<InteractiveTextOverlay> createState() => _InteractiveTextOverlayState();
}

class _InteractiveTextOverlayState extends State<InteractiveTextOverlay> {
  late TextEditingController _controller;
  Offset _position = const Offset(100, 100);
  Size _size = const Size(200, 50);
  double _fontSize = 14.0;
  Color _color = Colors.black;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                border: Border.all(color: PdfProTheme.primaryBlue, width: 1),
                color: Colors.white.withValues(alpha: 0.9),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      style: TextStyle(fontSize: _fontSize, color: _color),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
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
                            (_size.width + details.delta.dx).clamp(50.0, 600.0),
                            (_size.height + details.delta.dy).clamp(20.0, 400.0),
                          );
                        });
                      },
                      child: const Icon(Icons.open_in_full_rounded, color: PdfProTheme.primaryBlue, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Toolbar for font size and color
        Positioned(
          top: _position.dy - 50,
          left: _position.dx,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: PdfProTheme.proGlassDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(8.0, 72.0)),
                ),
                Text("${_fontSize.toInt()}", style: const TextStyle(fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(8.0, 72.0)),
                ),
                const SizedBox(width: 8),
                _colorPicker(Colors.black),
                _colorPicker(Colors.red),
                _colorPicker(Colors.blue),
                _colorPicker(Colors.green),
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
                heroTag: "cancel_text",
                mini: true,
                onPressed: widget.onCancel,
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, color: PdfProTheme.errorRed),
              ),
              const SizedBox(width: 24),
              FloatingActionButton.extended(
                heroTag: "confirm_text",
                onPressed: () => widget.onConfirm(_controller.text, _position, _size, _fontSize, _color),
                backgroundColor: PdfProTheme.primaryBlue,
                label: const Text("APPLY TEXT", style: TextStyle(color: Colors.white)),
                icon: const Icon(Icons.check, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorPicker(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _color = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: _color == color ? Colors.white : Colors.transparent, width: 2),
        ),
      ),
    );
  }
}
