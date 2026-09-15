import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'sync_documents.dart';

/// One transactional record contains both user data and its sync baseline.
/// The legacy preferences are retained unchanged as a migration backup.
class LocalStore extends ChangeNotifier {
  LocalStore(this.database);
  final Database database;
  final _record = stringMapStoreFactory.store('workspaces');
  Json _state = {};
  Future<void> _queue = Future.value();
  Json get state => cloneJson(_state);
  Json get payload => cloneJson(_state['payload'] as Json);
  String? get owner => _state['owner'] as String?;
  bool get initialized => _state['initialized'] == true;
  DateTime? get lastSync =>
      DateTime.tryParse(_state['lastSync'] as String? ?? '');

  Future<void> initialize(SharedPreferences preferences) async {
    final existing = await _record.record('active').get(database);
    if (existing != null) {
      if (existing['version'] != 1) {
        throw const FormatException('Unsupported local data version');
      }
      _state = Map<String, dynamic>.from(existing);
      validatePayload(payload);
      return;
    }
    final bikes = preferences.getString('bikes_data');
    final catalog = preferences.getString('custom_field_catalog');
    // Save raw input before decoding: corrupt legacy data must never be replaced.
    await _record.record('legacy-backup').put(database, {
      'bikes_data': bikes,
      'custom_field_catalog': catalog,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    final data = <String, dynamic>{
      'bikes': bikes == null || bikes.isEmpty ? [] : jsonDecode(bikes),
      'catalog': catalog == null ? [] : jsonDecode(catalog),
    };
    validatePayload(data);
    _state = {
      'version': 1,
      'owner': null,
      'payload': data,
      'base': {},
      'initialized': bikes != null,
    };
    await _record.record('active').put(database, _state);
  }

  Future<void> mutate(void Function(Json next) change) {
    final result = _queue.then((_) async {
      final next = cloneJson(_state);
      change(next);
      validatePayload(next['payload'] as Json);
      await database.transaction((txn) async {
        final persisted = await _record.record('active').get(txn);
        if (persisted?['localRevision'] != _state['localRevision']) {
          throw StateError(
            'Another app tab changed the data. Export unsaved changes and reload.',
          );
        }
        next['localRevision'] = (next['localRevision'] as int? ?? 0) + 1;
        await _record.record('active').put(txn, next);
      });
      _state = next;
      notifyListeners();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  Future<void> savePayload(Json value) {
    validatePayload(value);
    final copy = cloneJson(value);
    return mutate((state) {
      state['payload'] = copy;
      state['initialized'] = true;
      state['editVersion'] = (state['editVersion'] as int? ?? 0) + 1;
      state.remove('lastSync');
    });
  }

  Future<void> bindOwner(String uid) => mutate((state) {
    if (state['owner'] != null && state['owner'] != uid) {
      throw StateError('Account switch requires an explicit workspace switch');
    }
    state['owner'] = uid;
  });

  Future<void> switchOwner(String? uid) {
    final result = _queue.then((_) async {
      Json? next;
      await database.transaction((txn) async {
        final persisted = await _record.record('active').get(txn);
        if (persisted?['localRevision'] != _state['localRevision']) {
          throw StateError('Another app tab changed the data. Reload first.');
        }
        await _record.record('account:${owner ?? 'local'}').put(txn, _state);
        final saved = await _record
            .record('account:${uid ?? 'local'}')
            .get(txn);
        next = saved == null
            ? {
                'version': 1,
                'owner': uid,
                'payload': {'bikes': [], 'catalog': []},
                'base': {},
                'initialized': true,
              }
            : Map<String, dynamic>.from(saved);
        next!['localRevision'] = (_state['localRevision'] as int? ?? 0) + 1;
        await _record.record('active').put(txn, next!);
      });
      _state = next!;
      notifyListeners();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  Future<void> backup(String reason) async {
    await _queue;
    await _record.record('backup:${DateTime.now().microsecondsSinceEpoch}').put(
      database,
      {...state, 'reason': reason},
    );
  }

  Future<void> flush() => _queue;

  Future<List<Json>> savedWorkspaces() async {
    await _queue;
    final rows = await _record.find(database);
    return [
      for (final row in rows)
        if ((row.key.startsWith('backup:') || row.key.startsWith('account:')) &&
            row.value['payload'] is Map &&
            row.value['owner'] == owner)
          {'key': row.key, ...row.value},
    ]..sort((a, b) => (b['key'] as String).compareTo(a['key'] as String));
  }

  Future<void> saveGuestTransfer(Json payload) async {
    await _record.record('backup:${DateTime.now().microsecondsSinceEpoch}').put(
      database,
      {
        'owner': owner,
        'payload': cloneJson(payload),
        'reason': 'guest-before-sign-in',
      },
    );
  }
}
