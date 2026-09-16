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

String googleAuthErrorHelp(String code, {required bool german}) {
  if (code == 'pkce_verifier_missing_or_invalid' ||
      code == 'bad_code_verifier' ||
      code == 'flow_state_not_found' ||
      code == 'flow_state_expired') {
    return german
        ? 'Der Anmeldenachweis fehlt, ist ungültig oder abgelaufen. Starte und beende die Anmeldung im selben Browser. Auf dem iPhone die App direkt in Safari öffnen und dort erneut anmelden. Vorhandene App-Daten nicht löschen.'
        : 'The sign-in proof is missing, invalid or expired. Start and finish in the same browser. On iPhone, open the app directly in Safari and retry there. Do not clear existing app data.';
  }
  if (code == 'identity_already_exists') {
    return german
        ? 'Dieses Google-Konto ist bereits verknüpft. Brich diesen Versuch ab und wähle „Mit Google anmelden“.'
        : 'This Google account is already linked. Cancel this attempt and choose Sign in with Google.';
  }
  if (code == 'manual_linking_disabled') {
    return german
        ? 'Aktiviere „Allow manual linking“ in den Supabase-Auth-Einstellungen.'
        : 'Enable Allow manual linking in Supabase Auth settings.';
  }
  return german
      ? 'Google-Anmeldung nicht abgeschlossen. Bitte abbrechen und erneut versuchen. Bei erneutem Fehler den unten angezeigten Fehlercode mitteilen.'
      : 'Google sign-in did not complete. Cancel and retry. If it fails again, report the diagnostic code below.';
}
