/// Public client credentials. Access is enforced by database and Storage RLS.
abstract final class CloudConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dcrkfiooddkbzljibomo.supabase.co',
  );
  static const key = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_qdamx1ZOBq0H0j2PBgk3hg__uIm2-M6',
  );
}
