import 'dart:convert';
import '../models/bike.dart';
import '../models/bike_parameters.dart';

typedef Json = Map<String, dynamic>;

Json cloneJson(Json value) => jsonDecode(jsonEncode(value)) as Json;

// Map order is irrelevant; list order (bikes, fields and logs) is significant.
bool sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && sameJson(a[key], b[key]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!sameJson(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

enum SyncAction { unchanged, upload, download, conflict }

SyncAction decideSync(Object? base, Object? local, Object? remote) {
  if (sameJson(local, remote)) return SyncAction.unchanged;
  if (sameJson(local, base)) return SyncAction.download;
  if (sameJson(remote, base)) return SyncAction.upload;
  return SyncAction.conflict;
}

Json documentsFromPayload(Json payload) => {
  for (final bike in payload['bikes'] as List) 'bike:${bike['id']}': bike,
  'library': payload['catalog'],
  'order': [for (final bike in payload['bikes'] as List) bike['id']],
};

Json payloadFromDocuments(Json documents) {
  final bikes = <String, dynamic>{
    for (final entry in documents.entries)
      if (entry.key.startsWith('bike:') && entry.value != null)
        entry.key.substring(5): entry.value,
  };
  final order = (documents['order'] as List? ?? [])
      .whereType<String>()
      .toList();
  final ids = {...order, ...bikes.keys};
  return {
    'bikes': [
      for (final id in ids)
        if (bikes.containsKey(id)) bikes[id],
    ],
    'catalog': documents['library'] ?? [],
  };
}

void validatePayload(Json payload) {
  if (payload['bikes'] is! List || payload['catalog'] is! List) {
    throw const FormatException('Invalid bike backup');
  }
  final ids = <String>{};
  for (final bike in payload['bikes'] as List) {
    if (bike is! Map ||
        bike['id'] is! String ||
        (bike['id'] as String).isEmpty ||
        !ids.add(bike['id'] as String) ||
        (bike['setups'] != null && bike['setups'] is! List)) {
      throw const FormatException('Invalid or duplicate bike');
    }
    final setupIds = <String>{};
    for (final setup in bike['setups'] as List? ?? []) {
      if (setup is! Map ||
          setup['id'] is! String ||
          !setupIds.add(setup['id'] as String)) {
        throw const FormatException('Invalid or duplicate setup');
      }
    }
    Bike.fromMap(Map<String, dynamic>.from(bike));
  }
  if ((payload['catalog'] as List).any((item) => item is! Map)) {
    throw const FormatException('Invalid field library');
  }
  for (final item in payload['catalog'] as List) {
    CustomSetupCategory.fromMap(Map<String, dynamic>.from(item as Map));
  }
}
