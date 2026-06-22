import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as px;
import '../../core/theme/pdf_pro_theme.dart';
import '../../core/state/app_state.dart';
import '../../engine/render/render_engine.dart';

class PageManagerScreen extends StatefulWidget {
  final AppState stateController;
  const PageManagerScreen({super.key, required this.stateController});

  @override
  State<PageManagerScreen> createState() => _PageManagerScreenState();
}

class _PageManagerScreenState extends State<PageManagerScreen> {
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
          : ReorderableRawView(
              onReorder: _handleReorder,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _pagePreviews?.length ?? 0,
              itemBuilder: (context, index) {
                return ReorderableDelayedDragStartListener(
                  key: ValueKey('page_$index'),
                  index: index,
                  child: Column(
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
                          Text("${index + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: PdfProTheme.errorRed),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deletePage(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final updatedBytes = await RenderEngine.reorderPages(currentBytes, oldIndex, newIndex);
    
    if (!mounted) return;
    Navigator.pop(context);
    
    widget.stateController.commitMutation(updatedBytes);
    _generatePreviews(); 
  }

  Future<void> _deletePage(int index) async {
    final currentBytes = widget.stateController.currentBytes;
    if (currentBytes == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Page?"),
        content: Text("Delete page ${index + 1}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final updatedBytes = await RenderEngine.deletePages(currentBytes, [index]);
      if (!mounted) return;
      Navigator.pop(context);
      widget.stateController.commitMutation(updatedBytes);
      _generatePreviews();
    }
  }
}

class ReorderableRawView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final void Function(int, int) onReorder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets padding;

  const ReorderableRawView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    required this.gridDelegate,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableGridView.extent(
      maxCrossAxisExtent: 150,
      onReorder: onReorder,
      padding: padding,
      children: List.generate(itemCount, (index) => itemBuilder(context, index)),
    );
  }
}

class ReorderableGridView extends StatelessWidget {
  final List<Widget> children;
  final void Function(int, int) onReorder;
  final double maxCrossAxisExtent;
  final EdgeInsets padding;

  const ReorderableGridView.extent({
    super.key,
    required this.children,
    required this.onReorder,
    required this.maxCrossAxisExtent,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      padding: padding,
      onReorder: onReorder,
      children: children,
    );
  }
}
