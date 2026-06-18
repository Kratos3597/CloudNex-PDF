import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider((ref) => AiService());

class AiService {
  late final GenerativeModel _model;
  
  // In a real app, this should be securely stored (e.g., flutter_dotenv or secrets)
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> askAboutPdf(String prompt, String pdfContext) async {
    try {
      final fullPrompt = "You are CloudNex AI, a professional PDF assistant. Use the following document context to answer the user's question.\n\nContext:\n$pdfContext\n\nQuestion: $prompt";
      final content = [Content.text(fullPrompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
