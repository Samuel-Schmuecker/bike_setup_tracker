import 'package:bike_setup_tracker/utils/translations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Expose only a short diagnostic code, never callback URLs or tokens.
String googleAuthErrorCode(Object error) {
  if (error is! AuthException) return 'google_failed';
  if (error.message.toLowerCase().contains('code verifier')) {
    return 'pkce_verifier_missing_or_invalid';
  }
  final code = error.code;
  return code != null && RegExp(r'^[a-z0-9_]{1,80}$').hasMatch(code)
      ? code
      : 'google_failed';
}

String googleAuthErrorHelp(String code, {required String languageCode}) {
  if (code == 'pkce_verifier_missing_or_invalid' ||
      code == 'bad_code_verifier' ||
      code == 'flow_state_not_found' ||
      code == 'flow_state_expired') {
    return Translations.get(languageCode, 'authProofHelp');
  }
  if (code == 'identity_already_exists') {
    return Translations.get(languageCode, 'authAlreadyLinkedHelp');
  }
  if (code == 'manual_linking_disabled') {
    return Translations.get(languageCode, 'authManualLinkingHelp');
  }
  return Translations.get(languageCode, 'authIncompleteHelp');
}
