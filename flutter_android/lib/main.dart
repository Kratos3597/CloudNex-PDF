import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'services/pdf_service.dart';
import 'services/ocr_service.dart';
import 'widgets/signature_pad.dart';
import 'widgets/page_organizer.dart';

void main() {
  // Syncfusion License Key Registration
  const String syncfusionLicenseKey = String.fromEnvironment(
    'SYNCFUSION_LICENSE_KEY',
    defaultValue: 'Ngo9BigBOggjHTQxAR8/V1JBaF5cXmRCd1p/TH5YfUNzdUVEY1ZUTXxaS1ZhSXxVd0VjUH1edHFXQGlZU019XEc=',
  );

  SyncfusionLicense.registerLicense(syncfusionLicenseKey);

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
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
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
  final TextEditingController _searchController = TextEditingController();

  File? _currentPdfFile;
  bool _isLoading = true;
  String _documentTitle = 'Enterprise Specification.pdf';
  int _currentPage = 1;
  int _pageCount = 0;

  // Adobe Mobile Parity Features
  bool _isNightMode = false;
  bool _isSearchBarVisible = false;
  PdfTextSearchResult? _searchResult;
  PdfPageLayoutMode _pageLayoutMode = PdfPageLayoutMode.continuous;

  // Invert color matrix for Night / Reading Mode
  static const ColorFilter _nightModeMatrix = ColorFilter.matrix([
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  @override
  void initState() {
    super.initState();
    _loadSamplePdf();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
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
        _searchResult = null;
        _isSearchBarVisible = false;
      });
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    final result = _pdfViewerController.searchText(query);
    setState(() {
      _searchResult = result;
    });
  }

  void _clearSearch() {
    _searchResult?.clear();
    _searchController.clear();
    setState(() {
      _searchResult = null;
      _isSearchBarVisible = false;
    });
  }

  void _openPageOrganizer() {
    if (_currentPdfFile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PageOrganizerModal(
        pdfFile: _currentPdfFile!,
        onDocumentUpdated: (updatedFile) {
          setState(() {
            _currentPdfFile = updatedFile;
          });
        },
      ),
    );
  }

  Future<void> _handleSignAndShare() async {
    if (_currentPdfFile == null) return;

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

  Future<void> _handleOcrScanImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    final imageFile = File(result.files.single.path!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing OCR with Google ML Kit + Syncfusion...'),
          backgroundColor: Color(0xFF0052CC),
        ),
      );
    }

    setState(() => _isLoading = true);

    try {
      final searchablePdf = await FlutterOcrService.createSearchablePdfFromImage(
        imageFile: imageFile,
        outputFileName: 'OCR_${imageFile.path.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z]+$'), '')}.pdf',
      );

      setState(() {
        _currentPdfFile = searchablePdf;
        _documentTitle = searchablePdf.path.split('/').last;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Searchable PDF created! Invisible OCR text stream injected with Syncfusion.'),
            backgroundColor: Color(0xFF36B37E),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR Failed: $e'),
            backgroundColor: const Color(0xFFDE350B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget pdfViewerWidget = _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)))
        : _currentPdfFile == null
            ? const Center(child: Text('No PDF Loaded', style: TextStyle(color: Colors.white)))
            : SfPdfViewer.file(
                _currentPdfFile!,
                controller: _pdfViewerController,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                enableDocumentLinkAnnotation: true,
                enableHyperlinkNavigation: true,
                pageLayoutMode: _pageLayoutMode,
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
                onTextSelectionChanged: (details) {
                  if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected: "${details.selectedText}"'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Copy',
                          onPressed: () {
                            // Text copied automatically by system viewer
                          },
                        ),
                      ),
                    );
                  }
                },
              );

    // Apply Night / Reading Mode Invert Filter
    if (_isNightMode) {
      pdfViewerWidget = ColorFiltered(
        colorFilter: _nightModeMatrix,
        child: pdfViewerWidget,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Stack(
          children: [
            // Main PDF Canvas
            Positioned.fill(child: pdfViewerWidget),

            // Adobe-Style Floating Top Bar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Color(0xFF0052CC), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _documentTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF172B4D),
                                ),
                              ),
                              Text(
                                'Page $_currentPage of $_pageCount | Syncfusion Engine',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF6B778C)),
                              ),
                            ],
                          ),
                        ),
                        // Layout Mode Toggle
                        IconButton(
                          icon: Icon(
                            _pageLayoutMode == PdfPageLayoutMode.continuous
                                ? Icons.view_day_outlined
                                : Icons.view_array_outlined,
                            color: const Color(0xFF0052CC),
                            size: 20,
                          ),
                          tooltip: 'Toggle Continuous / Single Layout',
                          onPressed: () {
                            setState(() {
                              _pageLayoutMode = _pageLayoutMode == PdfPageLayoutMode.continuous
                                  ? PdfPageLayoutMode.single
                                  : PdfPageLayoutMode.continuous;
                            });
                          },
                        ),
                        // Search Toggle
                        IconButton(
                          icon: Icon(
                            _isSearchBarVisible ? Icons.search_off : Icons.search,
                            color: const Color(0xFF0052CC),
                            size: 20,
                          ),
                          tooltip: 'Search In PDF',
                          onPressed: () {
                            setState(() {
                              _isSearchBarVisible = !_isSearchBarVisible;
                              if (!_isSearchBarVisible) _clearSearch();
                            });
                          },
                        ),
                        // Pick File
                        IconButton(
                          icon: const Icon(Icons.folder_open, color: Color(0xFF0052CC), size: 20),
                          tooltip: 'Open PDF File',
                          onPressed: _pickExternalPdf,
                        ),
                      ],
                    ),

                    // Expandable Adobe Search Bar
                    if (_isSearchBarVisible) ...[
                      const Divider(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search words in PDF...',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
                                ),
                              ),
                              onSubmitted: _performSearch,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            onPressed: () => _searchResult?.previousInstance(),
                          ),
                          Text(
                            _searchResult != null && _searchResult!.totalInstanceCount > 0
                                ? '${_searchResult!.currentInstanceIndex}/${_searchResult!.totalInstanceCount}'
                                : '0/0',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () => _searchResult?.nextInstance(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            onPressed: _clearSearch,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Adobe-Style Floating Bottom Tool Bar
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF172B4D).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. Page Organizer
                    IconButton(
                      icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                      tooltip: 'Page Organizer',
                      onPressed: _openPageOrganizer,
                    ),
                    // 2. Digital Signature & Flattening
                    IconButton(
                      icon: const Icon(Icons.draw, color: Color(0xFF4C9AFF), size: 22),
                      tooltip: 'Sign & Flatten',
                      onPressed: _handleSignAndShare,
                    ),
                    // 3. OCR Scan Image to Searchable PDF
                    IconButton(
                      icon: const Icon(Icons.document_scanner, color: Color(0xFF36B37E), size: 22),
                      tooltip: 'OCR Scan to PDF',
                      onPressed: _handleOcrScanImage,
                    ),
                    // 4. Night / Reading Mode
                    IconButton(
                      icon: Icon(
                        _isNightMode ? Icons.light_mode : Icons.dark_mode,
                        color: _isNightMode ? const Color(0xFFFFAB00) : Colors.white,
                        size: 22,
                      ),
                      tooltip: _isNightMode ? 'Switch to Day Mode' : 'Switch to Night Mode',
                      onPressed: () {
                        setState(() {
                          _isNightMode = !_isNightMode;
                        });
                      },
                    ),
                    // 5. Native Share Sheet
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white, size: 22),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
