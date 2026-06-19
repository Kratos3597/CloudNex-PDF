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
      final fullPrompt = "You are CloudNex AI, a professional PDF assistant. Use the following document context to answer the user's question. Be concise and professional.\n\nContext:\n$pdfContext\n\nQuestion: $prompt";
      final content = [Content.text(fullPrompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      if (e.toString().contains('API_KEY_INVALID')) {
        return "// ERROR: AI_CORE_OFFLINE. (API Key not configured). Using local heuristic fallback...";
      }
      return "Error: $e";
    }
  }

  /// Part 3: Semantic Analysis / Summarization
  Future<String> summarizeDocument(String context) async {
    return askAboutPdf("Summarize this document in 5 key bullet points.", context);
  }

  Future<String> extractActionItems(String context) async {
    return askAboutPdf("Extract all action items, deadlines, and responsibilities from this document.", context);
  }

  /// Part 3: Semantic Search Simulation
  /// In a real RAG system, we'd use embeddings. For this POC, we'll use a keyword-weighted semantic check.
  List<String> semanticFilter(List<String> documentTitles, String query) {
    final lowerQuery = query.toLowerCase();
    // Simulate AI relevance scoring
    return documentTitles.where((title) {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains(lowerQuery)) return true;
      
      // Simulate semantic relation (e.g., 'invoice' matches 'billing')
      if (lowerQuery == "billing" && lowerTitle.contains("invoice")) return true;
      if (lowerQuery == "legal" && lowerTitle.contains("contract")) return true;
      if (lowerQuery == "report" && lowerTitle.contains("analysis")) return true;
      
      return false;
    }).toList();
  }
}
