import 'dart:async';
import 'dart:convert';
import 'package:bike_setup_tracker/cloud/cloud_provider.dart';
import 'package:bike_setup_tracker/cloud/local_store.dart';
import 'package:bike_setup_tracker/cloud/sync_documents.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
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
  Completer<void>? uploadStarted;
  Completer<void>? releaseUpload;
  bool failNextUploadResponse = false;
  bool anonymousAuth = false;
  bool passwordUpdated = false;
  bool googleAuth = false;
  String authId = 'user-1';
  String authEmail = 'test@example.com';
  int uploads = 0;
  bool failDeletion = false;
  int deletionCalls = 0;
  int signupCalls = 0;
  final documentAuthorizations = <String?>[];
  late final client = SupabaseClient(
    'https://test.supabase.co',
    'public-test-key',
    // The fake returns tokens directly; Flutter supplies PKCE storage in production.
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    httpClient: MockClient(handle),
  );

  Future<http.Response> handle(http.Request request) async {
    http.Response json(Object? value, [int code = 200]) => http.Response(
      jsonEncode(value),
      code,
      headers: {'content-type': 'application/json'},
      request: request,
    );
    final path = request.url.path;
    if (path == '/functions/v1/delete-account') {
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
      if (request.method == 'GET') return json(authUser(authId));
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
      final userId =
          (jsonDecode(request.body) as Map)['email'] == 'second@example.com'
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
    cloud = CloudProvider(
      store,
      bikes,
      client: server.client,
      startAutomatically: false,
    );
    addTearDown(() async {
      cloud.dispose();
      bikes.dispose();
      store.dispose();
      await server.client.dispose();
      await db.close();
    });
  }

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
      await cloud.deleteAccount();
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
      await expectLater(
        cloud.deleteAccount(),
        throwsA(isA<FunctionException>()),
      );
      expect(cloud.deletionPending, isTrue);
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
