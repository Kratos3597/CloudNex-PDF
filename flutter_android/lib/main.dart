import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'services/pdf_service.dart';
import 'widgets/signature_pad.dart';

void main() {
  // IMPORTANT: Register your Syncfusion License Key here
  // You can obtain your commercial or free community license from syncfusion.com
  const String syncfusionLicenseKey = String.fromEnvironment(
    'SYNCFUSION_LICENSE_KEY',
    defaultValue: 'YOUR_SYNCFUSION_LICENSE_KEY_HERE',
  );

  if (syncfusionLicenseKey != 'YOUR_SYNCFUSION_LICENSE_KEY_HERE') {
    SyncfusionLicense.registerLicense(syncfusionLicenseKey);
  }

  runApp(const CloudNexPdfApp());
}

class CloudNexPdfApp extends StatelessWidget {
  const CloudNexPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudNex PDF Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052CC),
          primary: const Color(0xFF0052CC),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
      ),
      home: const PdfViewerScreen(),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  File? _currentPdfFile;
  bool _isLoading = true;
  String _documentTitle = 'Enterprise Specification.pdf';
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSamplePdf();
  }

  Future<void> _loadSamplePdf() async {
    setState(() => _isLoading = true);
    try {
      final file = await CloudNexPdfService.createStressTestImagePdf();
      setState(() {
        _currentPdfFile = file;
        _documentTitle = 'CloudNex_Large_Sample.pdf';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error creating stress test PDF: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickExternalPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _currentPdfFile = File(result.files.single.path!);
        _documentTitle = result.files.single.name;
      });
    }
  }

  Future<void> _handleSignAndShare() async {
    if (_currentPdfFile == null) return;

    // 1. Show Signature Pad
    showDialog(
      context: context,
      builder: (ctx) => SignaturePadModal(
        onSigned: (signatureBytes) async {
          _processSignature(signatureBytes);
        },
      ),
    );
  }

  Future<void> _processSignature(Uint8List signatureBytes) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flattening signature into PDF bytes...'),
        backgroundColor: Color(0xFF0052CC),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final originalBytes = await _currentPdfFile!.readAsBytes();
      
      // Place signature stamp at bottom right of current page
      final signedFile = await CloudNexPdfService.applySignatureAndFlatten(
        originalPdfBytes: originalBytes,
        signaturePngBytes: signatureBytes,
        pageIndex: _pdfViewerController.pageNumber > 0 ? _pdfViewerController.pageNumber - 1 : 0,
        boundingBox: const Rect.fromLTWH(380, 700, 160, 60),
        outputFileName: 'SIGNED_${_currentPdfFile!.path.split('/').last}',
      );

      setState(() {
        _currentPdfFile = signedFile;
      });

      // 2. Trigger native Android Share Sheet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Android Share Sheet...'),
            backgroundColor: Color(0xFF36B37E),
          ),
        );
      }

      await CloudNexPdfService.sharePdfFile(
        pdfFile: signedFile,
        subject: 'Signed PDF: $_documentTitle',
        text: 'Attached is the verified and flattened signed PDF from CloudNex PDF Pro.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign and share: $e'),
            backgroundColor: const Color(0xFFDE350B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _documentTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF172B4D)),
            ),
            Text(
              'Page $_currentPage of $_pageCount | Syncfusion Engine',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B778C)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open, color: Color(0xFF0052CC)),
            tooltip: 'Open PDF',
            onPressed: _pickExternalPdf,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF0052CC)),
            tooltip: 'Share Document',
            onPressed: () {
              if (_currentPdfFile != null) {
                CloudNexPdfService.sharePdfFile(
                  pdfFile: _currentPdfFile!,
                  subject: _documentTitle,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPdfFile == null
              ? const Center(child: Text('No PDF Loaded'))
              : SfPdfViewer.file(
                  _currentPdfFile!,
                  controller: _pdfViewerController,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  enableDoubleTapZooming: true,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  onDocumentLoaded: (details) {
                    setState(() {
                      _pageCount = details.document.pages.count;
                    });
                  },
                  onPageChanged: (details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleSignAndShare,
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.draw),
        label: const Text('Sign & Share'),
      ),
    );
  }
}
