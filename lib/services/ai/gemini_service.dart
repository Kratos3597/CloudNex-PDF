import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  // In a real app, the API key would be fetched from environment variables or a secure vault.
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  return GeminiService(apiKey);
});

class GeminiService {
  final String apiKey;
  late final GenerativeModel model;

  GeminiService(this.apiKey) {
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> summarizePdfText(String text) async {
    final prompt = "Please summarize the following PDF content in a concise, enterprise-ready format with key insights: \n\n $text";
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? "Unable to generate summary.";
  }

  Future<String> askAboutDocument(String question, String context) async {
    final prompt = "Context from PDF: $context \n\n Question: $question";
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? "No response from AI.";
  }
}
