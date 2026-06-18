import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../services/ai_service.dart';
import '../../../services/pdf_service.dart';
import 'dart:typed_data';

class AiAssistantPanel extends ConsumerStatefulWidget {
  final Uint8List? pdfBytes;
  const AiAssistantPanel({super.key, this.pdfBytes});

  @override
  ConsumerState<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends ConsumerState<AiAssistantPanel> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "assistant", "content": "I am your CloudNex AI. How can I assist with your document today?"}
  ];

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": prompt});
      _controller.clear();
      _isLoading = true;
    });

    String context = "";
    if (widget.pdfBytes != null) {
      context = PdfService.extractText(widget.pdfBytes!);
    }

    final response = await ref.read(aiServiceProvider).askAboutPdf(prompt, context);

    if (mounted) {
      setState(() {
        _messages.add({"role": "assistant", "content": response});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: CyberpunkTheme.backgroundDark.withOpacity(0.9),
        border: Border(left: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildChatList()),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CyberpunkTheme.neonCyan),
                  ),
                  const SizedBox(width: 8),
                  Text("THINKING...", style: CyberpunkTheme.neonTextStyle(fontSize: 10)),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: CyberpunkTheme.neonCyan),
          const SizedBox(width: 12),
          Text(
            "NEURAL_LINK //",
            style: CyberpunkTheme.neonTextStyle(bold: true, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isAi = msg["role"] == "assistant";
        return Align(
          alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: CyberpunkTheme.glassDecoration(
              borderColor: isAi ? Colors.white12 : CyberpunkTheme.neonCyan.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              msg["content"]!,
              style: TextStyle(
                color: isAi ? Colors.white : CyberpunkTheme.neonCyan,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
        decoration: InputDecoration(
          hintText: "Enter protocol query...",
          hintStyle: const TextStyle(color: Colors.white24),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: CyberpunkTheme.neonCyan),
            onPressed: _sendMessage,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.02),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(color: CyberpunkTheme.neonCyan),
          ),
        ),
      ),
    );
  }
}
