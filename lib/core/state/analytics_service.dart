import 'package:flutter/foundation.dart';

class AuditEntry {
  final String id;
  final String action;
  final String documentName;
  final DateTime timestamp;
  final String user;

  AuditEntry({
    required this.id,
    required this.action,
    required this.documentName,
    required this.timestamp,
    required this.user,
  });
}

class AnalyticsService extends ChangeNotifier {
  final List<AuditEntry> _auditTrail = [];
  List<AuditEntry> get auditTrail => _auditTrail;

  void logAction(String action, String documentName) {
    _auditTrail.insert(0, AuditEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      documentName: documentName,
      timestamp: DateTime.now(),
      user: "OPERATOR_01",
    ));
    notifyListeners();
  }

  Map<String, int> getActionStats() {
    final stats = <String, int>{};
    for (var entry in _auditTrail) {
      stats[entry.action] = (stats[entry.action] ?? 0) + 1;
    }
    return stats;
  }
}

final analyticsService = AnalyticsService();
