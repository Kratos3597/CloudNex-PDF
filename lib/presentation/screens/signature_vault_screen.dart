import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/pdf_pro_theme.dart';
import '../../core/providers/signature_provider.dart';
import '../../engine/edit/image_engine.dart';

class SignatureVaultScreen extends ConsumerWidget {
  const SignatureVaultScreen({super.key});

  Future<void> _pickSignature(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // Required for Web to get bytes directly
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      
      // Heuristic background removal in background isolate
      final processedBytes = await ImageEngine.removeBackgroundAsync(bytes);
      
      await ref.read(signatureProvider.notifier).updateSignature(processedBytes);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signatureAsync = ref.watch(signatureProvider);

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
                "Attach a JPEG/PNG of your signature. We will remove the background so it looks professional on documents.",
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
                child: signatureAsync.when(
                  data: (bytes) => bytes != null 
                      ? Image.memory(bytes)
                      : Center(child: Icon(Icons.gesture_rounded, size: 48, color: Colors.grey.shade200)),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => _pickSignature(context, ref),
                icon: const Icon(Icons.upload_rounded),
                label: Text(signatureAsync.value == null ? "Attach Signature" : "Replace Signature"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PdfProTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              if (signatureAsync.value != null)
                TextButton(
                  onPressed: () => ref.read(signatureProvider.notifier).removeSignature(),
                  child: const Text("Remove Signature", style: TextStyle(color: PdfProTheme.errorRed)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
