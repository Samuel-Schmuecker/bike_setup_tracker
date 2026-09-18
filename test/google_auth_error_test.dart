import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bike_setup_tracker/cloud/google_auth_error.dart';

void main() {
  test('missing verifier explains same-browser recovery', () {
    final code = googleAuthErrorCode(
      const AuthException('Code verifier could not be found in local storage.'),
    );
    expect(code, 'pkce_verifier_missing_or_invalid');
    expect(googleAuthErrorHelp(code, languageCode: 'de'), contains('Safari'));
  });
  test('diagnostics never expose exception text or arbitrary codes', () {
    expect(
      googleAuthErrorCode(
        const AuthException(
          'secret callback',
          code: 'https://example.com/?code=secret',
        ),
      ),
      'google_failed',
    );
    expect(googleAuthErrorCode(StateError('secret')), 'google_failed');
    expect(
      googleAuthErrorCode(
        const AuthException('hidden', code: 'identity_already_exists'),
      ),
      'identity_already_exists',
    );
  });
}
