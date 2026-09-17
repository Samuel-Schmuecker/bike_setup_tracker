import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../cloud/cloud_provider.dart';
import '../../widgets/privacy_policy_link.dart';
import '../../cloud/google_auth_error.dart';
import '../../cloud/sync_documents.dart';
import '../../providers/language_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _message;
  bool _working = false;
  bool get de => context.read<LanguageProvider>().currentLanguage == 'de';
  String t(String german, String english) => de ? german : english;

  Future<void> signInWithGuestChoice(CloudProvider cloud) async {
    String? choice;
    if (cloud.anonymous && cloud.store.owner != null) {
      choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            t(
              'Was soll mit deinen Gastdaten passieren?',
              'What should happen to your guest data?',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t(
                    'Nach erfolgreicher Google-Anmeldung wird das bisherige Gastkonto gelöscht. Übernommene Daten werden vorher vollständig synchronisiert.',
                    'After successful Google sign-in, the old guest account is deleted. Imported data is fully synced first.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, 'import'),
                  child: Text(
                    t('Daten als Kopien übernehmen', 'Import data as copies'),
                  ),
                ),
                TextButton(
                  onPressed: () => run(() => export(cloud)),
                  child: Text(t('Sicherung exportieren', 'Export backup')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'discard'),
                  child: Text(t('Gastdaten verwerfen', 'Discard guest data')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Abbrechen', 'Cancel')),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == 'discard' &&
          !await confirm(
            t('Gastdaten wirklich verwerfen?', 'Discard guest data?'),
            t(
              'Nach erfolgreicher Anmeldung werden das alte Gastkonto, seine Cloud-Daten und lokalen Sicherungen gelöscht. Exportierte Dateien bleiben erhalten.',
              'After successful sign-in, the old guest account, its cloud data and local backups are deleted. Exported files remain.',
            ),
          )) {
        return;
      }
    }
    if (mounted) {
      await run(() => cloud.startGoogle(link: false, guestChoice: choice));
    }
  }

  Future<void> requestDeletion(CloudProvider cloud) async {
    final controller = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            t('Konto endgültig löschen?', 'Permanently delete account?'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t(
                    'Dein App-Konto, Cloud-Daten, Bilder und frühere Versionen sowie die lokalen Sicherungen dieses Kontos werden gelöscht. Dein Google-Konto bleibt bestehen. Exportierte Dateien und Kopien auf anderen Geräten bleiben erhalten. Anbieter-Backups unterliegen deren Aufbewahrungsfristen. Dieser Vorgang kann nicht rückgängig gemacht werden.',
                    'Your app account, cloud data, images, previous versions and this account’s local backups will be deleted. Your Google account remains. Exported files and copies on other devices remain. Provider backups follow their retention periods. This cannot be undone.',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  onChanged: (_) => update(() {}),
                  decoration: InputDecoration(
                    labelText: t(
                      'Zur Bestätigung DELETE eingeben',
                      'Type DELETE to confirm',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('Abbrechen', 'Cancel')),
            ),
            FilledButton(
              onPressed: controller.text == 'DELETE'
                  ? () => Navigator.pop(context, true)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(t('Endgültig löschen', 'Delete permanently')),
            ),
          ],
        ),
      ),
    );
    // The dialog may still be animating out; its controller is disposed afterwards.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (accepted == true && mounted) await run(cloud.deleteAccount);
  }

  Future<void> run(Future<void> Function() work, {String? success}) async {
    if (_working) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await work();
      if (mounted) setState(() => _message = success);
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = t(
            'Der Vorgang wurde nicht abgeschlossen. Bitte Verbindung und Eingaben prüfen. Details: $error',
            'The operation did not complete. Please check your connection and entries. Details: $error',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> export(CloudProvider cloud) async {
    final data = Uint8List.fromList(
      utf8.encode(jsonEncode(await cloud.exportBackup())),
    );
    final name =
        'bike-backup-${DateTime.now().toIso8601String().substring(0, 10)}.json';
    final file = XFile.fromData(data, mimeType: 'application/json', name: name);
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          fileNameOverrides: [name],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } else {
      final target = await getSaveLocation(suggestedName: name);
      if (target != null) await file.saveTo(target.path);
    }
  }

  Future<void> import(CloudProvider cloud) async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Bike backup',
          extensions: ['json'],
          mimeTypes: ['application/json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ],
    );
    if (file == null) return;
    if (await file.length() > 50 * 1024 * 1024) {
      throw const FormatException('Backup exceeds 50 MB');
    }
    final backup = Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()) as Map,
    );
    if (!mounted) return;
    final confirmed = await confirm(
      t('Sicherung importieren?', 'Import backup?'),
      t(
        'Die Bikes werden als neue Kopien hinzugefügt. Vorhandene Bikes bleiben erhalten.',
        'Bikes will be added as new copies. Existing bikes are retained.',
      ),
    );
    if (confirmed) await cloud.importBackup(backup);
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('Abbrechen', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('Bestätigen', 'Confirm')),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> history(CloudProvider cloud) async {
    final rows = await cloud.history();
    if (!mounted) return;
    final selected = await showDialog<Json>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('Frühere Cloud-Versionen', 'Previous cloud versions')),
        content: SizedBox(
          width: 500,
          height: 350,
          child: rows.isEmpty
              ? Text(
                  t(
                    'Noch keine früheren Versionen vorhanden.',
                    'No previous versions yet.',
                  ),
                )
              : ListView(
                  children: [
                    for (final row in rows)
                      if (row['payload'] != null)
                        ListTile(
                          title: Text(
                            '${row['document_id']} · ${row['revision']}',
                          ),
                          subtitle: Text('${row['saved_at']}'),
                          onTap: () => Navigator.pop(ctx, row),
                        ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('Schließen', 'Close')),
          ),
        ],
      ),
    );
    if (selected != null &&
        mounted &&
        await confirm(
          t('Version wiederherstellen?', 'Restore version?'),
          t(
            'Diese Fassung wird wieder zur aktuellen Fassung. Der aktuelle lokale Bestand wird vorher gesichert.',
            'This version becomes current. The current local data is backed up first.',
          ),
        )) {
      await cloud.restoreVersion(selected);
    }
  }

  Future<void> localHistory(CloudProvider cloud) async {
    final rows = await cloud.store.savedWorkspaces();
    if (!mounted) return;
    final selected = await showDialog<Json>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('Lokale Sicherungen', 'Local backups')),
        content: SizedBox(
          width: 500,
          height: 350,
          child: rows.isEmpty
              ? Text(t('Noch keine Sicherungen vorhanden.', 'No backups yet.'))
              : ListView(
                  children: [
                    for (final row in rows)
                      ListTile(
                        title: Text(
                          '${(row['payload']['bikes'] as List).length} Bikes',
                        ),
                        subtitle: Text(
                          row['key'].toString().startsWith('backup:')
                              ? DateTime.fromMicrosecondsSinceEpoch(
                                  int.parse(row['key'].toString().substring(7)),
                                ).toString()
                              : t(
                                  'Separat gespeicherter Kontobestand',
                                  'Separately saved account data',
                                ),
                        ),
                        onTap: () => Navigator.pop(ctx, row),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('Schließen', 'Close')),
          ),
        ],
      ),
    );
    if (selected != null &&
        mounted &&
        await confirm(
          t('Als Kopien übernehmen?', 'Restore as copies?'),
          t(
            'Diese Bikes werden dem aktuellen Bestand hinzugefügt.',
            'These bikes will be added to the current workspace.',
          ),
        )) {
      await cloud.restoreLocalWorkspace(selected);
    }
  }

  String documentLabel(String key, CloudProvider cloud) {
    if (key == 'order') return t('Reihenfolge der Bikes', 'Bike order');
    if (key == 'library') {
      return t('Bibliothek eigener Felder', 'Custom field library');
    }
    for (final bike in cloud.bikes.bikes) {
      if (key == 'bike:${bike.id}') return '${bike.brand} ${bike.model}';
    }
    return t('Gelöschtes Bike', 'Deleted bike');
  }

  String statusText(String status) => switch (status) {
    'google_waiting' => t(
      'Cloud synchronisiert; Google-Anmeldung noch offen.',
      'Cloud synced; Google sign-in pending.',
    ),
    'google' => t(
      'Google-Anmeldung konnte nicht zugeordnet werden oder ist abgelaufen. Bitte abbrechen und erneut anmelden.',
      'Google sign-in could not be matched or expired. Please cancel and sign in again.',
    ),
    'syncing' => t('Daten werden synchronisiert …', 'Syncing data …'),
    'synced' => t('Mit Cloud synchronisiert', 'Synced with cloud'),
    'conflict' => t(
      'Änderungskonflikt – Auswahl erforderlich',
      'Conflicting changes – choose a version',
    ),
    'setup' => t(
      'Cloud-Einrichtung fehlt: SQL-Skript und Zugriffsregeln prüfen.',
      'Cloud setup is incomplete: check SQL migration and access rules.',
    ),
    'session' => t(
      'Anmeldung fehlt. Bitte erneut anmelden. Lokale Daten bleiben erhalten.',
      'Session missing. Please sign in again. Local data is retained.',
    ),
    'auth' => t(
      'Anmeldung nicht möglich. Verbindung und anonyme Anmeldung in Supabase prüfen.',
      'Unable to authenticate. Check connection and anonymous sign-ins in Supabase.',
    ),
    'local' => t(
      'Lokales Speichern fehlgeschlagen. Bitte freien Speicher prüfen.',
      'Local save failed. Please check free storage.',
    ),
    'offline' => t(
      'Sicherung ausstehend. Verbindung oder Cloud-Dienst nicht verfügbar; automatischer Wiederholungsversuch folgt.',
      'Backup pending. Connection or cloud service unavailable; retrying automatically.',
    ),
    _ => t('Sicherung ausstehend', 'Backup pending'),
  };

  Widget authOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback? onPressed,
    bool emphasized = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primaryContainer
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: emphasized ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: emphasized ? colors.onPrimaryContainer : colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: emphasized
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: emphasized ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: emphasized
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (emphasized)
            FilledButton(onPressed: onPressed, child: Text(title))
          else
            OutlinedButton(onPressed: onPressed, child: Text(title)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final cloud = context.watch<CloudProvider>();
    final disabled = cloud.busy || _working;
    if (cloud.cloudPaused || cloud.deletionPending) {
      return Scaffold(
        appBar: AppBar(title: Text(t('Konto löschen', 'Delete account'))),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cloud.cloudPaused
                        ? Icons.check_circle_outline
                        : Icons.delete_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cloud.cloudPaused
                        ? t(
                            'Dein Konto wurde gelöscht. Es wird kein neues Gastkonto angelegt, bis du die App erneut nutzt.',
                            'Your account has been deleted. No new guest account is created until you start again.',
                          )
                        : t(
                            'Die Kontolöschung wurde gestartet. Die Synchronisierung ist gesperrt. Bei einem Verbindungsfehler kannst du die Löschung erneut versuchen.',
                            'Account deletion has started. Sync is blocked. If the connection fails, retry deletion.',
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (disabled) const LinearProgressIndicator(),
                  if (_message != null) SelectableText(_message!),
                  if (!cloud.cloudPaused)
                    TextButton(
                      onPressed: disabled
                          ? null
                          : () => run(() => export(cloud)),
                      child: Text(
                        t('Lokale Daten exportieren', 'Export local data'),
                      ),
                    ),
                  FilledButton(
                    onPressed: disabled
                        ? null
                        : () => run(
                            cloud.cloudPaused
                                ? cloud.resumeAfterDeletion
                                : cloud.deleteAccount,
                          ),
                    child: Text(
                      cloud.cloudPaused
                          ? t('Neu als Gast starten', 'Start again as guest')
                          : t('Löschung erneut versuchen', 'Retry deletion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Konto & Datensicherung', 'Account & backup')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cloud.anonymous
                            ? t(
                                'Du nutzt die App als Gast',
                                'You are using the app as a guest',
                              )
                            : cloud.email ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(statusText(cloud.status)),
                      if (cloud.sessionUnavailable) ...[
                        const SizedBox(height: 12),
                        Text(
                          t(
                            'Deine gespeicherte Anmeldung ist nicht mehr gültig. Das Konto wurde möglicherweise außerhalb der App gelöscht. Deine lokalen Daten sind noch vorhanden.',
                            'Your saved session is no longer valid. The account may have been deleted outside the app. Your local data is still available.',
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: disabled
                              ? null
                              : () async {
                                  if (await confirm(
                                    t(
                                      'Lokale Daten neu verbinden?',
                                      'Reconnect local data?',
                                    ),
                                    t(
                                      'Es wird ein neues Gastkonto erstellt. Deine vorhandenen lokalen Daten werden dorthin übertragen. Anschließend kannst du Google verbinden oder dich anmelden.',
                                      'A new guest account will be created and your existing local data uploaded to it. You can then link Google or sign in.',
                                    ),
                                  )) {
                                    await run(cloud.reconnectLocalData);
                                  }
                                },
                          label: Text(
                            t(
                              'Lokale Daten neu verbinden',
                              'Reconnect local data',
                            ),
                          ),
                        ),
                      ],
                      if (cloud.store.lastSync != null)
                        Text(
                          '${t('Letzte Synchronisierung', 'Last sync')}: ${cloud.store.lastSync!.toLocal()}',
                        ),
                      const SizedBox(height: 12),
                      Text(
                        t(
                          'Bikes, Setups und Bilder werden lokal und automatisch in deiner privaten Cloud gespeichert.',
                          'Bikes, setups and images are saved locally and automatically to your private cloud.',
                        ),
                      ),
                      if (cloud.anonymous)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            t(
                              'Verknüpfe dein Google-Konto, um nach Geräteverlust oder gelöschten App-Daten wieder Zugriff zu erhalten. Die anonyme Anmeldung allein ermöglicht das nicht.',
                              'Link Google to regain access after losing a device or clearing app data. Anonymous sign-in alone cannot provide this.',
                            ),
                          ),
                        ),
                      if (!cloud.anonymous) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: disabled ? null : cloud.sync,
                          icon: const Icon(Icons.sync),
                          label: Text(t('Jetzt synchronisieren', 'Sync now')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (cloud.conflicts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  t('Konflikte', 'Conflicts'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  t(
                    'Beide Fassungen bleiben bis zur Auswahl erhalten. Vor der Auflösung wird lokal eine Sicherung angelegt.',
                    'Both versions are retained until you choose. A local backup is created before resolving.',
                  ),
                ),
                for (final key in cloud.conflicts.keys)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(documentLabel(key, cloud)),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (key.startsWith('bike:'))
                                FilledButton(
                                  onPressed: disabled
                                      ? null
                                      : () => run(
                                          () => cloud.keepBoth(
                                            key,
                                            t('Konfliktkopie', 'Conflict copy'),
                                          ),
                                        ),
                                  child: Text(
                                    t(
                                      'Beide Fassungen behalten',
                                      'Keep both versions',
                                    ),
                                  ),
                                ),
                              TextButton(
                                onPressed: disabled
                                    ? null
                                    : () => run(
                                        () => cloud.resolveConflict(
                                          key,
                                          keepLocal: true,
                                        ),
                                      ),
                                child: Text(
                                  t(
                                    'Lokale Fassung behalten',
                                    'Keep local version',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: disabled
                                    ? null
                                    : () => run(
                                        () => cloud.resolveConflict(
                                          key,
                                          keepLocal: false,
                                        ),
                                      ),
                                child: Text(
                                  t(
                                    'Cloud-Fassung übernehmen',
                                    'Use cloud version',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            cloud.googleLinked
                                ? Icons.verified_user_outlined
                                : Icons.account_circle_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cloud.googleLinked
                                  ? t(
                                      'Google ist verbunden',
                                      'Google is connected',
                                    )
                                  : t('Dein Konto', 'Your account'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (cloud.anonymous ||
                          cloud.status == 'session' ||
                          cloud.status == 'google') ...[
                        authOption(
                          icon: Icons.login_rounded,
                          title: 'Login',
                          subtitle: t(
                            'Du hast bereits ein Konto?',
                            'Already have an account?',
                          ),
                          description: t(
                            'Melde dich mit Google an, um auf deine gespeicherten Bikes und Setups zuzugreifen. Du entscheidest vorher, was mit deinen Gastdaten passiert.',
                            'Sign in with Google to access your saved bikes and setups. First choose what happens to your guest data.',
                          ),
                          onPressed: disabled || cloud.googlePending
                              ? null
                              : () => signInWithGuestChoice(cloud),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!cloud.googleLinked)
                        authOption(
                          icon: Icons.person_add_alt_1_rounded,
                          title: t('Registrieren', 'Register'),
                          subtitle: t(
                            'Neu hier? Sichere deine Bikes.',
                            'New here? Keep your bikes safe.',
                          ),
                          description: t(
                            'Erstelle dein App-Konto mit Google. Deine bisherigen Bikes und Setups bleiben erhalten und werden mit deinem Konto verknüpft. Du brauchst kein zusätzliches Passwort.',
                            'Create your app account with Google. Your existing bikes and setups are kept and linked to your account. No extra password needed.',
                          ),
                          emphasized: true,
                          onPressed: disabled || cloud.googlePending
                              ? null
                              : () => run(() => cloud.startGoogle(link: true)),
                        )
                      else
                        Text(
                          t(
                            'Google ist verknüpft. Melde dich auf anderen Geräten mit demselben Google-Konto an.',
                            'Google is linked. Sign in with the same Google account on other devices.',
                          ),
                        ),
                      if (cloud.googlePending || cloud.googleIssue != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          cloud.googleIssue == null
                              ? t(
                                  'Schließe die Google-Anmeldung im Browser ab und kehre zur App zurück. Bei einer Verknüpfung mit einem bereits verwendeten Google-Konto bitte abbrechen und „Login“ wählen.',
                                  'Complete Google sign-in in the browser and return to the app. If this Google account is already linked elsewhere, cancel and choose Login.',
                                )
                              : googleAuthErrorHelp(
                                  cloud.googleIssue!,
                                  german: de,
                                ),
                        ),
                        if (cloud.googleIssue != null)
                          SelectableText('Code: ${cloud.googleIssue}'),
                        OutlinedButton(
                          onPressed: disabled
                              ? null
                              : () => run(cloud.cancelGoogle),
                          child: Text(
                            t(
                              'Google-Anmeldung abbrechen',
                              'Cancel Google sign-in',
                            ),
                          ),
                        ),
                      ],
                      if (!cloud.anonymous)
                        OutlinedButton(
                          onPressed: disabled || cloud.googlePending
                              ? null
                              : () => run(() async {
                                  if (await confirm(
                                    t('Abmelden?', 'Sign out?'),
                                    t(
                                      'Der lokale Kontobestand bleibt separat erhalten. Noch nicht synchronisierte Änderungen sind nur auf diesem Gerät vorhanden.',
                                      'Your local account data is retained separately. Unsynced changes exist only on this device.',
                                    ),
                                  )) {
                                    await cloud.signOut();
                                  }
                                }),
                          child: Text(t('Abmelden', 'Sign out')),
                        ),
                      if (cloud.anonymous) ...[
                        const SizedBox(height: 12),
                        Text(
                          t(
                            'Google ist optional. Du kannst die App weiter als Gast nutzen.',
                            'Google is optional. You can keep using the app as a guest.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_working || cloud.busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SelectableText(_message!),
                ),
              const Divider(height: 40),
              if (cloud.guestCleanupPending) ...[
                Text(
                  t(
                    'Bisheriges Gastkonto bereinigen',
                    'Clean up previous guest account',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  cloud.guestCleanupError == null
                      ? t(
                          'Die Gastdaten werden abgeglichen. Erst danach wird das alte Gastkonto gelöscht.',
                          'Guest data is being synced. The old guest account is deleted afterwards.',
                        )
                      : t(
                          'Das alte Gastkonto konnte noch nicht gelöscht werden. Deine Google-Daten bleiben erhalten. Bitte erneut versuchen. Wenn der Fehler bleibt, muss der Gastbestand geprüft werden.',
                          'The old guest account could not be deleted yet. Your Google data remains. Retry; if this persists, the guest data needs review.',
                        ),
                ),
                OutlinedButton(
                  onPressed: disabled ? null : cloud.sync,
                  child: Text(t('Erneut versuchen', 'Retry')),
                ),
                const Divider(height: 24),
              ],
              Text(
                t('Sicherungsdateien', 'Backup files'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                t(
                  'Eine exportierte Datei enthält deine Bikes, Setups und Bilder. Bewahre sie an einem sicheren Ort außerhalb dieses Geräts auf.',
                  'An exported file contains your bikes, setups and images. Keep it somewhere safe outside this device.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: disabled ? null : () => run(() => export(cloud)),
                    icon: const Icon(Icons.download),
                    label: Text(t('Exportieren', 'Export')),
                  ),
                  OutlinedButton.icon(
                    onPressed: disabled ? null : () => run(() => import(cloud)),
                    icon: const Icon(Icons.upload),
                    label: Text(t('Importieren', 'Import')),
                  ),
                  OutlinedButton(
                    onPressed: disabled || cloud.user == null
                        ? null
                        : () => run(() => history(cloud)),
                    child: Text(t('Cloud-Versionen', 'Cloud versions')),
                  ),
                  OutlinedButton(
                    onPressed: disabled
                        ? null
                        : () => run(() => localHistory(cloud)),
                    child: Text(t('Lokale Sicherungen', 'Local backups')),
                  ),
                ],
              ),
              const Divider(height: 40),
              Text(
                t('Konto löschen', 'Delete account'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Entfernt dein App-Konto und die zugehörigen Daten dauerhaft. Exportiere vorher eine Sicherung, wenn du deine Daten behalten möchtest.',
                  'Permanently removes your app account and its data. Export a backup first if you want to keep your data.',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: disabled ? null : () => run(() => export(cloud)),
                icon: const Icon(Icons.download),
                label: Text(
                  t('Vorher Sicherung exportieren', 'Export backup first'),
                ),
              ),
              TextButton.icon(
                onPressed: disabled || cloud.user == null || cloud.googlePending
                    ? null
                    : () => requestDeletion(cloud),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(
                  t('Konto und Daten löschen', 'Delete account and data'),
                ),
              ),
              const Divider(height: 40),
              PrivacyPolicyLink(german: de),
            ],
          ),
        ),
      ),
    );
  }
}
