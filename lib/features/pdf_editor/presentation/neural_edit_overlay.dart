import 'package:flutter/material.dart';
import '../../../core/theme/pdf_pro_theme.dart';

class NeuralEditOverlay extends StatefulWidget {
  final String initialText;
  final Rect boundingBox;
  final VoidCallback onCancel;
  final Function(String newText) onConfirm;

  const NeuralEditOverlay({
    super.key,
    required this.initialText,
    required this.boundingBox,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<NeuralEditOverlay> createState() => _NeuralEditOverlayState();
}

class _NeuralEditOverlayState extends State<NeuralEditOverlay> {
  late TextEditingController _controller;

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
        // Positioning the text editor exactly over the original PDF text
        Positioned(
          left: widget.boundingBox.left,
          top: widget.boundingBox.top,
          width: widget.boundingBox.width,
          height: widget.boundingBox.height,
          child: Container(
            color: Colors.white, // Overlays the white-out
            child: TextField(
              controller: _controller,
              maxLines: null,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12, // Should ideally be calculated from original text
                height: 1.2,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              autofocus: true,
            ),
          ),
        ),
        // floating action bar
        Positioned(
          top: widget.boundingBox.top - 60,
          left: widget.boundingBox.left,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: PdfProTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onCancel,
                  ),
                  const VerticalDivider(color: Colors.white24),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: () => widget.onConfirm(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
