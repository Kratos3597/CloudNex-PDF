import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/pdf_pro_theme.dart';
import '../services/signature_service.dart';

class SignatureVaultView extends StatefulWidget {
  const SignatureVaultView({super.key});

  @override
  State<SignatureVaultView> createState() => _SignatureVaultViewState();
}

class _SignatureVaultViewState extends State<SignatureVaultView> {
  final SignatureService _service = SignatureService();
  Uint8List? _currentSignature;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignature();
  }

  Future<void> _loadSignature() async {
    final bytes = await _service.getSignatureBytes();
    if (mounted) {
      setState(() {
        _currentSignature = bytes;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickSignature() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final bytes = await File(result.files.single.path!).readAsBytes();
      // Heuristic background removal could be added here
      await _service.saveSignature(bytes);
      _loadSignature();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signature Management")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "My Digital Signature",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Attach a JPEG/PNG of your signature. We will use this to sign documents instantly.",
                textAlign: TextAlign.center,
                style: TextStyle(color: PdfProTheme.textLight),
              ),
              const SizedBox(height: 48),
              
              Container(
                width: 300,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _currentSignature != null 
                        ? Image.memory(_currentSignature!)
                        : Center(child: Icon(Icons.gesture_rounded, size: 48, color: Colors.grey.shade200)),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: _pickSignature,
                icon: const Icon(Icons.upload_rounded),
                label: Text(_currentSignature == null ? "Attach Signature" : "Replace Signature"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PdfProTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              if (_currentSignature != null)
                TextButton(
                  onPressed: () async {
                    // Logic to delete
                  },
                  child: const Text("Remove Signature", style: TextStyle(color: PdfProTheme.errorRed)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
