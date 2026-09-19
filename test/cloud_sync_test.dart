import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bike_setup_tracker/cloud/cloud_provider.dart';
import 'package:bike_setup_tracker/cloud/local_store.dart';
import 'package:bike_setup_tracker/cloud/sync_documents.dart';
import 'package:bike_setup_tracker/data/demo_bikes.dart';
import 'package:crypto/crypto.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Json bike(String id, [String model = 'Original']) => Bike(
  id: id,
  brand: 'Test',
  model: model,
  category: 'Trail',
  travelFront: 140,
  travelRear: 130,
).toMap();

class FakeCloud {
  final rows = <String, Json>{};
  final images = <String, List<int>>{};
  final history = <String, List<Json>>{};
  final retiredImages = <String>{};
  bool failImageCleanup = false;
  int imageCleanupCalls = 0;
  Completer<void>? uploadStarted;
  Completer<void>? releaseUpload;
  Completer<void>? imageDownloadStarted;
  Completer<void>? releaseImageDownload;
  bool failNextUploadResponse = false;
  bool anonymousAuth = false;
  bool passwordUpdated = false;
  bool googleAuth = false;
  String authId = 'user-1';
  String authEmail = 'test@example.com';
  int uploads = 0;
  bool failDeletion = false;
  int deletionCalls = 0;
  int guestDeletionCalls = 0;
  bool failGuestDeletion = false;
  bool failGuestPreparation = false;
  int guestPreparationCalls = 0;
  int signupCalls = 0;
  int requests = 0;
  final deletedUsers = <String>{};
  bool userLookupOffline = false;
  String signupUserId = 'user-1';
  final documentAuthorizations = <String?>[];
  late final client = SupabaseClient(
    'https://test.supabase.co',
    'public-test-key',
    // The fake returns tokens directly; Flutter supplies PKCE storage in production.
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    httpClient: MockClient(handle),
  );

