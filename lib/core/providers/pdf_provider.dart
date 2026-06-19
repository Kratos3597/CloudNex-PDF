import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pdf_editor/controller/pdf_state_controller.dart';

final pdfStateProvider = ChangeNotifierProvider<PdfStateController>((ref) {
  return PdfStateController();
});
