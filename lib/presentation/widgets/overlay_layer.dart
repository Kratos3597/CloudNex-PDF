import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/state/app_state.dart';
import '../../storage/graph/overlay_model.dart';
import '../../core/theme/pdf_pro_theme.dart';

class OverlayLayer extends StatelessWidget {
  final AppState stateController;
  final PdfViewerController pdfViewerController;

  const OverlayLayer({
    super.key,
    required this.stateController,
    required this.pdfViewerController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: stateController,
      builder: (context, _) {
        final objects = stateController.activeShadowObjects
            .where((obj) => obj.pageIndex == stateController.activePageNumber - 1)
            .toList();

        return Stack(
          children: objects.map((obj) => _buildShadowObject(context, obj)).toList(),
        );
      },
    );
  }

  Widget _buildShadowObject(BuildContext context, ShadowObject obj) {
    final isSelected = stateController.selectedShadowObjectId == obj.id;

    return Positioned(
      left: obj.position.dx,
      top: obj.position.dy,
      child: GestureDetector(
        onTap: () => stateController.selectShadowObject(obj.id),
        onPanUpdate: (details) {
          if (isSelected) {
            obj.position += details.delta;
            stateController.updateShadowObject(obj);
          }
        },
        child: Container(
          width: obj.size.width,
          height: obj.size.height,
          decoration: BoxDecoration(
            border: isSelected ? Border.all(color: PdfProTheme.primaryBlue, width: 2) : null,
          ),
          child: _renderContent(obj),
        ),
      ),
    );
  }

  Widget _renderContent(ShadowObject obj) {
    switch (obj.type) {
      case ShadowObjectType.text:
        return Text(
          obj.content,
          style: TextStyle(fontSize: obj.fontSize, color: obj.color),
        );
      case ShadowObjectType.signature:
        // Signature content is image bytes as string code units
        return Image.memory(stateController.activeSignatureGraphicBytes!);
      case ShadowObjectType.shape:
        return Container(
          decoration: BoxDecoration(
            color: obj.color.withValues(alpha: 0.3),
            shape: obj.content == 'CIRCLE' ? BoxShape.circle : BoxShape.rectangle,
            border: Border.all(color: obj.color),
          ),
        );
      case ShadowObjectType.redact:
        return Container(color: Colors.black);
    }
  }
}
