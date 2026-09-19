import 'package:bike_setup_tracker/utils/translations.dart';
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
  String get languageCode => context.read<LanguageProvider>().currentLanguage;

  Future<void> signInWithGuestChoice(CloudProvider cloud) async {
    String? choice;
    if (cloud.anonymous && cloud.store.owner != null) {
      choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(Translations.get(languageCode, 'guestDataChoiceTitle')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(Translations.get(languageCode, 'guestDataChoiceBody')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, 'import'),
                  child: Text(
                    Translations.get(languageCode, 'guestDataImportCopies'),
                  ),
                ),
                TextButton(
                  onPressed: () => run(() => export(cloud)),
                  child: Text(Translations.get(languageCode, 'backupExport')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'discard'),
                  child: Text(
                    Translations.get(languageCode, 'guestDataDiscard'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(Translations.get(languageCode, 'cancel')),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == 'discard' &&
          !await confirm(
            Translations.get(languageCode, 'guestDataDiscardTitle'),
            Translations.get(languageCode, 'guestDataDiscardBody'),
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
          title: Text(Translations.get(languageCode, 'accountDeleteTitle')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Translations.get(languageCode, 'accountDeleteBody')),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  onChanged: (_) => update(() {}),
                  decoration: InputDecoration(
                    labelText: Translations.get(
                      languageCode,
                      'accountDeleteConfirmationHint',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(Translations.get(languageCode, 'cancel')),
            ),
            FilledButton(
              onPressed: controller.text == 'DELETE'
                  ? () => Navigator.pop(context, true)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                Translations.get(languageCode, 'accountDeleteConfirm'),
              ),
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      await work();
      if (mounted) setState(() => _message = success);
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = Translations.format(
            languageCode,
            'accountOperationError',
            {'error': (error).toString()},
          ),
        );
        // The inline error can be below the viewport after the guest dialog.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            duration: const Duration(seconds: 15),
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
        XTypeGroup(
          label: Translations.get(languageCode, 'backupFileType'),
          extensions: const ['json'],
          mimeTypes: const ['application/json'],
          uniformTypeIdentifiers: const ['public.json'],
        ),
      ],
    );
    if (file == null) return;
    if (await file.length() > 50 * 1024 * 1024) {
      throw FormatException(Translations.get(languageCode, 'backupTooLarge'));
    }
    final backup = Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()) as Map,
    );
    if (!mounted) return;
    final confirmed = await confirm(
      Translations.get(languageCode, 'backupImportTitle'),
      Translations.get(languageCode, 'backupImportBody'),
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
              child: Text(Translations.get(languageCode, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(Translations.get(languageCode, 'confirm')),
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
        title: Text(Translations.get(languageCode, 'backupCloudHistoryTitle')),
        content: SizedBox(
          width: 500,
          height: 350,
          child: rows.isEmpty
              ? Text(Translations.get(languageCode, 'backupCloudHistoryEmpty'))
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
            child: Text(Translations.get(languageCode, 'close')),
          ),
        ],
      ),
    );
    if (selected != null &&
        mounted &&
        await confirm(
          Translations.get(languageCode, 'backupRestoreTitle'),
          Translations.get(languageCode, 'backupRestoreBody'),
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
        title: Text(Translations.get(languageCode, 'backupLocalTitle')),
        content: SizedBox(
          width: 500,
          height: 350,
          child: rows.isEmpty
              ? Text(Translations.get(languageCode, 'backupLocalEmpty'))
              : ListView(
                  children: [
                    for (final row in rows)
                      ListTile(
                        title: Text(
                          Translations.format(languageCode, 'backupBikeCount', {
                            'count': (row['payload']['bikes'] as List).length
                                .toString(),
                          }),
                        ),
                        subtitle: Text(
                          row['key'].toString().startsWith('backup:')
                              ? DateTime.fromMicrosecondsSinceEpoch(
                                  int.parse(row['key'].toString().substring(7)),
                                ).toString()
                              : Translations.get(
                                  languageCode,
                                  'backupSeparateAccount',
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
            child: Text(Translations.get(languageCode, 'close')),
          ),
        ],
      ),
    );
    if (selected != null &&
        mounted &&
        await confirm(
          Translations.get(languageCode, 'backupRestoreCopiesTitle'),
          Translations.get(languageCode, 'backupRestoreCopiesBody'),
        )) {
      await cloud.restoreLocalWorkspace(selected);
    }
  }

  String documentLabel(String key, CloudProvider cloud) {
    if (key == 'order')
      return Translations.get(languageCode, 'accountDocumentBikeOrder');
    if (key == 'library') {
      return Translations.get(languageCode, 'accountDocumentFieldLibrary');
    }
    for (final bike in cloud.bikes.bikes) {
      if (key == 'bike:${bike.id}') return '${bike.brand} ${bike.model}';
    }
    return Translations.get(languageCode, 'accountDocumentDeletedBike');
  }

  String statusText(String status) => switch (status) {
    'images' => Translations.get(languageCode, 'syncStatusImages'),
    'cleanup' => Translations.get(languageCode, 'syncStatusCleanup'),
    'google_waiting' => Translations.get(
      languageCode,
      'syncStatusGoogleWaiting',
    ),
    'google' => Translations.get(languageCode, 'syncStatusGoogleError'),
    'syncing' => Translations.get(languageCode, 'syncStatusSyncing'),
    'synced' => Translations.get(languageCode, 'syncStatusSynced'),
    'conflict' => Translations.get(languageCode, 'syncStatusConflict'),
    'setup' => Translations.get(languageCode, 'syncStatusSetup'),
    'session' => Translations.get(languageCode, 'syncStatusSession'),
    'auth' => Translations.get(languageCode, 'syncStatusAuth'),
    'local' => Translations.get(languageCode, 'syncStatusLocal'),
    'offline' => Translations.get(languageCode, 'syncStatusOffline'),
    _ => Translations.get(languageCode, 'syncStatusPending'),
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
        appBar: AppBar(
          title: Text(Translations.get(languageCode, 'accountDelete')),
        ),
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
                        ? Translations.get(languageCode, 'accountDeletedBody')
                        : Translations.get(
                            languageCode,
                            'accountDeletionPendingBody',
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
                        Translations.get(languageCode, 'backupExportLocal'),
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
                          ? Translations.get(
                              languageCode,
                              'accountRestartGuest',
                            )
                          : Translations.get(
                              languageCode,
                              'accountRetryDeletion',
                            ),
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
        title: Text(Translations.get(languageCode, 'accountBackup')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (cloud.googleIssue != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          googleAuthErrorHelp(
                            cloud.googleIssue!,
                            languageCode: languageCode,
                          ),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        if (cloud.googleIssue == 'identity_already_exists') ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: disabled
                                ? null
                                : () async {
                                    await run(cloud.cancelGoogle);
                                    if (mounted &&
                                        cloud.googleIssue == null &&
                                        !cloud.googlePending) {
                                      await signInWithGuestChoice(cloud);
                                    }
                                  },
                            icon: const Icon(Icons.login),
                            label: Text(
                              Translations.get(languageCode, 'accountLogin'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cloud.anonymous
                            ? Translations.get(
                                languageCode,
                                'accountGuestStatus',
                              )
                            : cloud.email ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(statusText(cloud.status)),
                      if (cloud.sessionUnavailable) ...[
                        const SizedBox(height: 12),
                        Text(
                          Translations.get(
                            languageCode,
                            'accountSessionExpiredBody',
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: disabled
                              ? null
                              : () async {
                                  if (await confirm(
                                    Translations.get(
                                      languageCode,
                                      'accountReconnectTitle',
                                    ),
                                    Translations.get(
                                      languageCode,
                                      'accountReconnectBody',
                                    ),
                                  )) {
                                    await run(cloud.reconnectLocalData);
                                  }
                                },
                          label: Text(
                            Translations.get(languageCode, 'accountReconnect'),
                          ),
                        ),
                      ],
                      if (cloud.store.lastSync != null)
                        Text(
                          '${Translations.get(languageCode, 'accountLastSync')}: ${cloud.store.lastSync!.toLocal()}',
                        ),
                      const SizedBox(height: 12),
                      Text(
                        Translations.get(languageCode, 'accountStorageBody'),
                      ),
                      if (cloud.anonymous)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            Translations.get(
                              languageCode,
                              'accountLinkGoogleBody',
                            ),
                          ),
                        ),
                      if (!cloud.anonymous) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: disabled ? null : cloud.sync,
                          icon: const Icon(Icons.sync),
                          label: Text(
                            Translations.get(languageCode, 'accountSyncNow'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (cloud.conflicts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  Translations.get(languageCode, 'accountConflictsTitle'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(Translations.get(languageCode, 'accountConflictsBody')),
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
                                            Translations.get(
                                              languageCode,
                                              'accountConflictCopy',
                                            ),
                                          ),
                                        ),
                                  child: Text(
                                    Translations.get(
                                      languageCode,
                                      'accountKeepBoth',
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
                                  Translations.get(
                                    languageCode,
                                    'accountKeepLocal',
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
                                  Translations.get(
                                    languageCode,
                                    'accountUseCloud',
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
                                  ? Translations.get(
                                      languageCode,
                                      'accountGoogleConnected',
                                    )
                                  : Translations.get(
                                      languageCode,
                                      'accountTitle',
                                    ),
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
                          title: Translations.get(languageCode, 'accountLogin'),
                          subtitle: Translations.get(
                            languageCode,
                            'accountLoginSubtitle',
                          ),
                          description: Translations.get(
                            languageCode,
                            'accountLoginBody',
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
                          title: Translations.get(
                            languageCode,
                            'accountRegister',
                          ),
                          subtitle: Translations.get(
                            languageCode,
                            'accountRegisterSubtitle',
                          ),
                          description: Translations.get(
                            languageCode,
                            'accountRegisterBody',
                          ),
                          emphasized: true,
                          onPressed: disabled || cloud.googlePending
                              ? null
                              : () => run(() => cloud.startGoogle(link: true)),
                        )
                      else
                        Text(
                          Translations.get(
                            languageCode,
                            'accountGoogleLinkedBody',
                          ),
                        ),
                      if (cloud.googlePending || cloud.googleIssue != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          cloud.googleIssue == null
                              ? Translations.get(
                                  languageCode,
                                  'accountGoogleWaitingBody',
                                )
                              : googleAuthErrorHelp(
                                  cloud.googleIssue!,
                                  languageCode: languageCode,
                                ),
                        ),
                        if (cloud.googleIssue != null)
                          SelectableText(
                            Translations.format(
                              languageCode,
                              'diagnosticCode',
                              {'code': cloud.googleIssue.toString()},
                            ),
                          ),
                        OutlinedButton(
                          onPressed: disabled
                              ? null
                              : () => run(cloud.cancelGoogle),
                          child: Text(
                            Translations.get(
                              languageCode,
                              'accountCancelGoogle',
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
                                    Translations.get(
                                      languageCode,
                                      'accountSignOutTitle',
                                    ),
                                    Translations.get(
                                      languageCode,
                                      'accountSignOutBody',
                                    ),
                                  )) {
                                    await cloud.signOut();
                                  }
                                }),
                          child: Text(
                            Translations.get(languageCode, 'accountSignOut'),
                          ),
                        ),
                      if (cloud.anonymous) ...[
                        const SizedBox(height: 12),
                        Text(
                          Translations.get(
                            languageCode,
                            'accountGoogleOptionalBody',
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
                  Translations.get(languageCode, 'guestCleanupTitle'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  cloud.guestCleanupError == null
                      ? Translations.get(
                          languageCode,
                          'guestCleanupSyncingBody',
                        )
                      : Translations.get(languageCode, 'guestCleanupErrorBody'),
                ),
                OutlinedButton(
                  onPressed: disabled ? null : cloud.sync,
                  child: Text(Translations.get(languageCode, 'retry')),
                ),
                const Divider(height: 24),
              ],
              Text(
                Translations.get(languageCode, 'backupFilesTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(Translations.get(languageCode, 'backupFilesBody')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: disabled ? null : () => run(() => export(cloud)),
                    icon: const Icon(Icons.download),
                    label: Text(
                      Translations.get(languageCode, 'backupExportAction'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: disabled ? null : () => run(() => import(cloud)),
                    icon: const Icon(Icons.upload),
                    label: Text(
                      Translations.get(languageCode, 'backupImportAction'),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: disabled || cloud.user == null
                        ? null
                        : () => run(() => history(cloud)),
                    child: Text(
                      Translations.get(languageCode, 'backupCloudVersions'),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: disabled
                        ? null
                        : () => run(() => localHistory(cloud)),
                    child: Text(
                      Translations.get(languageCode, 'backupLocalTitle'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              Text(
                Translations.get(languageCode, 'accountDelete'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(Translations.get(languageCode, 'accountDeleteSummary')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: disabled ? null : () => run(() => export(cloud)),
                icon: const Icon(Icons.download),
                label: Text(
                  Translations.get(languageCode, 'accountExportBeforeDelete'),
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
                  Translations.get(languageCode, 'accountDeleteAction'),
                ),
              ),
              const Divider(height: 40),
              PrivacyPolicyLink(languageCode: languageCode),
            ],
          ),
        ),
      ),
    );
  }
}
