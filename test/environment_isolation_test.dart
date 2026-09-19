import 'package:bike_setup_tracker/cloud/cloud_config.dart';
import 'package:bike_setup_tracker/cloud/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(SharedPreferences.resetStatic);

  test(
    'dev isolates local data while production retains its existing store',
    () async {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({
        'bikes_data': '[]',
        'hasSeenOnboarding': true,
        'theme_accent': 123,
      });
      SharedPreferences.resetStatic();
      SharedPreferences.setPrefix(CloudConfig.preferencesPrefix);
      final preferences = await SharedPreferences.getInstance();
      final production = CloudConfig.environment == 'production';
      expect(
        preferences.getBool('hasSeenOnboarding'),
        production ? true : null,
      );
      expect(preferences.getInt('theme_accent'), production ? 123 : null);

      final factory = newDatabaseFactoryMemory();
      final legacyDatabase = await factory.openDatabase('bike_tracker_v2');
      final productionStore = LocalStore(legacyDatabase);
      SharedPreferences.resetStatic();
      final legacyPreferences = await SharedPreferences.getInstance();
      await productionStore.initialize(legacyPreferences);
      await productionStore.bindOwner('production-user');
      SharedPreferences.resetStatic();
      SharedPreferences.setPrefix(CloudConfig.preferencesPrefix);

      final database = await factory.openDatabase(CloudConfig.databaseName);
      final store = LocalStore(database);
      await store.initialize(preferences);
      expect(store.owner, production ? 'production-user' : null);
      expect(store.initialized, production);

      if (!production) {
        await preferences.remove('bikes_data');
        await preferences.setBool('hasSeenOnboarding', false);
        await store.bindOwner('dev-user');
        await productionStore.initialize(legacyPreferences);
        expect(productionStore.owner, 'production-user');
        SharedPreferences.resetStatic();
        final reloaded = await SharedPreferences.getInstance();
        expect(reloaded.getString('bikes_data'), '[]');
        expect(reloaded.getBool('hasSeenOnboarding'), true);
        await database.close();
      }
      await legacyDatabase.close();
    },
  );

  test('selected deployment configuration targets its designated project', () {
    expect(CloudConfig.validate, returnsNormally);
  });
}
