/// Public client credentials. Access is enforced by database and Storage RLS.
abstract final class CloudConfig {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  // Preserve production's existing offline data; dev starts in its own store.
  static const databaseName = environment == 'production'
      ? 'bike_tracker_v2'
      : 'bike_tracker_dev_v2';
  static const preferencesPrefix = environment == 'production'
      ? 'flutter.'
      : 'bike_tracker_dev.';

  static void validate() {
    if (environment != 'dev' && environment != 'production') {
      throw StateError('APP_ENV must be dev or production');
    }
    final expectedHost = environment == 'production'
        ? 'iwmrlwouyfpmizzirmby.supabase.co'
        : 'dcrkfiooddkbzljibomo.supabase.co';
    if (Uri.parse(url).host != expectedHost || key.isEmpty) {
      throw StateError('Supabase configuration does not match APP_ENV');
    }
  }

  // Use the deployed URL slug, which can differ from the dashboard label.
  static const imageCleanupFunction = String.fromEnvironment(
    'SUPABASE_IMAGE_CLEANUP_FUNCTION',
    defaultValue: 'super-function',
  );
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dcrkfiooddkbzljibomo.supabase.co',
  );
  static const key = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_qdamx1ZOBq0H0j2PBgk3hg__uIm2-M6',
  );
}
