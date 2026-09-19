/// Public client credentials. Access is enforced by database and Storage RLS.
abstract final class CloudConfig {
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
