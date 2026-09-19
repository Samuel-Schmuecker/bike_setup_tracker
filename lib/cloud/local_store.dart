import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'sync_documents.dart';
import 'erase_images.dart';
import 'guest_import.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> bindOwner(String uid, {bool? anonymous}) => mutate((state) {
    if (state['owner'] != null && state['owner'] != uid) {
      throw StateError('Account switch requires an explicit workspace switch');
    }
    state['owner'] = uid;
    if (anonymous != null) state['anonymousOwner'] = anonymous;
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

  /// Erase this account's snapshots; retain workspaces of other accounts.
  Future<void> eraseAccount(String uid) {
    final result = _queue.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      final removedImages = <String>{};
      final retainedImages = <String>{};
      void collect(Object? value, Set<String> paths) {
        if (value is Map) {
          if (value['imagePath'] is String) {
            paths.add(value['imagePath'] as String);
          }
          for (final child in value.values) {
            collect(child, paths);
          }
        } else if (value is List) {
          for (final child in value) {
            collect(child, paths);
          }
        }
      }

      for (final row in await _record.find(database)) {
        collect(
          row.value,
          row.value['owner'] == uid ? removedImages : retainedImages,
        );
      }
      await eraseAccountImages(removedImages.difference(retainedImages));
      // Old migration copies have no reliable owner. Remove them to prevent resurrection.
      for (final key in ['bikes_data', 'custom_field_catalog']) {
        if (!await preferences.remove(key)) {
          throw StateError('LOCAL_ERASURE_FAILED');
        }
      }
      late Json next;
      await database.transaction((txn) async {
        final persisted = await _record.record('active').get(txn);
        if (persisted?['localRevision'] != _state['localRevision'] ||
            owner != uid) {
          throw StateError('Another tab changed the data. Reload first.');
        }
        for (final row in await _record.find(txn)) {
          if (row.value['owner'] == uid || row.key == 'legacy-backup') {
            await _record.record(row.key).delete(txn);
          }
        }
        next = {
          'version': 1,
          'owner': null,
          'payload': {'bikes': [], 'catalog': []},
          'base': {},
          'initialized': true,
          'cloudPaused': true,
          'localRevision': (_state['localRevision'] as int? ?? 0) + 1,
        };
        await _record.record('active').put(txn, next);
      });
      _state = next;
      notifyListeners();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

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

  /// Finish a redirect in one transaction so restart/retry cannot duplicate a transfer.
  Future<void> finishGoogleLogin(String uid) {
    final result = _queue.then((_) async {
      final intent = _state['googleIntent'] as Map?;
      if (intent == null) return;
      if (intent['sourceOwner'] != owner) {
        throw StateError('GOOGLE_OWNER_CHANGED');
      }
      if (intent['kind'] == 'link' && uid != owner) {
        throw StateError('GOOGLE_LINK_MISMATCH');
      }
      Json? next;
      await database.transaction((txn) async {
        final persisted = await _record.record('active').get(txn);
        if (persisted?['localRevision'] != _state['localRevision']) {
          throw StateError('Another tab changed the workspace. Reload first.');
        }
        if (uid == owner) {
          next = cloneJson(_state);
        } else {
          final previous = cloneJson(_state)..remove('googleIntent');
          await _record
              .record('account:${owner ?? 'local'}')
              .put(txn, previous);
          final saved = await _record.record('account:$uid').get(txn);
          next = saved == null
              ? {
                  'version': 1,
                  'owner': uid,
                  'payload': {'bikes': [], 'catalog': []},
                  'base': {},
                  'initialized': true,
                }
              : Map<String, dynamic>.from(saved);
          if (intent['sourceAnonymous'] == true) {
            await _record.record('backup:${intent['createdAt']}').put(txn, {
              'owner': uid,
              'payload': previous['payload'],
              'reason': 'guest-before-google-login',
            });
            if (intent['guestTicket'] is String && previous['owner'] != null) {
              next!['guestCleanup'] = {
                'ticket': intent['guestTicket'],
                'source': previous['owner'],
                'backupKey': 'backup:${intent['createdAt']}',
                'mode': intent['guestChoice'],
              };
              if (intent['guestChoice'] == 'import') {
                final guest = guestImportPayload(previous['payload'] as Json);
                final ids = <String, String>{};
                void collect(Object? value) {
                  if (value is Map) {
                    final id = value['id'];
                    if (id is String &&
                        !{'fork', 'shock', 'tires'}.contains(id)) {
                      ids.putIfAbsent(id, () => const Uuid().v4());
                    }
                    value.values.forEach(collect);
                  } else if (value is List) {
                    value.forEach(collect);
                  }
                }

                collect(guest);
                Object? remap(Object? value) {
                  if (value is String) return ids[value] ?? value;
                  if (value is List) return value.map(remap).toList();
                  if (value is Map) {
                    return {
                      for (final e in value.entries)
                        ids[e.key] ?? e.key: remap(e.value),
                    };
                  }
                  return value;
                }

                final imported = remap(guest) as Map;
                for (final field in ['bikes', 'catalog']) {
                  (next!['payload'][field] as List).addAll(
                    imported[field] as List,
                  );
                }
                next!['editVersion'] = (next!['editVersion'] as int? ?? 0) + 1;
              }
            }
          }
        }
        next!.remove('googleIntent');
        next!['anonymousOwner'] = false;
        next!['localRevision'] = (_state['localRevision'] as int? ?? 0) + 1;
        await _record.record('active').put(txn, next!);
      });
      _state = next!;
      notifyListeners();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  Future<void> finishGuestCleanup() {
    final result = _queue.then((_) async {
      final cleanup = _state['guestCleanup'] as Map?;
      if (cleanup == null) return;
      final removedImages = <String>{};
      final retainedImages = <String>{};
      void collect(Object? value, Set<String> paths) {
        if (value is Map) {
          if (value['imagePath'] is String) {
            paths.add(value['imagePath'] as String);
          }
          for (final child in value.values) {
            collect(child, paths);
          }
        } else if (value is List) {
          for (final child in value) {
            collect(child, paths);
          }
        }
      }

      final rows = await _record.find(database);
      bool remove(RecordSnapshot<String, Json> row) =>
          row.value['owner'] == cleanup['source'] ||
          row.key == cleanup['backupKey'] ||
          row.key == 'legacy-backup';
      for (final row in rows) {
        collect(row.value, remove(row) ? removedImages : retainedImages);
      }
      await eraseAccountImages(removedImages.difference(retainedImages));
      final preferences = await SharedPreferences.getInstance();
      for (final key in ['bikes_data', 'custom_field_catalog']) {
        if (!await preferences.remove(key)) {
          throw StateError('LOCAL_ERASURE_FAILED');
        }
      }
      final next = cloneJson(_state)..remove('guestCleanup');
      await database.transaction((txn) async {
        final persisted = await _record.record('active').get(txn);
        if (persisted?['localRevision'] != _state['localRevision']) {
          throw StateError('Reload before cleanup');
        }
        for (final row in rows.where(remove)) {
          await _record.record(row.key).delete(txn);
        }
        next['localRevision'] = (_state['localRevision'] as int? ?? 0) + 1;
        await _record.record('active').put(txn, next);
      });
      _state = next;
      notifyListeners();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }
}
