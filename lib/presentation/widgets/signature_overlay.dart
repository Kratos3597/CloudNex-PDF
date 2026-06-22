import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/pdf_pro_theme.dart';

class SignatureOverlay extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onCancel;
  final Function(Offset position, Size size) onConfirm;

  const SignatureOverlay({
    super.key,
    required this.imageBytes,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<SignatureOverlay> createState() => _SignatureOverlayState();
}

class _SignatureOverlayState extends State<SignatureOverlay> {
  Offset _position = const Offset(100, 100);
  Size _size = const Size(150, 75);

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
                color: Colors.transparent,
              ),
              child: Stack(
                children: [
                  Image.memory(widget.imageBytes, fit: BoxFit.contain),
                  // Resize handle
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _size = Size(
                            (_size.width + details.delta.dx).clamp(50.0, 400.0),
                            (_size.height + details.delta.dy).clamp(25.0, 200.0),
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
        // Action buttons
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: "cancel_sig",
                onPressed: widget.onCancel,
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, color: PdfProTheme.errorRed),
              ),
              const SizedBox(width: 24),
              FloatingActionButton.extended(
                heroTag: "confirm_sig",
                onPressed: () => widget.onConfirm(_position, _size),
                backgroundColor: PdfProTheme.primaryBlue,
                label: const Text("PLACE SIGNATURE", style: TextStyle(color: Colors.white)),
                icon: const Icon(Icons.check, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