  Future<http.Response> handle(http.Request request) async {
    requests++;
    http.Response json(Object? value, [int code = 200]) => http.Response(
      jsonEncode(value),
      code,
      headers: {'content-type': 'application/json'},
      request: request,
    );
    final path = request.url.path;
    if (path == '/functions/v1/super-function') {
      imageCleanupCalls++;
      if (failImageCleanup) return json({'error': 'image_delete_failed'}, 500);
      final candidates = <String>{};
      for (final entry in history.entries) {
        if (rows[entry.key]?['payload'] != null) continue;
        for (final old in entry.value) {
          final image = old.remove('imagePath');
          if (image is String && image.startsWith('cloud:')) {
            candidates.add(image.substring(6));
          }
        }
      }
      final retained = <Object?>{
        for (final row in rows.values)
          if (row['payload'] is Map) row['payload']['imagePath'],
        for (final versions in history.values)
          for (final old in versions) old['imagePath'],
      };
      for (final name in candidates) {
        if (!retained.contains('cloud:$name')) {
          images.remove(name);
          retiredImages.add(name);
        }
      }
      return json({'complete': true});
    }
    if (path == '/functions/v1/delete-account') {
      final body = jsonDecode(request.body) as Map;
      if (body['action'] == 'finish_guest') {
        guestDeletionCalls++;
        if (failGuestDeletion) return json({'error': 'guest_changed'}, 409);
        return json({'deleted': true});
      }
      if (body['action'] == 'prepare_guest') {
        guestPreparationCalls++;
        if (failGuestPreparation) {
          return json({'error': 'guest_changed_or_setup_missing'}, 409);
        }
        return json({'ticket': 'guest-ticket'});
      }
      deletionCalls++;
      if (failDeletion) return json({'error': 'image_delete_failed'}, 500);
      rows.clear();
      images.clear();
      return json({'deleted': true});
    }
    Json authUser(String id) => {
      'id': id,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': authEmail,
      'is_anonymous': anonymousAuth,
      'app_metadata': {
        'providers': googleAuth ? ['google'] : ['email'],
      },
      'user_metadata': {},
      'created_at': '2026-09-15T00:00:00Z',
    };
    if (path == '/auth/v1/user') {
      if (request.method == 'GET') {
        if (userLookupOffline) throw http.ClientException('Offline');
        if (deletedUsers.contains(authId))
          return json({
            'error_code': 'user_not_found',
            'msg': 'User from sub claim in JWT does not exist',
          }, 403);
        return json(authUser(authId));
      }
      final body = jsonDecode(request.body) as Map;
      if (body['email'] != null) authEmail = body['email'] as String;
      if (body['password'] != null) passwordUpdated = true;
      return json(authUser('user-1'));
    }
    if (path.startsWith('/storage/v1/object/')) {
      final key = path.substring(
        path.indexOf('bike-images/') + 'bike-images/'.length,
      );
      if (request.method == 'POST') {
        if (images.containsKey(key)) {
          return json({'message': 'Already exists', 'statusCode': '409'}, 409);
        }
        final contentType = request.headers['content-type'] ?? '';
        if (contentType.startsWith('multipart/form-data')) {
          final boundary = contentType.split('boundary=').last;
          final part = latin1
              .decode(request.bodyBytes)
              .split('--$boundary')
              .firstWhere((part) => part.contains('filename='));
          images[key] = latin1.encode(
            part.substring(part.indexOf('\r\n\r\n') + 4, part.length - 2),
          );
        } else {
          images[key] = request.bodyBytes;
        }
        return json({'Key': 'bike-images/$key'});
      }
      if (images.containsKey(key)) {
        if (imageDownloadStarted != null) {
          if (!imageDownloadStarted!.isCompleted) {
            imageDownloadStarted!.complete();
          }
          await releaseImageDownload!.future;
        }
        return http.Response.bytes(images[key]!, 200, request: request);
      }
      return json({'message': 'Missing image', 'statusCode': '404'}, 404);
    }
    if (path == '/auth/v1/token' ||
        path == '/auth/v1/signup' ||
        path == '/auth/v1/verify') {
      if (path == '/auth/v1/signup') {
        signupCalls++;
        anonymousAuth = true;
      }
      if (path == '/auth/v1/verify') anonymousAuth = false;
      final userId = path == '/auth/v1/signup'
          ? signupUserId
          : (jsonDecode(request.body) as Map)['email'] == 'second@example.com'
          ? 'user-2'
          : 'user-1';
      authId = userId;
      return json({
        'access_token': 'test-token-$userId',
        'refresh_token': 'refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': authUser(userId),
      });
    }
    if (path == '/rest/v1/bike_documents') return json(rows.values.toList());
    if (path == '/rest/v1/rpc/save_bike_document') {
      documentAuthorizations.add(request.headers['authorization']);
      final body = jsonDecode(request.body) as Map;
      final key = body['p_document_id'] as String;
      uploads++;
      if (key.startsWith('bike:') && uploadStarted != null) {
        if (!uploadStarted!.isCompleted) uploadStarted!.complete();
        await releaseUpload!.future;
      }
      final old = rows[key];
      if (old != null && sameJson(old['payload'], body['p_payload'])) {
        return json(old);
      }
      if ((old?['revision'] ?? 0) != body['p_expected_revision']) {
        return json({'message': 'SYNC_CONFLICT', 'code': 'P0001'}, 409);
      }
      final image = body['p_payload'] is Map
          ? body['p_payload']['imagePath']
          : null;
      if (image is String &&
          image.startsWith('cloud:') &&
          retiredImages.contains(image.substring(6))) {
        return json({'message': 'IMAGE_RETIRED', 'code': 'P0001'}, 409);
      }
      if (old?['payload'] is Map) {
        history
            .putIfAbsent(key, () => [])
            .add(cloneJson(old!['payload'] as Json));
      }
      rows[key] = {
        'document_id': key,
        'revision': (old?['revision'] as int? ?? 0) + 1,
        'payload': body['p_payload'],
      };
      if (failNextUploadResponse && key.startsWith('bike:')) {
        failNextUploadResponse = false;
        throw http.ClientException('Connection lost after commit');
      }
      return json(rows[key]);
    }
    if (path == '/auth/v1/logout') return json({});
    return json({'message': 'Unexpected request: $path'}, 400);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStore store;
  late BikeProvider bikes;
  late FakeCloud server;
  late CloudProvider cloud;
  late ThemeProvider theme;

  Future<void> initialize([List<Json> initial = const []]) async {
    SharedPreferences.setMockInitialValues({
      'bikes_data': jsonEncode(initial),
      'custom_field_catalog': '[]',
    });
    final db = await newDatabaseFactoryMemory().openDatabase('test');
    store = LocalStore(db);
    await store.initialize(await SharedPreferences.getInstance());
    bikes = BikeProvider(localStore: store);
    await bikes.ready;
    server = FakeCloud();
    await server.client.auth.signInWithPassword(
      email: 'test@example.com',
      password: 'testpassword',
    );
    theme = ThemeProvider(await SharedPreferences.getInstance());
    cloud = CloudProvider(
      store,
      bikes,
      client: server.client,
      theme: theme,
      startAutomatically: false,
    );
    addTearDown(() async {
      cloud.dispose();
      theme.dispose();
      bikes.dispose();
      store.dispose();
      await server.client.dispose();
      await db.close();
    });
  }

  test(
    'onboarding blocks all sync triggers until explicitly started',
    () async {
      await initialize();
      cloud.dispose();
      await server.client.auth.signOut();
      cloud = CloudProvider(
        store,
        bikes,
        client: server.client,
        cloudEnabled: false,
      );
      final requestsBefore = server.requests;
      await cloud.sync();
      cloud.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await store.savePayload({
        'bikes': [bike('before-onboarding')],
        'catalog': [],
      });
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(server.requests, requestsBefore);
      expect(server.signupCalls, 0);
      expect(store.owner, isNull);

      final completed = Completer<void>();
      cloud.addListener(() {
        if (!cloud.busy && !completed.isCompleted) completed.complete();
      });
      cloud.startSync();
      await completed.future.timeout(const Duration(seconds: 5));
      expect(server.signupCalls, 1);
      expect(store.owner, 'user-1');
      expect(server.rows, contains('bike:before-onboarding'));
    },
  );

  test(
    'sync decision preserves concurrent edits and delete/edit conflicts',
    () {
      expect(decideSync({'a': 1}, {'a': 2}, {'a': 3}), SyncAction.conflict);
      expect(decideSync({'a': 1}, null, {'a': 2}), SyncAction.conflict);
      expect(decideSync({'a': 1}, {'a': 1}, null), SyncAction.download);
      expect(decideSync(null, {'a': 1}, {'a': 1}), SyncAction.unchanged);
      expect(sameJson({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isTrue);
    },
  );

  test(
    'OAuth session change during upload never applies another account',
    () async {
      await initialize([bike('guest')]);
      server.uploadStarted = Completer<void>();
      server.releaseUpload = Completer<void>();
      final pass = cloud.sync();
      await server.uploadStarted!.future;
      await server.client.auth.signInWithPassword(
        email: 'second@example.com',
        password: 'testpassword',
      );
      server.releaseUpload!.complete();
      await pass;
      expect(
        server.documentAuthorizations,
        everyElement('Bearer test-token-user-1'),
      );
      expect(store.owner, 'user-1');
      expect(store.state['base'], isEmpty);
      expect(cloud.status, 'session');
    },
  );

  test(
    'deletion erases local account backups and prevents automatic guest creation',
    () async {
      await initialize([bike('delete-me')]);
      await cloud.sync();
      await store.backup('before-test');
      await theme.setBackground(const Color(0xFFFFFFFF));
      await theme.setAccent(const Color(0xFFAA00FF));
      await cloud.deleteAccount();
      expect(theme.background, ThemeProvider.defaultBackground);
      expect(theme.accent.toARGB32(), ThemeProvider.defaultAccent.toARGB32());
      final restoredTheme = ThemeProvider(
        await SharedPreferences.getInstance(),
      );
      expect(restoredTheme.background, ThemeProvider.defaultBackground);
      expect(
        restoredTheme.accent.toARGB32(),
        ThemeProvider.defaultAccent.toARGB32(),
      );
      restoredTheme.dispose();
      expect(cloud.cloudPaused, isTrue);
      expect(store.payload['bikes'], isEmpty);
      expect(await store.savedWorkspaces(), isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString('bikes_data'),
        isNull,
      );
      expect(server.deletionCalls, 1);
      await cloud.sync();
      expect(server.signupCalls, 0);
      final reopened = LocalStore(store.database);
      await reopened.initialize(await SharedPreferences.getInstance());
      expect(reopened.state['cloudPaused'], isTrue);
      reopened.dispose();
      await cloud.resumeAfterDeletion();
      expect(server.signupCalls, 1);
      expect(bikes.bikes.single.model, 'Supreme V5');
      expect((store.payload['bikes'] as List).single['model'], 'Supreme V5');
      expect(
        (await SharedPreferences.getInstance()).getBool('hasSeenOnboarding'),
        isFalse,
      );
      await cloud.resumeAfterDeletion();
      expect(bikes.bikes.length, 1);
      expect(server.signupCalls, 1);
    },
  );

  test(
    'failed deletion retains local data, blocks sync and allows retry',
    () async {
      await initialize([bike('keep-until-success')]);
      await cloud.sync();
      server.failDeletion = true;
      await theme.setAccent(const Color(0xFFAA00FF));
      await expectLater(
        cloud.deleteAccount(),
        throwsA(isA<FunctionException>()),
      );
      expect(cloud.deletionPending, isTrue);
      expect(theme.accent, const Color(0xFFAA00FF));
      expect((store.payload['bikes'] as List).length, 1);
      final uploads = server.uploads;
      await cloud.sync();
      expect(server.uploads, uploads);
      await expectLater(cloud.signOut(), throwsStateError);
      server.failDeletion = false;
      await cloud.deleteAccount();
      expect(cloud.cloudPaused, isTrue);
    },
  );

  test('existing bikes upload; legacy preferences remain untouched', () async {
    await initialize([bike('old-id')]);
    final raw = (await SharedPreferences.getInstance()).getString('bikes_data');
    await cloud.sync();
    expect(
      cloud.status,
      'synced',
      reason: '${cloud.lastError}\n${cloud.lastErrorStack}',
    );
    expect(server.rows['bike:old-id']!['payload']['model'], 'Original');
    expect(
      (await SharedPreferences.getInstance()).getString('bikes_data'),
      raw,
    );
    expect(store.owner, 'user-1');
  });

  test(
    'new device downloads bikes and remote order without a false conflict',
    () async {
      await initialize();
      server.rows.addAll({
        'bike:a': {
          'document_id': 'bike:a',
          'revision': 2,
          'payload': bike('a'),
        },
        'bike:b': {
          'document_id': 'bike:b',
          'revision': 1,
          'payload': bike('b'),
        },
        'order': {
          'document_id': 'order',
          'revision': 3,
          'payload': ['b', 'a'],
        },
      });
      await cloud.sync();
      expect(cloud.status, 'synced');
      expect(bikes.bikes.map((b) => b.id), ['b', 'a']);
      expect(server.uploads, 0);
    },
  );

  test(
    'edits during upload remain pending and are sent on the next pass',
    () async {
      await initialize([bike('a')]);
      server.uploadStarted = Completer<void>();
      server.releaseUpload = Completer<void>();
      final syncing = cloud.sync();
      await server.uploadStarted!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw StateError('Upload not reached: ${cloud.lastError}');
        },
      );
      bikes.updateBike(
        bikes.bikes.single.copyWith(model: 'Edited during upload'),
      );
      await store.flush();
      server.releaseUpload!.complete();
      await syncing;
      expect(bikes.bikes.single.model, 'Edited during upload');
      expect(cloud.status, 'pending');
      await cloud.sync();
      expect(
        server.rows['bike:a']!['payload']['model'],
        'Edited during upload',
      );
      expect(cloud.status, 'synced');
    },
  );

  test(
    'lost response after commit retries without duplicating records',
    () async {
      await initialize([bike('a')]);
      server.failNextUploadResponse = true;
      await cloud.sync();
      expect(cloud.status, 'offline');
      await cloud.sync();
      expect(cloud.status, 'synced');
      expect(server.rows['bike:a']!['revision'], 1);
      expect(bikes.bikes.length, 1);
    },
  );

  test(
    'concurrent edits block overwrite; keeping both preserves both bikes',
    () async {
      await initialize([bike('a')]);
      await cloud.sync();
      bikes.updateBike(bikes.bikes.single.copyWith(model: 'Local change'));
      await store.flush();
      server.rows['bike:a'] = {
        'document_id': 'bike:a',
        'revision': 2,
        'payload': bike('a', 'Remote change'),
      };
      await cloud.sync();
      expect(cloud.status, 'conflict');
      expect(server.rows['bike:a']!['payload']['model'], 'Remote change');
      await cloud.keepBoth('bike:a', 'copy');
      // The resolution triggers a background sync; wait for it to finish.
      while (cloud.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(
        bikes.bikes.map((b) => b.model),
        containsAll(['Remote change', 'Local change (copy)']),
      );
      expect((await store.savedWorkspaces()).length, greaterThan(0));
    },
  );

  test(
    'deletions create tombstones and do not resurrect on the next sync',
    () async {
      await initialize([bike('a')]);
      await cloud.sync();
      bikes.deleteBike('a');
      await store.flush();
      await cloud.sync();
      expect(server.rows['bike:a']!['payload'], isNull);
      await cloud.sync();
      expect(bikes.bikes, isEmpty);
      expect(cloud.status, 'synced');
    },
  );

  test(
    'account switch archives the previous workspace and restores it independently',
    () async {
      await initialize([bike('a')]);
      await store.bindOwner('user-1');
      await store.switchOwner('user-2');
      expect(store.payload['bikes'], isEmpty);
      await store.savePayload({
        'bikes': [bike('b')],
        'catalog': [],
      });
      await store.switchOwner('user-1');
      expect((store.payload['bikes'] as List).single['id'], 'a');
      expect(store.owner, 'user-1');
    },
  );

  test(
    'import rejects file paths and duplicate IDs before changing local data',
    () async {
      await initialize([bike('a')]);
      await expectLater(
        cloud.importBackup({
          'format': 'bike-setup-tracker',
          'version': 1,
          'bikes': [
            {...bike('b'), 'imagePath': 'C:/private/file.txt'},
          ],
          'catalog': [],
        }),
        throwsFormatException,
      );
      await expectLater(
        cloud.importBackup({
          'format': 'bike-setup-tracker',
          'version': 1,
          'bikes': [bike('b'), bike('b')],
          'catalog': [],
        }),
        throwsFormatException,
      );
      expect(bikes.bikes.single.id, 'a');
    },
  );

  test('corrupt legacy data is retained and migration fails closed', () async {
    SharedPreferences.setMockInitialValues({'bikes_data': '{broken-json'});
    final db = await newDatabaseFactoryMemory().openDatabase('broken');
    final broken = LocalStore(db);
    final prefs = await SharedPreferences.getInstance();
    await expectLater(broken.initialize(prefs), throwsFormatException);
    expect(prefs.getString('bikes_data'), '{broken-json');
    await db.close();
    broken.dispose();
  });

  test('photos upload privately and restore as offline image data', () async {
    const photo =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=';
    await initialize([
      {...bike('a'), 'imagePath': photo},
    ]);
    await cloud.sync();
    expect(cloud.status, 'synced', reason: '${cloud.lastError}');
    expect(server.images.length, 1);
    expect(
      server.rows['bike:a']!['payload']['imagePath'],
      startsWith('cloud:user-1/'),
    );
    // Simulate a fresh local workspace on the second device.
    await store.mutate((state) {
      state['payload'] = {'bikes': [], 'catalog': []};
      state['base'] = {};
    });
    bikes.applyStoredPayload();
    await cloud.sync();
    expect(cloud.status, 'synced', reason: '${cloud.lastError}');
    expect(
      UriData.parse(bikes.bikes.single.imagePath!).contentAsBytes(),
      UriData.parse(photo).contentAsBytes(),
    );
  });

  Future<void> googleIntent(String kind, {bool sourceAnonymous = true}) =>
      store.mutate((state) {
        state['googleIntent'] = {
          'id': 'attempt-1',
          'kind': kind,
          'sourceOwner': state['owner'],
          'sourceAnonymous': sourceAnonymous,
          'createdAt': DateTime.now().microsecondsSinceEpoch,
        };
      });

  test(
    'failed Google preparation releases callback and preserves guest data',
    () async {
      await initialize([bike('guest')]);
      server.anonymousAuth = true;
      await server.client.auth.signInAnonymously();
      await cloud.sync();
      expect(cloud.status, 'synced');
      server.failGuestPreparation = true;

      await expectLater(
        cloud.startGoogle(link: false, guestChoice: 'import'),
        throwsA(isA<FunctionException>()),
      );

      expect(cloud.googleIssue, isNotNull);
      expect(cloud.googlePending, isFalse);
      expect(cloud.busy, isFalse);
      expect(bikes.bikes.single.id, 'guest');
      expect(server.deletionCalls, 0);
      expect(server.guestDeletionCalls, 0);
      final listener = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        43827,
      );
      await listener.close(force: true);
    },
  );

  const photo = 'data:image/png;base64,AQIDBA==';

  test(
    'image cleanup failure does not block Google guest preparation',
    () async {
      await initialize([bike('guest')]);
      await server.client.auth.signInAnonymously();
      await cloud.sync();
      server.failImageCleanup = true;
      // Stop at the transfer endpoint instead of opening a real browser.
      server.failGuestPreparation = true;
      await expectLater(
        cloud.startGoogle(link: false, guestChoice: 'import'),
        throwsA(isA<FunctionException>()),
      );
      expect(cloud.status, 'cleanup');
      expect(server.guestPreparationCalls, 1);
      expect(bikes.bikes.single.id, 'guest');
    },
  );

  test('cleanup failure cannot mask missing images and permit login', () async {
    await initialize([bike('guest')]);
    await server.client.auth.signInAnonymously();
    await cloud.sync();
    server.rows['bike:guest']!['payload']['imagePath'] =
        'cloud:user-1/missing.jpg';
    server.rows['bike:guest']!['revision'] = 2;
    server.failImageCleanup = true;
    await expectLater(
      cloud.startGoogle(link: false, guestChoice: 'import'),
      throwsStateError,
    );
    expect(cloud.status, 'images');
    expect(server.guestPreparationCalls, 0);
    expect(bikes.bikes.single.id, 'guest');
  });

  test(
    'photo upload with lost document response survives restart without a duplicate or conflict',
    () async {
      await initialize([
        {...bike('a'), 'imagePath': photo},
      ]);
      server.failNextUploadResponse = true;
      await cloud.sync();
      final name = server.images.keys.single;
      cloud.dispose();
      cloud = CloudProvider(
        store,
        bikes,
        client: server.client,
        startAutomatically: false,
      );
      await cloud.sync();
      expect(cloud.status, 'synced', reason: '${cloud.lastError}');
      expect(cloud.conflicts, isEmpty);
      expect(server.images.keys.toList(), [name]);
      expect(server.rows['bike:a']!['revision'], 1);
    },
  );

  test(
    'missing photo retains bike, loads following bikes and retries photo',
    () async {
      await initialize();
      final bytes = UriData.parse(photo).contentAsBytes();
      final name = 'user-1/${sha256.convert(bytes)}';
      server.rows['bike:a'] = {
        'document_id': 'bike:a',
        'revision': 1,
        'payload': {...bike('a'), 'imagePath': 'cloud:$name'},
      };
      server.rows['bike:b'] = {
        'document_id': 'bike:b',
        'revision': 1,
        'payload': bike('b'),
      };
      await cloud.sync();
      expect(bikes.bikes.map((bike) => bike.id), containsAll(['a', 'b']));
      expect(cloud.status, 'images');
      expect(
        bikes.bikes.firstWhere((bike) => bike.id == 'a').imagePath,
        'cloud:$name',
      );
      expect(server.rows['bike:a']!['revision'], 1);
      // Retain the unresolved reference across an application restart.
      cloud.dispose();
      cloud = CloudProvider(
        store,
        bikes,
        client: server.client,
        startAutomatically: false,
      );
      server.images[name] = bytes;
      await cloud.sync();
      expect(cloud.status, 'synced', reason: '${cloud.lastError}');
      expect(
        UriData.parse(
          bikes.bikes.firstWhere((bike) => bike.id == 'a').imagePath!,
        ).contentAsBytes(),
        bytes,
      );
      expect(server.rows['bike:a']!['revision'], 1);
    },
  );

  test('absent remote row cannot silently delete a synced bike', () async {
    await initialize([bike('a')]);
    await cloud.sync();
    server.rows.remove('bike:a');
    await cloud.sync();
    expect(bikes.bikes.single.id, 'a');
    expect(cloud.lastError.toString(), contains('REMOTE_DOCUMENT_MISSING'));
    expect(store.state['base']['bike:a']['revision'], 1);
  });

  test('photo retry cannot overwrite an edit made during download', () async {
    await initialize();
    final bytes = UriData.parse(photo).contentAsBytes();
    final name = 'user-1/${sha256.convert(bytes)}';
    server.rows['bike:a'] = {
      'document_id': 'bike:a',
      'revision': 1,
      'payload': {...bike('a'), 'imagePath': 'cloud:$name'},
    };
    await cloud.sync();
    server.images[name] = bytes;
    server.imageDownloadStarted = Completer<void>();
    server.releaseImageDownload = Completer<void>();
    final retry = cloud.sync();
    await server.imageDownloadStarted!.future;
    bikes.updateBike(
      bikes.bikes.single.copyWith(model: 'Edited while loading'),
    );
    await store.flush();
    server.releaseImageDownload!.complete();
    await retry;
    expect(bikes.bikes.single.model, 'Edited while loading');
    await cloud.sync();
    expect(server.rows['bike:a']!['payload']['model'], 'Edited while loading');
    expect(bikes.bikes.single.imagePath, startsWith('data:image/'));
    expect(cloud.status, 'synced', reason: '${cloud.lastError}');
  });

  test(
    'unreadable local photo does not stop other cloud bikes from loading',
    () async {
      await initialize([
        {...bike('a'), 'imagePath': 'missing-directory/photo.jpg'},
      ]);
      server.rows['bike:z'] = {
        'document_id': 'bike:z',
        'revision': 1,
        'payload': bike('z'),
      };
      await cloud.sync();
      expect(bikes.bikes.map((bike) => bike.id), containsAll(['a', 'z']));
      expect(cloud.lastError, isNotNull);
      expect(server.rows['bike:a'], isNull);
    },
  );

  test(
    'delete photo retries after failure and survives provider restart',
    () async {
      await initialize([
        {...bike('a'), 'imagePath': photo},
      ]);
      await cloud.sync();
      expect(server.images, hasLength(1));
      bikes.deleteBike('a');
      server.failImageCleanup = true;
      await cloud.sync();
      expect(server.rows['bike:a']!['payload'], isNull);
      expect(server.images, hasLength(1));
      expect(cloud.status, 'cleanup');
      cloud.dispose();
      cloud = CloudProvider(
        store,
        bikes,
        client: server.client,
        startAutomatically: false,
      );
      server.failImageCleanup = false;
      await cloud.sync();
      expect(cloud.status, 'synced', reason: '${cloud.lastError}');
      expect(server.images, isEmpty);
      expect(server.history['bike:a']!.single['imagePath'], isNull);
      expect(bikes.bikes, isEmpty);
    },
  );

  test(
    'shared photo survives first deletion; reimport uses a fresh object',
    () async {
      await initialize([
        {...bike('a'), 'imagePath': photo},
        {...bike('b'), 'imagePath': photo},
      ]);
      await cloud.sync();
      final oldName = server.images.keys.single;
      bikes.deleteBike('a');
      await cloud.sync();
      expect(server.images, hasLength(1));
      bikes.deleteBike('b');
      await cloud.sync();
      expect(server.images, isEmpty);
      bikes.addBike(Bike.fromMap({...bike('c'), 'imagePath': photo}));
      await cloud.sync();
      expect(cloud.status, 'synced', reason: '${cloud.lastError}');
      expect(server.images.keys.single, isNot(oldName));
    },
  );

  test(
    'Google guest import omits untouched demo but preserves custom bikes',
    () async {
      await initialize([createDemoBikes().single.toMap(), bike('own')]);
      await cloud.sync();
      await googleIntent('login');
      await store.mutate((state) {
        state['googleIntent']['guestTicket'] = 'guest-ticket';
        state['googleIntent']['guestChoice'] = 'import';
      });
      server.googleAuth = true;
      await server.client.auth.signInWithPassword(
        email: 'second@example.com',
        password: 'password',
      );
      server.rows.clear();
      server.rows['bike:3'] = {
        'document_id': 'bike:3',
        'revision': 1,
        'payload': createDemoBikes().single.toMap(),
      };
      await cloud.sync();
      // A second pass includes the newly downloaded bike in the shared order.
      await cloud.sync();
      expect(cloud.status, 'synced', reason: '${cloud.lastError}');
      expect(bikes.bikes, hasLength(2));
      expect(
        bikes.bikes.where((bike) => bike.model == 'Supreme V5'),
        hasLength(1),
      );
      expect(bikes.bikes.where((bike) => bike.brand == 'Test'), hasLength(1));
      await cloud.sync();
      expect(bikes.bikes, hasLength(2));
    },
  );

  test(
    'anonymous email upgrade keeps ownership and existing cloud documents',
    () async {
      await initialize([bike('a')]);
      await server.client.auth.signOut();
      await server.client.auth.signInAnonymously();
      await cloud.sync();
      expect(cloud.anonymous, isTrue);
      final uid = cloud.user!.id;
      final revision = server.rows['bike:a']!['revision'];
      await cloud.linkEmail('linked@example.com');
      while (cloud.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await cloud.confirmEmail('linked@example.com', '123456', 'longpassword');
      while (cloud.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(cloud.user!.id, uid);
      expect(store.owner, uid);
      expect(cloud.anonymous, isFalse);
      expect(server.passwordUpdated, isTrue);
      expect(server.rows['bike:a']!['revision'], revision);
    },
  );

  test('local backup list does not expose another account', () async {
    await initialize([bike('private')]);
    await store.bindOwner('user-1');
    await store.backup('private account backup');
    await store.switchOwner('user-2');
    expect(await store.savedWorkspaces(), isEmpty);
    await store.switchOwner('user-1');
    expect(await store.savedWorkspaces(), isNotEmpty);
  });

  test(
    'Google linking preserves UID, bikes and cloud revision after redirect',
    () async {
      await initialize([bike('a')]);
      await cloud.sync();
      final revision = server.rows['bike:a']!['revision'];
      await googleIntent('link');
      server.googleAuth = true;
      await server.client.auth.signInWithPassword(
        email: 'test@example.com',
        password: 'password',
      );
      await cloud.sync();
      expect(cloud.status, 'synced', reason: '${cloud.lastError}');
      expect(cloud.googleLinked, isTrue);
      expect(store.owner, 'user-1');
      expect(bikes.bikes.single.id, 'a');
      expect(server.rows['bike:a']!['revision'], revision);
      expect(store.state['googleIntent'], isNull);
    },
  );

  test(
    'Google login switches account and archives guest data exactly once',
    () async {
      await initialize([bike('guest')]);
      await cloud.sync();
      await googleIntent('login');
      server.googleAuth = true;
      await server.client.auth.signInWithPassword(
        email: 'second@example.com',
        password: 'password',
      );
      server.rows.clear();
      server.rows['bike:existing'] = {
        'document_id': 'bike:existing',
        'revision': 1,
        'payload': bike('existing'),
      };
      await cloud.sync();
      expect(store.owner, 'user-2');
      expect(bikes.bikes.single.id, 'existing');
      final backups = await store.savedWorkspaces();
      expect(backups.length, 1);
      expect(
        (backups.single['payload']['bikes'] as List).single['id'],
        'guest',
      );
      await cloud.sync();
      expect((await store.savedWorkspaces()).length, 1);
      expect(server.rows.containsKey('bike:guest'), isFalse);
    },
  );

  Future<void> switchGuestWithChoice(String choice) async {
    await initialize([bike('guest')]);
    await cloud.sync();
    await googleIntent('login');
    await store.mutate((state) {
      state['googleIntent']['guestTicket'] = 'guest-ticket';
      state['googleIntent']['guestChoice'] = choice;
    });
    server.googleAuth = true;
    await server.client.auth.signInWithPassword(
      email: 'second@example.com',
      password: 'password',
    );
    server.rows.clear();
  }

  test(
    'guest import uploads copies before cleanup, retry does not duplicate',
    () async {
      await switchGuestWithChoice('import');
      server.failNextUploadResponse = true;
      await cloud.sync();
      expect(server.guestDeletionCalls, 0);
      expect(cloud.guestCleanupPending, isTrue);
      final copiedId = bikes.bikes.single.id;
      expect(copiedId, isNot('guest'));
      server.failGuestDeletion = true;
      await cloud.sync();
      expect(server.rows['bike:$copiedId']?['payload'], isNotNull);
      expect(cloud.guestCleanupPending, isTrue);
      expect((await store.savedWorkspaces()), isNotEmpty);
      server.failGuestDeletion = false;
      await cloud.sync();
      expect(cloud.guestCleanupPending, isFalse);
      expect(bikes.bikes.single.id, copiedId);
      expect(await store.savedWorkspaces(), isEmpty);
      expect(store.owner, 'user-2');
      expect(server.deletionCalls, 0);
    },
  );

  test('guest copies merge into a previously saved Google workspace', () async {
    await switchGuestWithChoice('import');
    await stringMapStoreFactory
        .store('workspaces')
        .record('account:user-2')
        .put(store.database, {
          'version': 1,
          'owner': 'user-2',
          'payload': {
            'bikes': [bike('existing')],
            'catalog': [],
          },
          'base': {},
          'initialized': true,
        });
    server.rows['bike:existing'] = {
      'document_id': 'bike:existing',
      'revision': 1,
      'payload': bike('existing'),
    };
    await cloud.sync();
    expect(cloud.googlePending, isFalse, reason: '${cloud.lastError}');
    expect(store.owner, 'user-2');
    expect(bikes.bikes.length, 2);
    expect(bikes.bikes.map((bike) => bike.id), contains('existing'));
    expect(bikes.bikes.map((bike) => bike.id), isNot(contains('guest')));
    await cloud.sync();
    expect(bikes.bikes.length, 2);
  });

  test(
    'explicit discard never uploads guest bikes to Google account',
    () async {
      await switchGuestWithChoice('discard');
      await cloud.sync();
      expect(bikes.bikes, isEmpty);
      expect(server.rows.keys.where((key) => key.startsWith('bike:')), isEmpty);
      expect(server.guestDeletionCalls, 1);
      expect(cloud.guestCleanupPending, isFalse);
      expect(store.owner, 'user-2');
    },
  );

  for (final choice in ['import', 'discard']) {
    test('guest $choice completes despite unavailable image cleanup', () async {
      await switchGuestWithChoice(choice);
      server.failImageCleanup = true;
      server.failGuestDeletion = true;
      await cloud.sync();
      expect(cloud.status, 'cleanup');
      expect(server.guestDeletionCalls, 1);
      expect(cloud.guestCleanupPending, isTrue);
      expect(cloud.guestCleanupError, isNotNull);
      expect(await store.savedWorkspaces(), isNotEmpty);
      final copiedIds = bikes.bikes.map((bike) => bike.id).toList();
      for (final id in copiedIds) {
        expect(server.rows['bike:$id']?['payload'], isNotNull);
      }

      server.failGuestDeletion = false;
      await cloud.sync();
      expect(server.guestDeletionCalls, 2);
      expect(cloud.guestCleanupPending, isFalse);
      expect(cloud.guestCleanupError, isNull);
      expect(await store.savedWorkspaces(), isEmpty);
      expect(bikes.bikes.map((bike) => bike.id), copiedIds);
      expect(store.owner, 'user-2');
      expect(server.deletionCalls, 0);
    });
  }

  test(
    'failed guest upload still blocks deletion when cleanup is unavailable',
    () async {
      await switchGuestWithChoice('import');
      server.failImageCleanup = true;
      server.failNextUploadResponse = true;
      await cloud.sync();
      expect(server.guestDeletionCalls, 0);
      expect(cloud.guestCleanupPending, isTrue);
      expect(await store.savedWorkspaces(), isNotEmpty);
    },
  );

  test(
    'guest import completion survives restart without importing twice',
    () async {
      await switchGuestWithChoice('import');
      await store.finishGoogleLogin('user-2');
      final reopened = LocalStore(store.database);
      await reopened.initialize(await SharedPreferences.getInstance());
      await reopened.finishGoogleLogin('user-2');
      expect((reopened.payload['bikes'] as List).length, 1);
      expect(reopened.state['guestCleanup']['ticket'], 'guest-ticket');
      reopened.dispose();
    },
  );

  test('Google linking to a different UID never moves local data', () async {
    await initialize([bike('guest')]);
    await cloud.sync();
    await googleIntent('link');
    server.googleAuth = true;
    await server.client.auth.signInWithPassword(
      email: 'second@example.com',
      password: 'password',
    );
    final uploads = server.uploads;
    await cloud.sync();
    expect(cloud.status, 'google');
    expect(store.owner, 'user-1');
    expect(bikes.bikes.single.id, 'guest');
    expect(server.uploads, uploads);
  });

  test(
    'Google intent survives restart and can be cancelled without deleting data',
    () async {
      await initialize([bike('guest')]);
      await store.bindOwner('user-1');
      await googleIntent('login');
      final reopened = LocalStore(store.database);
      await reopened.initialize(await SharedPreferences.getInstance());
      expect(reopened.state['googleIntent']['kind'], 'login');
      reopened.dispose();
      await cloud.cancelGoogle();
      expect(store.state['googleIntent'], isNull);
      expect(bikes.bikes.single.id, 'guest');
    },
  );

  test(
    'expired Google intent blocks account switching and retains guest data',
    () async {
      await initialize([bike('guest')]);
      await cloud.sync();
      await googleIntent('login');
      await store.mutate(
        (state) => state['googleIntent']['createdAt'] = DateTime.now()
            .subtract(const Duration(hours: 1))
            .microsecondsSinceEpoch,
      );
      server.googleAuth = true;
      await server.client.auth.signInWithPassword(
        email: 'second@example.com',
        password: 'password',
      );
      await cloud.sync();
      expect(cloud.status, 'google');
      expect(store.owner, 'user-1');
    },
  );

  test(
    'dashboard deletion retains bikes and requires explicit recovery',
    () async {
      await initialize([bike('local-bike')]);
      await cloud.sync();
      server.deletedUsers.add('user-1');
      server.rows.clear();
      await cloud.sync();
      expect(cloud.status, 'session');
      expect(cloud.sessionUnavailable, isTrue);
      expect(store.owner, 'user-1');
      expect(bikes.bikes.single.id, 'local-bike');
      expect(server.signupCalls, 0);
      server.signupUserId = 'replacement-guest';
      await cloud.reconnectLocalData();
      while (cloud.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(cloud.sessionUnavailable, isFalse);
      expect(store.owner, 'replacement-guest');
      expect(server.signupCalls, 1);
      expect(bikes.bikes.single.id, 'local-bike');
      expect(server.rows['bike:local-bike']?['revision'], 1);
    },
  );

  test(
    'network failure never replaces an account or discards local data',
    () async {
      await initialize([bike('offline-bike')]);
      await cloud.sync();
      server.userLookupOffline = true;
      await cloud.sync();
      expect(cloud.sessionUnavailable, isFalse);
      await expectLater(cloud.reconnectLocalData(), throwsA(anything));
      expect(store.owner, 'user-1');
      expect(bikes.bikes.single.id, 'offline-bike');
      expect(server.signupCalls, 0);
    },
  );

  test('stale browser workspace cannot overwrite another tab', () async {
    await initialize([bike('a')]);
    final secondTab = LocalStore(store.database);
    await secondTab.initialize(await SharedPreferences.getInstance());
    await store.savePayload({
      'bikes': [bike('a', 'First tab edit')],
      'catalog': [],
    });
    await expectLater(
      secondTab.savePayload({
        'bikes': [bike('a', 'Stale tab edit')],
        'catalog': [],
      }),
      throwsStateError,
    );
    final reopened = LocalStore(store.database);
    await reopened.initialize(await SharedPreferences.getInstance());
    expect(
      (reopened.payload['bikes'] as List).single['model'],
      'First tab edit',
    );
    secondTab.dispose();
    reopened.dispose();
  });

  test(
    'lost session never creates a replacement identity for owned data',
    () async {
      await initialize([bike('a')]);
      await cloud.sync();
      await server.client.auth.signOut();
      await cloud.sync();
      expect(cloud.status, 'session');
      expect(store.owner, 'user-1');
      expect(bikes.bikes.single.id, 'a');
    },
  );
}
