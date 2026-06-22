import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloudnex_pdf_reader/core/state/app_state.dart';
import 'package:cloudnex_pdf_reader/engine/edit/edit_engine.dart';

void main() {
  group('PdfEditor Core Engine Tests', () {
    late AppState stateController;
    // Dummy byte representation for testing
    final Uint8List mockBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);

    setUp(() {
      stateController = AppState();
    });

    test('Initial state should be empty', () {
      expect(stateController.currentBytes, isNull);
      expect(stateController.canUndo, isFalse);
    });

    test('Committing a mutation should update state and enable undo', () {
      // Need a session for mutation
      stateController.openDocument(mockBytes, "test.pdf");
      stateController.commitMutation(mockBytes);

      expect(stateController.currentBytes, equals(mockBytes));
      expect(stateController.canUndo, isTrue);
    });

    test('Undo should revert state correctly', () {
      stateController.openDocument(mockBytes, "test.pdf");
      final Uint8List state1 = Uint8List.fromList([1, 2, 3]);
      final Uint8List state2 = Uint8List.fromList([4, 5, 6]);

      stateController.commitMutation(state1);
      stateController.commitMutation(state2);

      stateController.undo();

      expect(stateController.currentBytes, equals(state1));
      expect(stateController.canRedo, isTrue);
    });

    test('Tool toggling state verification', () {
      stateController.toggleTool(ActivePdfTool.highlight);
      expect(stateController.currentTool, equals(ActivePdfTool.highlight));

      stateController.clearActiveTool();
      expect(stateController.currentTool, equals(ActivePdfTool.none));
    });

    test('Metadata scrub verification', () {
      // Create a mock report to verify our structural analyzer
      final report = EditEngine.analyzeDocumentStructure(mockBytes);

      // We expect the report to identify it as unverified or safe depending on input
      expect(report, isNotNull);
      expect(
          report.totalPages, equals(0)); // Should fail gracefully on bad bytes
    });
  });
}
