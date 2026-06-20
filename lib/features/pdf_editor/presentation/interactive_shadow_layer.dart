import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../domain/models/shadow_object.dart';
import '../controller/pdf_state_controller.dart';
import '../../../core/theme/pdf_pro_theme.dart';
import '../../../services/neural_engine/dom_models.dart';

class InteractiveShadowLayer extends StatelessWidget {
  final PdfStateController stateController;
  final PdfViewerController pdfViewerController;

  const InteractiveShadowLayer({
    super.key,
    required this.stateController,
    required this.pdfViewerController,
  });

  @override
  Widget build(BuildContext context) {
    final session = stateController.activeSession;
    if (session == null) return const SizedBox.shrink();

    final activePage = session.activePageNumber - 1;
    final dom = session.pageDoms[activePage];

    return Stack(
      children: [
        // 1. NEURAL HIGHLIGHTS (DOM-based)
        if (dom != null)
          ...dom.elements.map((el) => _buildNeuralBlock(el)),

        // 2. USER SHADOW OBJECTS (Manual edits)
        ...session.shadowObjects.where((obj) => obj.pageIndex == activePage).map((obj) {
          return ShadowObjectWidget(
            object: obj,
            isSelected: stateController.selectedShadowObjectId == obj.id,
            onTap: () => stateController.selectShadowObject(obj.id),
            onUpdate: (newObj) => stateController.updateShadowObject(newObj),
            onDelete: () => stateController.removeShadowObject(obj.id),
          );
        }),
      ],
    );
  }

  Widget _buildNeuralBlock(DomElement el) {
    return Positioned(
      left: el.left,
      top: el.top,
      child: Container(
        width: el.width,
        height: el.height,
        decoration: BoxDecoration(
          color: PdfProTheme.primaryBlue.withOpacity(0.05),
          border: Border.all(color: PdfProTheme.primaryBlue.withOpacity(0.1), width: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class ShadowObjectWidget extends StatelessWidget {
  final ShadowObject object;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(ShadowObject) onUpdate;
  final VoidCallback onDelete;

  const ShadowObjectWidget({
    super.key,
    required this.object,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: object.position.dx,
      top: object.position.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: isSelected
            ? (details) {
                onUpdate(object.copyWith(
                  position: object.position + details.delta,
                ));
              }
            : null,
        child: Container(
          width: object.size.width,
          height: object.size.height,
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: PdfProTheme.primaryBlue, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              _buildContent(),
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    onPressed: onDelete,
                  ),
                ),
              if (isSelected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      onUpdate(object.copyWith(
                        size: Size(
                          (object.size.width + details.delta.dx).clamp(50.0, 500.0),
                          (object.size.height + details.delta.dy).clamp(20.0, 500.0),
                        ),
                      ));
                    },
                    child: const Icon(Icons.open_in_full_rounded, color: PdfProTheme.primaryBlue, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (object.type) {
      case ShadowObjectType.text:
        return Text(
          object.content,
          style: TextStyle(
            fontSize: object.fontSize,
            color: object.color,
            fontWeight: FontWeight.bold,
          ),
        );
      case ShadowObjectType.signature:
        // Assuming content is base64 or placeholder for this demo
        return Image.memory(
          Uint8List.fromList(object.content.codeUnits), // Real logic will use bytes
          fit: BoxFit.contain,
        );
      case ShadowObjectType.shape:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: object.color, width: 2),
            borderRadius: object.content == 'CIRCLE' ? BorderRadius.circular(object.size.width) : null,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
