import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CloudNexApp());
}

class CloudNexApp extends StatelessWidget {
  const CloudNexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const LibraryScreen(),
    );
  }
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<File> recentFiles = [];

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);

      setState(() {
        recentFiles.insert(0, file);
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(file: file),
        ),
      );
    }
  }

  void openFile(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CloudNex PDF Library"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickPdf,
        child: const Icon(Icons.add),
      ),
      body: recentFiles.isEmpty
          ? const Center(
              child: Text(
                "No PDFs yet.\nTap + to open a file.",
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: recentFiles.length,
              itemBuilder: (context, index) {
                final file = recentFiles[index];

                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(file.path.split('/').last),
                  onTap: () => openFile(file),
                );
              },
            ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final File file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? bytes;
  final PdfViewerController _controller = PdfViewerController();

  @override
  void initState() {
    super.initState();
    loadFile();
  }

  Future<void> loadFile() async {
    final data = await widget.file.readAsBytes();
    setState(() => bytes = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.file.path.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _controller.zoomLevel += 0.2,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _controller.zoomLevel -= 0.2,
          ),
        ],
      ),
      body: bytes == null
          ? const Center(child: CircularProgressIndicator())
          : RepaintBoundary(
              child: SfPdfViewer.memory(
                bytes!,
                controller: _controller,

                // 🔥 Pro-level performance settings
                canShowScrollHead: false,
                canShowScrollStatus: false,
                pageSpacing: 0,
                enableDoubleTapZooming: true,
              ),
            ),
    );
  }
}