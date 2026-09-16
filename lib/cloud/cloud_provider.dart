import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/bike_provider.dart';
import 'cloud_config.dart';
import 'image_bytes.dart';
import 'local_store.dart';
import 'sync_documents.dart';
import 'oauth_return.dart';
import 'google_auth_error.dart';

class CloudProvider extends ChangeNotifier with WidgetsBindingObserver {
  CloudProvider(
    this.store,
    this.bikes, {
    SupabaseClient? client,
    bool startAutomatically = true,
  }) : _client = client {
    WidgetsBinding.instance.addObserver(this);
    store.addListener(_localChanged);
    bikes.addListener(_bikeStatusChanged);
    if (startAutomatically) {
      _timer = Timer.periodic(const Duration(seconds: 45), (_) => sync());
      unawaited(sync());
    }
  }
  final LocalStore store;
  final BikeProvider bikes;
  SupabaseClient? _client;
  Timer? _timer;
  Timer? _debounce;
  StreamSubscription<AuthState>? _authEvents;
  OAuthReturn? _oauthReturn;
  String? googleIssue;
  bool get googlePending => store.state['googleIntent'] != null;
  bool get googleLinked => _hasGoogle(user);
  bool _hasGoogle(User? value) =>
      value != null &&
      ((value.identities?.any((identity) => identity.provider == 'google') ??
              false) ||
          (value.appMetadata['providers'] as List? ?? []).contains('google'));
  bool busy = false;
  bool accountOperation = false;
  bool _disposed = false;
  String status = 'pending';
  Object? lastError;
  StackTrace? lastErrorStack;
  final Map<String, Json> conflicts = {};
  Json? _observedPayload;
  final Map<String, String> _uploaded = {};
  final Map<String, String> _downloaded = {};
  User? get user => _client?.auth.currentUser;
  bool get anonymous => user?.isAnonymous ?? true;
  String? get email => user?.email;
  bool get canSync => bikes.storageError == null;
  bool get cloudPaused => store.state['cloudPaused'] == true;
  bool get deletionPending => store.state['deletionPending'] == true;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _bikeStatusChanged() {
    if (!canSync) {
      status = 'local';
      _emit();
    }
  }

