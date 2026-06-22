import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryManager {
  MemoryManager._();

  static const String _kSessionActiveKey = 'cloudnex_session_active';
  static const String _kSessionPageKey = 'cloudnex_session_page';
  static const String _kSessionPasswordKey = 'cloudnex_session_password';
  static const String _kRecoveryFileName = 'matrix_recovery.tmp';
  static const String _kHistoryKey = 'cloudnex_pdf_history';

  /// Adds a file path and name to the history list
  static Future<void> addToHistory(String path, String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_kHistoryKey) ?? [];
    
    // Remove if already exists to move to top
    history.removeWhere((item) => item.startsWith('$path|'));
    history.insert(0, '$path|$name');

    // Keep only last 20
    if (history.length > 20) {
      history = history.sublist(0, 20);
    }

    await prefs.setStringList(_kHistoryKey, history);
  }

  static Future<List<Map<String, String>>> getHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_kHistoryKey) ?? [];
    return history.map((item) {
      final parts = item.split('|');
      return {'path': parts[0], 'name': parts[1]};
    }).toList();
  }

  /// Writes a temporary file and stores metadata for crash recovery
  static Future<void> writeRecoverySession({
    required Uint8List bytes,
    required int activePage,
    String? password,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_kRecoveryFileName');
    await file.writeAsBytes(bytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSessionActiveKey, true);
    await prefs.setInt(_kSessionPageKey, activePage);
    if (password != null) {
      await prefs.setString(_kSessionPasswordKey, password);
    }
  }

  /// Checks if a recovery session exists
  static Future<bool> hasRecoverySession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSessionActiveKey) ?? false;
  }

  /// Reads the recovery session data
  static Future<Map<String, dynamic>?> readRecoverySession() async {
    if (!await hasRecoverySession()) return null;

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_kRecoveryFileName');
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'bytes': bytes,
      'page': prefs.getInt(_kSessionPageKey) ?? 1,
      'password': prefs.getString(_kSessionPasswordKey),
    };
  }

  /// Clears recovery metadata
  static Future<void> purgeRecoverySession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionActiveKey);
    await prefs.remove(_kSessionPageKey);
    await prefs.remove(_kSessionPasswordKey);
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_kRecoveryFileName');
    if (await file.exists()) await file.delete();
  }
}
