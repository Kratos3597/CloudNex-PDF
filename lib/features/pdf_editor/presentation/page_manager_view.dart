import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as px;
import '../../../core/theme/pdf_pro_theme.dart';
import '../controller/pdf_state_controller.dart';
import '../../../services/pdf_service.dart';

class PageManagerView extends StatefulWidget {
  final PdfStateController stateController;
  const PageManagerView({super.key, required this.stateController});

  @override
  State<PageManagerView> createState() => _PageManagerViewState();
}

class _PageManagerViewState extends State<PageManagerView> {
  List<Uint8List>? _pagePreviews;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generatePreviews();
  }

  Future<void> _generatePreviews() async {
    final bytes = widget.stateController.currentBytes;
    if (bytes == null) return;

    try {
      final doc = await px.PdfDocument.openData(bytes);
      final List<Uint8List> previews = [];
      for (int i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
        final pageImage = await page.render(width: page.width / 4, height: page.height / 4);
        if (pageImage != null) {
          previews.add(pageImage.bytes);
        }
        await page.close();
      }
      await doc.close();
      if (mounted) {
        setState(() {
          _pagePreviews = previews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error generating previews: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organize Pages"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _pagePreviews?.length ?? 0,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.memory(_pagePreviews![index], fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Page ${index + 1}", style: const TextStyle(fontSize: 10)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: PdfProTheme.errorRed),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _deletePage(index),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _deletePage(int index) async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await PdfService.deletePages(currentBytes, [index]);
    
    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    _generatePreviews(); // Refresh
  }
}
