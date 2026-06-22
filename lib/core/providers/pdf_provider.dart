import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';

final pdfStateProvider = ChangeNotifierProvider<AppState>((ref) {
  return AppState();
});
