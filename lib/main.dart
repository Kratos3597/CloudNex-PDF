import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart'; // Required for PDF rendering
import 'pdf_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => PdfProvider(),
      child: const CloudNexApp(),
    ),
  );
}

class CloudNexApp extends StatelessWidget {
  const CloudNexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudNex PDF Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CloudNex PDF Pro")),
      body: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          // If no file is selected, show the selection button
          if (provider.selectedFile == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => provider.pickAndLoadPdf(),
                child: const Text("Select PDF"),
              ),
            );
          }

          // If a file is selected, show the PDF Viewer
          return PdfViewer.file(
            provider.selectedFile!.path,
            params: const PdfViewerParams(),
          );
        },
      ),
    );
  }
}