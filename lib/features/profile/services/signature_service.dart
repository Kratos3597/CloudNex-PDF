import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignatureService {
  static const String _sigKey = 'user_signature_path';

  Future<String?> getSavedSignaturePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sigKey);
  }

  Future<void> saveSignature(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/my_signature.png');
    await file.writeAsBytes(bytes);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sigKey, file.path);
  }

  Future<Uint8List?> getSignatureBytes() async {
    final path = await getSavedSignaturePath();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    return null;
  }
}
