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
import '../providers/theme_provider.dart';
import 'cloud_config.dart';
import 'image_bytes.dart';
import 'local_store.dart';
import 'sync_documents.dart';
import 'oauth_return.dart';
import 'google_auth_error.dart';
import 'guest_import.dart';

class CloudProvider extends ChangeNotifier with WidgetsBindingObserver {
  CloudProvider(
    this.store,
    this.bikes, {
    SupabaseClient? client,
    bool startAutomatically = true,
    bool cloudEnabled = true,
    this.theme,
  }) : _client = client,
       _cloudEnabled = cloudEnabled {
    WidgetsBinding.instance.addObserver(this);
    store.addListener(_localChanged);
    bikes.addListener(_bikeStatusChanged);
    if (startAutomatically && _cloudEnabled) startSync();
  }
  bool _cloudEnabled;

  /// Called after onboarding has been confirmed and saved locally.
  void startSync() {
    if (_disposed) return;
    _cloudEnabled = true;
    _timer ??= Timer.periodic(const Duration(seconds: 45), (_) => sync());
    unawaited(sync());
  }

  final LocalStore store;
  final BikeProvider bikes;
  final ThemeProvider? theme;
  SupabaseClient? _client;
  Timer? _timer;
  Timer? _debounce;
  StreamSubscription<AuthState>? _authEvents;
  OAuthReturn? _oauthReturn;
  String? googleIssue;
  bool get googlePending => store.state['googleIntent'] != null;
  bool get googleLinked => !sessionUnavailable && _hasGoogle(user);
  bool sessionUnavailable = false;

  bool _invalidSession(Object error) =>
      error is AuthException &&
      {
        'user_not_found',
        'session_not_found',
        'refresh_token_not_found',
        'refresh_token_already_used',
        'bad_jwt',
        'session_expired',
      }.contains(error.code);
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
  bool _imageDownloadFailed = false;
  final Map<String, Json> conflicts = {};
  Json? _observedPayload;
  final Map<String, String> _uploaded = {};
  final Map<String, String> _downloaded = {};
  User? get user => _client?.auth.currentUser;
  bool get anonymous => user?.isAnonymous ?? true;

