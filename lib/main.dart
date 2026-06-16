import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  runApp(const CloudNexApp());
}

class CloudNexApp extends StatelessWidget {
  const CloudNexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> openPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfEditorScreen(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1A), Color(0xFF1C1C2E)],
            begin: Alignment.topLeft,
          ),
        ),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: () => openPdf(context),
            icon: const Icon(Icons.folder_open),
            label: const Text("Open PDF"),
          ),
        ),
      ),
    );
  }
}

class PdfEditorScreen extends StatefulWidget {
  final Uint8List bytes;

  const PdfEditorScreen({super.key, required this.bytes});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  late Uint8List pdfBytes;
  bool showTools = false;

  final PdfViewerController controller = PdfViewerController();

  @override
  void initState() {
    super.initState();
    pdfBytes = widget.bytes;
  }

  // =========================
  // ✍️ SIGN PDF (REAL EDIT)
  // =========================
  Future<void> addSignature() async {
    final doc = PdfDocument(inputBytes: pdfBytes);
    final page = doc.pages[0];

    page.graphics.drawString(
      "SIGNED ✍️",
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      bounds: const Rect.fromLTWH(50, 100, 200, 50),
    );

    final bytes = doc.saveSync();
    doc.dispose();

    setState(() {
      pdfBytes = Uint8List.fromList(bytes);
    });
  }

  // =========================
  // 💾 SAVE FILE
  // =========================
  Future<void> savePdf() async {
    final file = File("/storage/emulated/0/Download/cloudnex_edited.pdf");
    await file.writeAsBytes(pdfBytes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF Saved to Downloads")),
    );
  }

  // =========================
  // 🧠 TOOL ACTIONS (PLACEHOLDERS)
  // =========================
  void enableDraw() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draw Mode (coming next)")),
    );
  }

  void enableHighlight() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Highlight Mode (coming next)")),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SfPdfViewer.memory(
              pdfBytes,
              controller: controller,
              enableDoubleTapZooming: true,
              pageSpacing: 0,
            ),
          ),

          // 🍎 iOS GLASS TOP BAR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withValues(alpha: 0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("CloudNex PDF Editor"),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: () {
                          setState(() => showTools = !showTools);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 📑 RADIAL TOOL MENU (ADOBE STYLE)
          if (showTools)
            Positioned(
              bottom: 140,
              right: 30,
              child: Column(
                children: [
                  toolButton(Icons.brush, enableDraw),
                  const SizedBox(height: 10),
                  toolButton(Icons.highlight, enableHighlight),
                  const SizedBox(height: 10),
                  toolButton(Icons.edit, addSignature),
                  const SizedBox(height: 10),
                  toolButton(Icons.save, savePdf),
                ],
              ),
            ),

          // 🍎 iOS STYLE DOCK
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      dockIcon(Icons.brush, enableDraw),
                      dockIcon(Icons.edit, addSignature),
                      dockIcon(Icons.save, savePdf),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dockIcon(IconData icon, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget toolButton(IconData icon, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}