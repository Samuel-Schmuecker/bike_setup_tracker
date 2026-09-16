import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../cloud/cloud_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final cloud = context.watch<CloudProvider>();
    final disabled = cloud.busy || _working;
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
                            ? t('Ohne Registrierung', 'Without registration')
                            : cloud.email ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(statusText(cloud.status)),
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
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: disabled ? null : cloud.sync,
                        icon: const Icon(Icons.sync),
                        label: Text(t('Jetzt synchronisieren', 'Sync now')),
                      ),
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
              Text(
                t('Google-Konto', 'Google account'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (!cloud.googleLinked) ...[
                Text(
                  t(
                    'Verknüpfe Google, um deine Bikes nach einem Gerätewechsel wiederzufinden. Dafür brauchst du kein zusätzliches Passwort.',
                    'Link Google to restore your bikes after changing devices. No additional password is needed.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: disabled || cloud.googlePending
                      ? null
                      : () => run(() => cloud.startGoogle(link: true)),
                  child: Text(
                    t(
                      'Mit Google absichern',
                      'Link Google to secure your data',
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  t(
                    'Google ist verknüpft. Melde dich auf anderen Geräten mit demselben Google-Konto an.',
                    'Google is linked. Sign in with the same Google account on other devices.',
                  ),
                ),
              ],
              if (cloud.anonymous ||
                  cloud.status == 'session' ||
                  cloud.status == 'google') ...[
                OutlinedButton(
                  onPressed: disabled || cloud.googlePending
                      ? null
                      : () => run(() async {
                          if (await confirm(
                            t('Mit Google anmelden?', 'Sign in with Google?'),
                            t(
                              'Dein Google-Konto wird geöffnet. Bisherige Gastdaten bleiben separat als lokale Sicherung erhalten und können danach als Kopien übernommen werden.',
                              'Your Google account will be opened. Guest data remains as a separate local backup and can then be imported as copies.',
                            ),
                          )) {
                            await cloud.startGoogle(link: false);
                          }
                        }),
                  child: Text(t('Mit Google anmelden', 'Sign in with Google')),
                ),
              ],
              if (cloud.googlePending || cloud.googleIssue != null) ...[
                const SizedBox(height: 12),
                Text(
                  cloud.googleIssue == null
                      ? t(
                          'Schließe die Google-Anmeldung im Browser ab und kehre zur App zurück. Bei einer Verknüpfung mit einem bereits verwendeten Google-Konto bitte abbrechen und „Mit Google anmelden“ wählen.',
                          'Complete Google sign-in in the browser and return to the app. If this Google account is already linked elsewhere, cancel and choose Sign in with Google.',
                        )
                      : googleAuthErrorHelp(cloud.googleIssue!, german: de),
                ),
                if (cloud.googleIssue != null)
                  SelectableText('Code: ${cloud.googleIssue}'),
                OutlinedButton(
                  onPressed: disabled ? null : () => run(cloud.cancelGoogle),
                  child: Text(
                    t('Google-Anmeldung abbrechen', 'Cancel Google sign-in'),
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
            ],
          ),
        ),
      ),
    );
  }
}
