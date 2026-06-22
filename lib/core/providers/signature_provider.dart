import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/edit/signature_service.dart';

final signatureServiceProvider = Provider((ref) => SignatureService());

final signatureProvider = StateNotifierProvider<SignatureNotifier, AsyncValue<Uint8List?>>((ref) {
  return SignatureNotifier(ref.watch(signatureServiceProvider));
});

class SignatureNotifier extends StateNotifier<AsyncValue<Uint8List?>> {
  final SignatureService _service;

  SignatureNotifier(this._service) : super(const AsyncValue.loading()) {
    loadSignature();
  }

  Future<void> loadSignature() async {
    state = const AsyncValue.loading();
    try {
      final bytes = await _service.getSignatureBytes();
      state = AsyncValue.data(bytes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSignature(Uint8List bytes) async {
    state = const AsyncValue.loading();
    try {
      await _service.saveSignature(bytes);
      state = AsyncValue.data(bytes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeSignature() async {
    state = const AsyncValue.data(null);
  }
}
