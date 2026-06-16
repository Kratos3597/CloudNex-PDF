import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_core/syncfusion_flutter_core.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

void main() {
  SyncfusionLicense.registerLicense("YNgo9BigBOggjHTQxAR8/V1JHaF5cWWdCf1FpRmJGdld5fUVHYVZUTXxaS00DNHVRdkdlWXlfdnRQQ2JfWUZ3VkRWYEo=");
  runApp(const CloudNexApp());
}

class CloudNexApp extends StatelessWidget {
  const CloudNexApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const PdfReaderScreen(),
      );
}

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key});
  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  // We use Uint8List to keep the PDF in memory for editing
  Uint8List? _documentBytes;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() => _documentBytes = bytes);
    }
  }

  // Example: Basic save logic
  Future<void> _saveDocument() async {
    if (_documentBytes == null) return;
    // Implementation: Write _documentBytes to a new File path
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document Saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _documentBytes != null
              ? SfPdfViewer.memory(_documentBytes!)
              : const Center(child: Text("Select a PDF to view")),

          Positioned(
            bottom: 20, left: 20, right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: Colors.white.withValues(alpha: 0.1), // Updated for Flutter 3.27+
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.folder_open), onPressed: _pickFile),
                      IconButton(icon: const Icon(Icons.edit), onPressed: () {/* Add your Annotation logic here */}),
                      IconButton(icon: const Icon(Icons.save), onPressed: _saveDocument),
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
}