  /// Only suggest linking a known guest account. A missing user can mean that
  /// a saved session is still being restored, especially on another device.
  bool get shouldSuggestAccountBackup =>
      user != null &&
      anonymous &&
      !googleLinked &&
      !googlePending &&
      !busy &&
      !accountOperation &&
      !sessionUnavailable &&
      !cloudPaused &&
      !deletionPending;
  String? get email => user?.email;
  bool get canSync => bikes.storageError == null;
  bool get cloudPaused => store.state['cloudPaused'] == true;
  bool get deletionPending => store.state['deletionPending'] == true;
  bool get guestCleanupPending => store.state['guestCleanup'] != null;
  String? guestCleanupError;

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
    if (!_cloudEnabled) return;
    final current = store.payload;
    if (sameJson(current, _observedPayload)) return;
    _observedPayload = current;
    status = 'pending';
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), sync);
    _emit();
  }

  Future<SupabaseClient> _ensureClient() async {
    if (!_cloudEnabled) throw StateError('ONBOARDING_NOT_COMPLETED');
    if (_client != null) return _client!;
    if (kIsWeb && googlePending) {
      googleIssue = googleAuthCallbackError(Uri.base) ?? googleIssue;
    }
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
        if (_invalidSession(error)) sessionUnavailable = true;
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
      if (store.owner != null) {
        sessionUnavailable = true;
        throw StateError('SESSION_MISSING');
      }
      await client.auth.signInAnonymously();
    }
    // A cached JWT can outlive a user deleted through the Supabase dashboard.
    // Verify before comparing cloud data, so an empty response cannot erase local bikes.
    try {
      final verified = (await client.auth.getUser()).user;
      if (verified == null) {
        throw const AuthException('User missing', code: 'user_not_found');
      }
    } catch (error) {
      if (_invalidSession(error)) sessionUnavailable = true;
      rethrow;
    }
    final uid = client.auth.currentUser!.id;
    if (store.owner != null && store.owner != uid) {
      sessionUnavailable = true;
      throw StateError('SESSION_MISSING');
    }
    sessionUnavailable = false;
    await store.bindOwner(uid, anonymous: user!.isAnonymous);
  }

  String _errorStatus(Object error) {
    if (_invalidSession(error)) return 'session';
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
    if (!_cloudEnabled || busy || _disposed) return;
    if (cloudPaused || deletionPending) {
      status = cloudPaused ? 'paused' : 'deleting';
      _emit();
      return;
    }
    busy = true;
    lastError = null;
    _imageDownloadFailed = false;
    status = 'syncing';
    _emit();
    try {
      await bikes.ready;
      await store.flush();
      if (!canSync) await bikes.saveToDevice();
      if (!canSync) throw StateError('LOCAL_SAVE_FAILED');
      final client = await _ensureClient();
      await _identity(client);
      if (store.state['googleIntent']?['guestTicket'] != null && anonymous) {
        status = 'google_waiting';
        return;
      }
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
        if (_disposed) return;
        if (user?.id != uid) throw StateError('SESSION_MISSING');
        try {
          final captured = local[key];
          final baseline = base[key] as Map?;
          final row = remote[key];
          final portable = await _toCloud(
            key,
            captured,
            uid,
            remoteValue: row?['payload'],
          );
          // Only an explicit tombstone means deletion. A missing row must not
          // silently erase a previously synchronized local bike.
          if (row == null && (baseline?['revision'] as num? ?? 0) > 0) {
            throw StateError('REMOTE_DOCUMENT_MISSING');
          }
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
          final hydrateImage =
              captured is Map &&
              (captured['imagePath'] as String? ?? '').startsWith('cloud:');
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
          }
          if (action == SyncAction.download || hydrateImage) {
            downloaded = await _fromCloud(
              key,
              accepted?['payload'],
              uid,
              allowUnavailableImage: true,
            );
          }
          // Never replace an edit made while the network request was in flight.
          if (user?.id != uid) throw StateError('SESSION_MISSING');
          var applied = false;
          await store.mutate((state) {
            if (state['owner'] != uid) throw StateError('SESSION_MISSING');
            final current = documentsFromPayload(state['payload'] as Json);
            if (action == SyncAction.download || hydrateImage) {
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
        } catch (error, stack) {
          if (user?.id != uid || _invalidSession(error)) rethrow;
          lastError ??= error;
          lastErrorStack = stack;
          if (error.toString().contains('IMAGE_UPLOAD_REQUIRED') ||
              error.toString().contains('IMAGE_RETIRED')) {
            _uploaded.clear();
          }
        }
      }
      // A fresh comparison catches edits queued during this pass.
      final end = store.state;
      final docs = documentsFromPayload(end['payload'] as Json);
      var pending = false;
      for (final key in {...docs.keys, ...(end['base'] as Json).keys}) {
        try {
          final portable = await _toCloud(key, docs[key], uid);
          if (!sameJson(
            portable,
            _documentValue(key, (end['base'][key] as Map?)?['payload']),
          )) {
            pending = true;
          }
        } catch (error, stack) {
          pending = true;
          lastError ??= error;
          lastErrorStack = stack;
        }
      }
      status = conflicts.isNotEmpty
          ? 'conflict'
          : lastError != null
          ? (_imageDownloadFailed ? 'images' : _errorStatus(lastError!))
          : pending
          ? 'pending'
          : 'synced';
      if (status == 'synced' || status == 'images') {
        // Retry server-side cleanup after offline deletions, restarts or a
        // lost response. The server checks references across all devices.
        try {
          if (user?.id != uid) throw StateError('SESSION_MISSING');
          final result = await client.functions.invoke(
            CloudConfig.imageCleanupFunction,
            headers: {'Authorization': authorization},
          );
          if (result.data is! Map || result.data['complete'] != true) {
            throw StateError('IMAGE_CLEANUP_PENDING');
          }
          _uploaded.clear();
          _downloaded.clear();
        } catch (error, stack) {
          lastError = error;
          lastErrorStack = stack;
          // Cleanup is maintenance, but must not hide missing image downloads.
          if (status == 'synced') status = 'cleanup';
        }
      }
      if (status == 'synced') {
        await store.mutate(
          (state) =>
              state['lastSync'] = DateTime.now().toUtc().toIso8601String(),
        );
      }
      if (googlePending && status == 'synced') status = 'google_waiting';
      // Target data is fully synchronized in either state. Unrelated image
      // maintenance must not prevent completing an already prepared transfer.
      if ((status == 'synced' || status == 'cleanup') && guestCleanupPending) {
        try {
          final response = await client.functions.invoke(
            'delete-account',
            body: {
              'action': 'finish_guest',
              'confirm': 'DELETE',
              'ticket': store.state['guestCleanup']['ticket'],
            },
          );
          if (response.data is! Map || response.data['deleted'] != true) {
            throw StateError('GUEST_CLEANUP_PENDING');
          }
          await store.finishGuestCleanup();
          _uploaded.clear();
          _downloaded.clear();
          guestCleanupError = null;
        } catch (_) {
          guestCleanupError = 'guest_cleanup_pending';
        }
      }
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

  Future<Object?> _toCloud(
    String key,
    Object? value,
    String uid, {
    Object? remoteValue,
  }) async {
    if (!key.startsWith('bike:') || value == null) return value;
    final bike = cloneJson(value as Json);
    final path = bike['imagePath'] as String?;
    if (path == null || path.isEmpty || path.startsWith('assets/')) return bike;
    if (path.startsWith('cloud:')) {
      if (!path.startsWith('cloud:$uid/')) {
        throw const FormatException('Invalid image owner');
      }
      return bike;
    }
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
      // A retired object name is never reused: a delayed cleanup request must
      // not delete a newly uploaded copy of the same photograph.
      object = '$uid/${const Uuid().v4()}/$hash';
      final savedImage =
          ((store.state['base'] as Json)[key] as Map?)?['payload'];
      // A previous write can have committed before its response was lost.
      // Reuse the fetched cloud reference after restart to avoid a false conflict.
      for (final candidate in [remoteValue, savedImage]) {
        final savedPath = candidate is Map ? candidate['imagePath'] : null;
        if (savedPath is String &&
            savedPath.startsWith('cloud:$uid/') &&
            savedPath.split('/').last == hash) {
          _uploaded[cacheKey] = savedPath.substring(6);
          bike['imagePath'] = savedPath;
          return bike;
        }
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

  Future<Object?> _fromCloud(
    String key,
    Object? value,
    String uid, {
    bool allowUnavailableImage = false,
  }) async {
    if (!key.startsWith('bike:') || value == null) return value;
    final bike = cloneJson(Map<String, dynamic>.from(value as Map));
    final path = bike['imagePath'] as String?;
    if (path != null && path.startsWith('cloud:')) {
      try {
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
      } catch (error, stack) {
        if (!allowUnavailableImage) rethrow;
        // Keep both the bike and its image reference. Retry the photo on the
        // next sync instead of hiding the bike or uploading an empty image.
        _imageDownloadFailed = true;
        lastError ??= error;
        lastErrorStack = stack;
      }
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
    } catch (error) {
      if (_invalidSession(error) ||
          error.toString().contains('SESSION_MISSING')) {
        sessionUnavailable = true;
        status = 'session';
      }
      rethrow;
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

  /// Explicit recovery only: never recreate an administratively deleted account silently.
  Future<void> reconnectLocalData() => _auth((client) async {
    if (guestCleanupPending) {
      throw StateError('Gastkonto-Bereinigung zuerst prüfen.');
    }
    if (client.auth.currentSession != null) {
      try {
        await _identity(client);
        return;
      } catch (error) {
        if (!_invalidSession(error) &&
            !error.toString().contains('SESSION_MISSING')) {
          rethrow;
        }
      }
    }
    await store.backup('before-session-recovery');
    await client.auth.signOut(scope: SignOutScope.local);
    await store.mutate((state) {
      state['owner'] = null;
      state['base'] = <String, dynamic>{};
      state['anonymousOwner'] = true;
      state.remove('googleIntent');
      state.remove('lastSync');
    });
    _uploaded.clear();
    _downloaded.clear();
    conflicts.clear();
    googleIssue = null;
    sessionUnavailable = false;
    await _identity(client);
  });

  Future<void> startGoogle({required bool link, String? guestChoice}) async {
    if (guestCleanupPending) {
      throw StateError('Gastkonto-Bereinigung zuerst abschließen.');
    }
    if (!link && anonymous && store.owner != null) {
      if (!{'import', 'discard'}.contains(guestChoice)) {
        throw StateError('Choose what to do with guest data');
      }
      await sync();
      // Old image cleanup does not affect the synchronized guest documents.
      // The transfer endpoint still validates their revisions before switching.
      if (status != 'synced' && status != 'cleanup') {
        throw StateError(
          'Gastdaten zuerst vollständig synchronisieren und Konflikte lösen.',
        );
      }
    }
    await _auth((client) async {
      googleIssue = null;
      if (link) {
        // Resolve any old attempt before starting a new one.
        await store.mutate((state) => state.remove('googleIntent'));
        await _identity(client);
        if (googleLinked) return;
      }
      await _oauthReturn?.close();
      final attempt = const Uuid().v4();
      final languageCode =
          (await SharedPreferences.getInstance()).getString('app_lang') ?? 'de';
      _oauthReturn = await OAuthReturn.open(attempt, (uri) async {
        try {
          final callbackError = googleAuthCallbackError(uri);
          if (callbackError != null) {
            throw AuthException('Google sign-in failed', code: callbackError);
          }
          await client.auth.getSessionFromUrl(uri);
          await sync();
        } catch (error) {
          googleIssue = googleAuthErrorCode(error);
          _emit();
          rethrow;
        }
      }, languageCode: languageCode);
      try {
        await store.backup('before-google');
        String? guestTicket;
        if (!link &&
            anonymous &&
            user?.id == store.owner &&
            store.owner != null) {
          final response = await client.functions.invoke(
            'delete-account',
            body: {
              'action': 'prepare_guest',
              'revisions': {
                for (final entry in (store.state['base'] as Map).entries)
                  if ((entry.value['revision'] as num) > 0)
                    entry.key: entry.value['revision'],
              },
            },
          );
          if (response.data is! Map || response.data['ticket'] is! String) {
            throw StateError('Gastwechsel konnte nicht vorbereitet werden.');
          }
          guestTicket = response.data['ticket'] as String;
        }
        await store.mutate(
          (state) => state['googleIntent'] = {
            'id': attempt,
            'kind': link ? 'link' : 'login',
            'guestTicket': guestTicket,
            'guestChoice': guestChoice,
            'sourceOwner': state['owner'],
            'sourceAnonymous':
                state['owner'] == null ||
                state['anonymousOwner'] == true ||
                (anonymous && user?.id == state['owner']),
            'createdAt': DateTime.now().microsecondsSinceEpoch,
          },
        );
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
      } catch (error) {
        googleIssue = googleAuthErrorCode(error);
        await _oauthReturn?.close();
        await store.mutate((state) => state.remove('googleIntent'));
        rethrow;
      }
    });
  }

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
    final guest = importGuest ? guestImportPayload(await exportBackup()) : null;
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
    if (guestCleanupPending) {
      throw StateError('Gastkonto-Bereinigung zuerst abschließen.');
    }
    if (anonymous) throw StateError('Link Google before signing out');
    await store.backup('before-sign-out');
    await client.auth.signOut(scope: SignOutScope.local);
    await store.switchOwner(null);
    conflicts.clear();
    bikes.applyStoredPayload();
  });

  Future<void> deleteAccount() async {
    if (guestCleanupPending) {
      throw StateError('Gastkonto-Bereinigung zuerst abschließen.');
    }
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
      await _resetAppearance();
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
      await _resetAppearance();
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

  Future<void> _resetAppearance() async {
    final currentTheme = theme;
    if (currentTheme != null) {
      await currentTheme.reset();
    } else {
      final temporaryTheme = ThemeProvider(
        await SharedPreferences.getInstance(),
      );
      try {
        await temporaryTheme.reset();
      } finally {
        temporaryTheme.dispose();
      }
    }
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
      if (path != null && path.startsWith('cloud:')) {
        final resolved = await _fromCloud(
          'bike:${bike['id']}',
          bike,
          store.owner!,
        );
        bike['imagePath'] = (resolved as Map)['imagePath'];
      } else if (path != null &&
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
