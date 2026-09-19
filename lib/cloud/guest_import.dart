import '../data/demo_bikes.dart';
import 'sync_documents.dart';

/// Demo log dates are generated on first launch. Everything else, including
/// setup values and notes, must still match before we omit a demo from import.
bool isUntouchedDemo(Map bike) {
  Json normalized(Map value) {
    final result = cloneJson(Map<String, dynamic>.from(value));
    for (final setup in result['setups'] as List? ?? []) {
      for (final log in setup['logs'] as List? ?? []) {
        (log as Map).remove('timestamp');
      }
    }
    return result;
  }

  return sameJson(
    normalized(bike),
    normalized(createDemoBikes().single.toMap()),
  );
}

Json guestImportPayload(Json payload) {
  final copy = cloneJson(payload);
  (copy['bikes'] as List).removeWhere((bike) => isUntouchedDemo(bike as Map));
  return copy;
}
