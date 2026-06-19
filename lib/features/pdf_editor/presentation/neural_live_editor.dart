import 'package:flutter/material.dart';
import '../../../core/theme/pdf_pro_theme.dart';
import '../../../services/neural_engine/neural_vision_engine.dart';

class NeuralLiveEditor extends StatefulWidget {
  final NeuralZone zone;
  final VoidCallback onCancel;
  final Function(String newText, double fontSize) onConfirm;

  const NeuralLiveEditor({
    super.key,
    required this.zone,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<NeuralLiveEditor> createState() => _NeuralLiveEditorState();
}

class _NeuralLiveEditorState extends State<NeuralLiveEditor> {
  late TextEditingController _controller;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.zone.originalText);
    _fontSize = widget.zone.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 2: Shadow DOM (The Live Widget)
        Positioned(
          left: widget.zone.bounds.left,
          top: widget.zone.bounds.top,
          width: widget.zone.bounds.width + 50, // Bleed area
          height: widget.zone.bounds.height + 100, // Bleed area
          child: Material(
            color: Colors.transparent,
            child: TextField(
              controller: _controller,
              maxLines: null,
              autofocus: true,
              style: TextStyle(
                color: Colors.black,
                fontSize: _fontSize,
                height: 1.2,
                backgroundColor: Colors.white, // Covers the white-out perfectly
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        // Layer 3: Physics-Based Controls (Simulated via simple toolbar)
        Positioned(
          top: widget.zone.bounds.top - 60,
          left: widget.zone.bounds.left,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: PdfProTheme.proGlassDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_rounded, color: PdfProTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                const Text("NEURAL_EDIT //", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PdfProTheme.primaryBlue)),
                const VerticalDivider(),
                IconButton(icon: const Icon(Icons.remove_rounded, size: 16), onPressed: () => setState(() => _fontSize--)),
                Text("${_fontSize.toInt()}", style: const TextStyle(fontSize: 12)),
                IconButton(icon: const Icon(Icons.add_rounded, size: 16), onPressed: () => setState(() => _fontSize++)),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.close_rounded, color: PdfProTheme.errorRed), onPressed: widget.onCancel),
                IconButton(icon: const Icon(Icons.check_rounded, color: PdfProTheme.successGreen), onPressed: () => widget.onConfirm(_controller.text, _fontSize)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