  void _localChanged() {
    final current = store.payload;
    if (sameJson(current, _observedPayload)) return;
    _observedPayload = current;
    status = 'pending';
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), sync);
    _emit();
  }

  Future<SupabaseClient> _ensureClient() async {
    if (_client != null) return _client!;
    await Supabase.initialize(
      url: CloudConfig.url,
      publishableKey: CloudConfig.key,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _client = Supabase.instance.client;
    _authEvents = _client!.auth.onAuthStateChange.listen(
      (_) {
        _emit();
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 1), sync);
      },
      onError: (Object error) {
        if (googlePending) googleIssue = googleAuthErrorCode(error);
        status = 'session';
        _emit();
      },
    );
    return _client!;
  }

  Future<void> _identity(SupabaseClient client) async {
    await _resumeGoogle(client);
    if (client.auth.currentSession == null) {
      if (store.owner != null) throw StateError('SESSION_MISSING');
      await client.auth.signInAnonymously();
    }
    final uid = client.auth.currentUser!.id;
    if (store.owner != null && store.owner != uid) {
      throw StateError('SESSION_MISSING');
    }
    await store.bindOwner(uid, anonymous: user!.isAnonymous);
  }

  String _errorStatus(Object error) {
    if (error.toString().contains('GOOGLE_')) return 'google';
    if (error is PostgrestException &&
        error.message.contains('SYNC_CONFLICT')) {
      return 'retry';
    }
    if (error is PostgrestException &&
        ['42P01', '42501', 'PGRST202', 'PGRST205'].contains(error.code)) {
      return 'setup';
    }
    if (error is AuthException) return 'auth';
    if (error.toString().contains('SESSION_MISSING')) return 'session';
    return 'offline';
  }

  Future<void> sync() async {
    if (busy || _disposed) return;
    if (cloudPaused || deletionPending) {
      status = cloudPaused ? 'paused' : 'deleting';
      _emit();
      return;
    }
    busy = true;
    lastError = null;
    status = 'syncing';
    _emit();
    try {
      await bikes.ready;
      await store.flush();
      if (!canSync) await bikes.saveToDevice();
      if (!canSync) throw StateError('LOCAL_SAVE_FAILED');
      final client = await _ensureClient();
      await _identity(client);
      final uid = user!.id;
      if (store.owner != uid) throw StateError('SESSION_MISSING');
      // OAuth can replace the session while image/network work is awaiting.
      // Pin document requests to this pass's account, especially the UID-based RPC.
      final authorization = 'Bearer ${client.auth.currentSession!.accessToken}';
      final remote = <String, Json>{};
      for (var start = 0; ; start += 500) {
        final rows = await client
            .from('bike_documents')
            .select()
            .eq('user_id', uid)
            .order('document_id')
            .range(start, start + 499)
            .setHeader('Authorization', authorization);
        for (final row in rows) {
          remote[row['document_id'] as String] = row;
        }
        if (rows.length < 500) break;
      }
      conflicts.clear();
      final snapshot = store.state;
      final local = documentsFromPayload(snapshot['payload'] as Json);
      final base = snapshot['base'] as Json;
      // Apply order last, once all downloaded bikes exist locally.
      final keys = {...local.keys, ...base.keys, ...remote.keys}.toList()
        ..sort(
          (a, b) => a == 'order'
              ? 1
              : b == 'order'
              ? -1
              : a.compareTo(b),
        );
      for (final key in keys) {
        if (_disposed || user?.id != uid) return;
        final captured = local[key];
        final portable = await _toCloud(key, captured, uid);
        final baseline = base[key] as Map?;
        final row = remote[key];
        final action = decideSync(
          _documentValue(key, baseline?['payload']),
          portable,
          _documentValue(key, row?['payload']),
        );
        if (action == SyncAction.conflict) {
          conflicts[key] = row ?? {'revision': 0, 'payload': null};
          continue;
        }
        Json? accepted = row;
        Object? downloaded;
        if (action == SyncAction.upload) {
          accepted = Map<String, dynamic>.from(
            await client
                    .rpc(
                      'save_bike_document',
                      params: {
                        'p_document_id': key,
                        'p_expected_revision': baseline?['revision'] ?? 0,
                        'p_payload': portable,
                      },
                    )
                    .setHeader('Authorization', authorization)
                as Map,
          );
        } else if (action == SyncAction.download) {
          downloaded = await _fromCloud(key, row?['payload'], uid);
        }
        // Never replace an edit made while the network request was in flight.
        if (user?.id != uid) throw StateError('SESSION_MISSING');
        var applied = false;
        await store.mutate((state) {
          if (state['owner'] != uid) throw StateError('SESSION_MISSING');
          final current = documentsFromPayload(state['payload'] as Json);
          if (action == SyncAction.download) {
            if (!sameJson(current[key], captured) &&
                !(key == 'order' &&
                    state['editVersion'] == snapshot['editVersion'])) {
              return;
            }
            current[key] = downloaded;
            state['payload'] = payloadFromDocuments(current);
            applied = true;
          }
          (state['base'] as Json)[key] = {
            'revision': accepted?['revision'] ?? 0,
            'payload': _documentValue(key, accepted?['payload']),
          };
        });
        if (applied) bikes.applyStoredPayload();
      }
      // A fresh comparison catches edits queued during this pass.
      final end = store.state;
      final docs = documentsFromPayload(end['payload'] as Json);
      var pending = false;
      for (final key in {...docs.keys, ...(end['base'] as Json).keys}) {
        final portable = await _toCloud(key, docs[key], uid);
        if (!sameJson(
          portable,
          _documentValue(key, (end['base'][key] as Map?)?['payload']),
        )) {
          pending = true;
        }
      }
      status = conflicts.isNotEmpty
          ? 'conflict'
          : pending
          ? 'pending'
          : 'synced';
      if (status == 'synced') {
        await store.mutate(
          (state) =>
              state['lastSync'] = DateTime.now().toUtc().toIso8601String(),
        );
      }
      if (googlePending && status == 'synced') status = 'google_waiting';
    } catch (error, stack) {
      lastError = error;
      lastErrorStack = stack;
      status = !canSync ? 'local' : _errorStatus(error);
    } finally {
      busy = false;
      _emit();
    }
  }

  Object? _documentValue(String key, Object? value) =>
      value ?? (key == 'library' || key == 'order' ? <dynamic>[] : null);

  Future<Object?> _toCloud(String key, Object? value, String uid) async {
    if (!key.startsWith('bike:') || value == null) return value;
    final bike = cloneJson(value as Json);
    final path = bike['imagePath'] as String?;
    if (path == null || path.isEmpty || path.startsWith('assets/')) return bike;
    final cacheKey = '$uid:$path';
    var object = _uploaded[cacheKey];
    if (object == null) {
      final bytes = path.startsWith('data:')
          ? Uint8List.fromList(UriData.parse(path).contentAsBytes())
          : await readLocalImage(path);
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Image exceeds 5 MB');
      }
      final hash = sha256.convert(bytes).toString();
      object = '$uid/$hash';
      final savedImage =
          ((store.state['base'] as Json)[key] as Map?)?['payload'];
      if (savedImage is Map && savedImage['imagePath'] == 'cloud:$object') {
        _uploaded[cacheKey] = object;
        bike['imagePath'] = 'cloud:$object';
        return bike;
      }
      final mime = path.startsWith('data:')
          ? UriData.parse(path).mimeType
          : 'image/jpeg';
      try {
        await _client!.storage
            .from('bike-images')
            .uploadBinary(
              object,
              bytes,
              fileOptions: FileOptions(contentType: mime, upsert: false),
            );
      } on StorageException catch (error) {
        if (error.statusCode != '409' && error.statusCode != '400') rethrow;
        // Verify a suspected duplicate; a permission/format error is not success.
        final stored = await _client!.storage
            .from('bike-images')
            .download(object);
        if (sha256.convert(stored).toString() != hash) rethrow;
      }
      _uploaded[cacheKey] = object;
    }
    bike['imagePath'] = 'cloud:$object';
    return bike;
  }

  Future<Object?> _fromCloud(String key, Object? value, String uid) async {
    if (!key.startsWith('bike:') || value == null) return value;
    final bike = cloneJson(Map<String, dynamic>.from(value as Map));
    final path = bike['imagePath'] as String?;
    if (path != null && path.startsWith('cloud:')) {
      final object = path.substring(6);
      if (!object.startsWith('$uid/')) {
        throw const FormatException('Invalid image owner');
      }
      var data = _downloaded[object];
      if (data == null) {
        final bytes = await _client!.storage
            .from('bike-images')
            .download(object);
        if (sha256.convert(bytes).toString() != object.split('/').last) {
          throw const FormatException('Image integrity check failed');
        }
        data = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _downloaded[object] = data;
      }
      bike['imagePath'] = data;
      _uploaded['$uid:$data'] = object;
    }
    return bike;
  }

  Future<void> _auth(Future<void> Function(SupabaseClient) work) async {
    if (deletionPending || cloudPaused) {
      throw StateError('ACCOUNT_DELETION_PENDING');
    }
    if (busy) throw StateError('Please wait for the current operation');
    busy = true;
    accountOperation = true;
    _emit();
    try {
      await bikes.ready;
      await store.flush();
      if (!canSync) {
        throw StateError('Local data must be saved before switching accounts');
      }
      await work(await _ensureClient());
    } finally {
      busy = false;
      accountOperation = false;
      _emit();
    }
    unawaited(sync());
  }

  Future<void> linkEmail(String email) => _auth((client) async {
    await _identity(client);
    await client.auth.updateUser(UserAttributes(email: email.trim()));
  });

  Future<void> startGoogle({required bool link}) => _auth((client) async {
    googleIssue = null;
    if (link) {
      // Resolve any old attempt before starting a new one.
      await store.mutate((state) => state.remove('googleIntent'));
      await _identity(client);
      if (googleLinked) return;
    }
    await _oauthReturn?.close();
    final attempt = const Uuid().v4();
    _oauthReturn = await OAuthReturn.open(attempt, (uri) async {
      try {
        await client.auth.getSessionFromUrl(uri);
        await sync();
      } catch (error) {
        googleIssue = googleAuthErrorCode(error);
        _emit();
        rethrow;
      }
    });
    await store.backup('before-google');
    await store.mutate(
      (state) => state['googleIntent'] = {
        'id': attempt,
        'kind': link ? 'link' : 'login',
        'sourceOwner': state['owner'],
        'sourceAnonymous':
            state['owner'] == null ||
            state['anonymousOwner'] == true ||
            (anonymous && user?.id == state['owner']),
        'createdAt': DateTime.now().microsecondsSinceEpoch,
      },
    );
    try {
      final redirect = _oauthReturn!.redirect;
      final response = link
          ? await client.auth.getLinkIdentityUrl(
              OAuthProvider.google,
              redirectTo: redirect,
              queryParams: {'prompt': 'select_account'},
            )
          : await client.auth.getOAuthSignInUrl(
              provider: OAuthProvider.google,
              redirectTo: redirect,
              queryParams: {'prompt': 'select_account'},
            );
      final opened = await launchUrl(
        Uri.parse(response.url),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );
      if (!opened) throw StateError('GOOGLE_BROWSER_FAILED');
    } catch (_) {
      await _oauthReturn?.close();
      await store.mutate((state) => state.remove('googleIntent'));
      rethrow;
    }
  });

  Future<void> _resumeGoogle(SupabaseClient client) async {
    final intent = store.state['googleIntent'] as Map?;
    if (intent == null) return;
    final created = DateTime.fromMicrosecondsSinceEpoch(
      intent['createdAt'] as int,
    );
    if (DateTime.now().difference(created) > const Duration(minutes: 15)) {
      throw StateError('GOOGLE_EXPIRED');
    }
    if (user == null || anonymous || !_hasGoogle(user)) return;
    final verified = (await client.auth.getUser()).user;
    if (verified == null || verified.isAnonymous || !_hasGoogle(verified)) {
      return;
    }
    accountOperation = true;
    _emit();
    try {
      await store.finishGoogleLogin(verified.id);
      conflicts.clear();
      bikes.applyStoredPayload();
      googleIssue = null;
    } finally {
      accountOperation = false;
      _emit();
    }
  }

  Future<void> cancelGoogle() async {
    if (busy) return;
    await _oauthReturn?.close();
    await store.mutate((state) => state.remove('googleIntent'));
    googleIssue = null;
    _emit();
    await sync();
  }

  Future<void> confirmEmail(String email, String code, String password) =>
      _auth((client) async {
        final uid = user!.id;
        await client.auth.verifyOTP(
          email: email.trim(),
          token: code.trim(),
          type: OtpType.emailChange,
        );
        if (user?.id != uid) throw StateError('Unexpected account change');
        await client.auth.updateUser(UserAttributes(password: password));
      });

  Future<void> updatePassword(String password) => _auth((client) async {
    if (anonymous) throw StateError('Verify your email first');
    await client.auth.updateUser(UserAttributes(password: password));
  });

  Future<void> signIn(
    String email,
    String password, {
    required bool importGuest,
  }) => _auth((client) async {
    final oldOwner = store.owner;
    final guestWorkspace = anonymous ? store.payload : null;
    final guest = importGuest ? await exportBackup() : null;
    await store.backup('before-sign-in');
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (user!.id != oldOwner) {
      await store.switchOwner(user!.id);
      if (guestWorkspace != null) await store.saveGuestTransfer(guestWorkspace);
      conflicts.clear();
      if (guest != null) await importBackup(guest);
      bikes.applyStoredPayload();
    }
  });

  Future<void> signOut() => _auth((client) async {
    if (anonymous) throw StateError('Link Google before signing out');
    await store.backup('before-sign-out');
    await client.auth.signOut(scope: SignOutScope.local);
    await store.switchOwner(null);
    conflicts.clear();
    bikes.applyStoredPayload();
  });

  Future<void> deleteAccount() async {
    if (busy) throw StateError('Please wait for the current operation');
    busy = true;
    accountOperation = true;
    _emit();
    try {
      await bikes.ready;
      await store.flush();
      final uid = store.owner;
      if (uid == null) throw StateError('SESSION_MISSING');
      final client = await _ensureClient();
      if (store.state['deletionCloudDone'] != true) {
        if (client.auth.currentUser?.id != uid) {
          throw StateError('SESSION_MISSING');
        }
        await store.mutate((state) {
          state['deletionPending'] = true;
          state.remove('googleIntent');
        });
        await _oauthReturn?.close();
        final response = await client.functions.invoke(
          'delete-account',
          body: {'confirm': 'DELETE'},
        );
        if (response.data is! Map || response.data['deleted'] != true) {
          throw StateError(
            'Löschung noch nicht abgeschlossen. Bitte erneut versuchen.',
          );
        }
        await store.mutate((state) => state['deletionCloudDone'] = true);
      }
      // Keep a durable completion marker if local sign-out or erasure fails.
      await client.auth.signOut(scope: SignOutScope.local);
      await store.eraseAccount(uid);
      conflicts.clear();
      _uploaded.clear();
      _downloaded.clear();
      googleIssue = null;
      bikes.applyStoredPayload();
      status = 'paused';
    } finally {
      busy = false;
      accountOperation = false;
      _emit();
    }
  }

  Future<void> resumeAfterDeletion() async {
    if (!cloudPaused || busy) return;
    busy = true;
    _emit();
    try {
      // Prepare the first-run experience before remounting the home screen.
      await bikes.restoreDemoAfterDeletion();
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setBool('hasSeenOnboarding', false)) {
        throw StateError('LOCAL_SAVE_FAILED');
      }
      await store.mutate((state) => state.remove('cloudPaused'));
    } finally {
      busy = false;
      _emit();
    }
    await sync();
  }

  Future<void> sendRecovery(String email) => _auth((client) async {
    await client.auth.resetPasswordForEmail(email.trim());
  });

  Future<void> recover(String email, String code, String password) =>
      _auth((client) async {
        await store.backup('before-password-recovery');
        await client.auth.verifyOTP(
          email: email.trim(),
          token: code.trim(),
          type: OtpType.recovery,
        );
        if (store.owner != user!.id) {
          await store.switchOwner(user!.id);
          bikes.applyStoredPayload();
        }
        await client.auth.updateUser(UserAttributes(password: password));
      });

  Future<Json> exportBackup() async {
    await store.flush();
    // Preserve even a user edit whose disk write failed.
    return _portableBackup(bikes.exportPayload);
  }

  Future<Json> _portableBackup(Json payload) async {
    final result = cloneJson(payload);
    for (final bike in result['bikes'] as List) {
      final path = bike['imagePath'] as String?;
      if (path != null &&
          path.isNotEmpty &&
          !path.startsWith('assets/') &&
          !path.startsWith('data:')) {
        bike['imagePath'] =
            'data:image/jpeg;base64,${base64Encode(await readLocalImage(path))}';
      }
    }
    return {'format': 'bike-setup-tracker', 'version': 1, ...result};
  }

  Future<void> restoreLocalWorkspace(Json workspace) async {
    await importBackup(
      await _portableBackup(
        Map<String, dynamic>.from(workspace['payload'] as Map),
      ),
    );
  }

  Future<void> importBackup(Json backup) async {
    if (backup['format'] != 'bike-setup-tracker' || backup['version'] != 1) {
      throw const FormatException('Unsupported backup format');
    }
    validatePayload(backup);
    for (final bike in backup['bikes'] as List) {
      final path = bike['imagePath'];
      if (path != null &&
          path != '' &&
          !(path is String &&
              (path.startsWith('assets/images/') ||
                  path.startsWith('data:image/')))) {
        throw const FormatException('Backup images must be embedded');
      }
    }
    await store.backup('before-import');
    // Imports are explicitly copies; custom IDs are remapped together with all references.
    final replacements = <String, String>{};
    void collect(Object? value) {
      if (value is Map) {
        final id = value['id'];
        if (id is String && !{'fork', 'shock', 'tires'}.contains(id)) {
          replacements.putIfAbsent(id, () => const Uuid().v4());
        }
        value.values.forEach(collect);
      } else if (value is List) {
        value.forEach(collect);
      }
    }

    collect(backup);
    Object? remap(Object? value) {
      if (value is String) return replacements[value] ?? value;
      if (value is List) return value.map(remap).toList();
      if (value is Map) {
        return {
          for (final entry in value.entries)
            replacements[entry.key] ?? entry.key: remap(entry.value),
        };
      }
      return value;
    }

    final imported = Map<String, dynamic>.from(remap(backup) as Map);
    await store.mutate((state) {
      final current = state['payload'] as Json;
      (current['bikes'] as List).addAll(imported['bikes'] as List);
      (current['catalog'] as List).addAll(imported['catalog'] as List);
      state['editVersion'] = (state['editVersion'] as int? ?? 0) + 1;
      state.remove('lastSync');
    });
    bikes.applyStoredPayload();
  }

  Future<void> resolveConflict(String key, {required bool keepLocal}) =>
      _auth((client) async {
        final conflict = conflicts[key];
        if (conflict == null) return;
        final remote = await _fromCloud(key, conflict['payload'], user!.id);
        await store.backup('before-conflict-resolution:$key');
        await store.mutate((state) {
          (state['base'] as Json)[key] = {
            'revision': conflict['revision'],
            'payload': conflict['payload'],
          };
          if (!keepLocal) {
            final docs = documentsFromPayload(state['payload'] as Json);
            docs[key] = remote;
            state['payload'] = payloadFromDocuments(docs);
          }
          state.remove('lastSync');
        });
        bikes.applyStoredPayload();
        conflicts.remove(key);
      });

  Future<void> keepBoth(String key, String suffix) => _auth((client) async {
    if (!key.startsWith('bike:') || !conflicts.containsKey(key)) return;
    final conflict = conflicts[key]!;
    final remote = await _fromCloud(key, conflict['payload'], user!.id);
    await store.backup('before-keeping-both:$key');
    await store.mutate((state) {
      final docs = documentsFromPayload(state['payload'] as Json);
      final local = docs[key];
      if (local is Map) {
        final copy = cloneJson(Map<String, dynamic>.from(local));
        copy['id'] = const Uuid().v4();
        copy['model'] = '${copy['model']} ($suffix)';
        docs['bike:${copy['id']}'] = copy;
      }
      docs[key] = remote;
      state['payload'] = payloadFromDocuments(docs);
      (state['base'] as Json)[key] = {
        'revision': conflict['revision'],
        'payload': conflict['payload'],
      };
      state.remove('lastSync');
    });
    conflicts.remove(key);
    bikes.applyStoredPayload();
  });

  Future<List<Json>> history() async {
    final client = await _ensureClient();
    return await client
        .from('bike_document_history')
        .select()
        .eq('user_id', user!.id)
        .order('saved_at', ascending: false)
        .limit(100);
  }

  Future<void> restoreVersion(Json row) => _auth((client) async {
    final key = row['document_id'] as String;
    if (row['payload'] == null) return;
    final restored = await _fromCloud(key, row['payload'], user!.id);
    await store.backup('before-version-restore');
    await store.mutate((state) {
      final docs = documentsFromPayload(state['payload'] as Json);
      docs[key] = restored;
      state['payload'] = payloadFromDocuments(docs);
      state.remove('lastSync');
    });
    bikes.applyStoredPayload();
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(sync());
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _debounce?.cancel();
    _authEvents?.cancel();
    _oauthReturn?.close();
    store.removeListener(_localChanged);
    bikes.removeListener(_bikeStatusChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
