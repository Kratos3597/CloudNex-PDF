import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfCacheService {
  PdfCacheService._();

  static const String _kSessionActiveKey = 'cloudnex_session_active';
  static const String _kSessionPageKey = 'cloudnex_session_page';
  static const String _kSessionPasswordKey = 'cloudnex_session_password';
  static const String _kRecoveryFileName = 'matrix_recovery.tmp';

  /// Returns the system-sanctioned isolated temporary file directory target
  static Future<File> _getRecoveryFileTarget() async {
    final Directory tempDir = await getTemporaryDirectory();
    return File('${tempDir.path}/$_kRecoveryFileName');
  }

  /// Silently commits document state arrays and raw bytes to disk storage assets
  static Future<void> writeRecoverySession({
    required Uint8List bytes,
    required int activePage,
    String? password,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final File fileTarget = await _getRecoveryFileTarget();

      // Write raw bytes directly as a background atomic data block
      await fileTarget.writeAsBytes(bytes, flush: true);

      // Save complementary configuration registers
      await prefs.setBool(_kSessionActiveKey, true);
      await prefs.setInt(_kSessionPageKey, activePage);
      if (password != null && password.isNotEmpty) {
        await prefs.setString(_kSessionPasswordKey, password);
      } else {
        await prefs.remove(_kSessionPasswordKey);
      }
    } catch (_) {
      // Absorb tracking write failure paths gracefully
    }
  }

  /// Evaluates SharedPreferences to determine if an uncompleted session exists
  static Future<bool> hasCachedRecoverySession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool activeFlag = prefs.getBool(_kSessionActiveKey) ?? false;
    final File fileTarget = await _getRecoveryFileTarget();
    
    return activeFlag && await fileTarget.exists();
  }

  /// Extracts the cached session configuration and returns the raw file bytes
  static Future<Map<String, dynamic>?> readRecoverySession() async {
    try {
      if (!await hasCachedRecoverySession()) return null;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final File fileTarget = await _getRecoveryFileTarget();

      final Uint8List cachedBytes = await fileTarget.readAsBytes();
      final int savedPage = prefs.getInt(_kSessionPageKey) ?? 1;
      final String? savedPassword = prefs.getString(_kSessionPasswordKey);

      return {
        'bytes': cachedBytes,
        'page': savedPage,
        'password': savedPassword,
      };
    } catch (_) {
      return null;
    }
  }

  /// Wipes all tracking files and metadata records cleanly off the device storage disk
  static Future<void> purgeRecoverySession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final File fileTarget = await _getRecoveryFileTarget();

      await prefs.remove(_kSessionActiveKey);
      await prefs.remove(_kSessionPageKey);
      await prefs.remove(_kSessionPasswordKey);

      if (await fileTarget.exists()) {
        await fileTarget.delete();
      }
    } catch (_) {}
  }
}