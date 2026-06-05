import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import '../db/database_helper.dart';
import 'enhanced_backup_service.dart';
import 'google_drive_backup_service.dart';

class AutoBackupManager {
  AutoBackupManager._();
  static final AutoBackupManager instance = AutoBackupManager._();

  static const String workmanagerTaskName = 'gdriveAutoBackup';
  static const String workmanagerUniqueName = 'gdrive_auto_backup';

  static const String metaEnabled = 'gdrive_backup_enabled';
  static const String metaFrequency = 'gdrive_backup_frequency';
  static const String metaLastBackupMs = 'gdrive_last_backup_ms';
  static const String metaAccountEmail = 'gdrive_account_email';

  bool _isRunning = false;

  Future<File> _copyDatabaseToTemp() async {
    // Run VACUUM to optimize the database size before backing up
    try {
      await DatabaseHelper().vacuum();
    } catch (_) {}

    final dbPath = p.join(await getDatabasesPath(), 'finance_app.db');
    final tmpDir = await getTemporaryDirectory();
    final dst = File(p.join(tmpDir.path, 'finance_app_upload.db'));
    return await File(dbPath).copy(dst.path);
  }

  Future<void> _syncWorkmanagerSchedule() async {
    if (!Platform.isAndroid) return;

    final enabled = await isEnabled();
    if (!enabled) {
      await Workmanager().cancelByUniqueName(workmanagerUniqueName);
      return;
    }

    final frequency = await getFrequency();
    if (frequency == 'startup') {
      await Workmanager().cancelByUniqueName(workmanagerUniqueName);
      return;
    }

    final Duration interval = frequency == 'weekly'
        ? const Duration(days: 7)
        : const Duration(hours: 24);

    await Workmanager().registerPeriodicTask(
      workmanagerUniqueName,
      workmanagerTaskName,
      frequency: interval,
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresCharging: true,
      ),
    );
  }

  Future<bool> isEnabled() async {
    final raw = await DatabaseHelper().getMetaValue(metaEnabled);
    return raw == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await DatabaseHelper().setMetaValue(metaEnabled, enabled ? 'true' : 'false');

    await _syncWorkmanagerSchedule();
  }

  Future<String> getFrequency() async {
    final raw = await DatabaseHelper().getMetaValue(metaFrequency);
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'daily';
    return v;
  }

  Future<void> setFrequency(String value) async {
    await DatabaseHelper().setMetaValue(metaFrequency, value.trim());
    await _syncWorkmanagerSchedule();
  }

  Future<int?> getLastBackupMs() async {
    final raw = await DatabaseHelper().getMetaValue(metaLastBackupMs);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> _setLastBackupMs(int ms) async {
    await DatabaseHelper().setMetaValue(metaLastBackupMs, ms.toString());
  }

  Future<void> _setAccountEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      await DatabaseHelper().setMetaValue(metaAccountEmail, '');
      return;
    }
    await DatabaseHelper().setMetaValue(metaAccountEmail, email.trim());
  }

  bool _isDue({
    required String frequency,
    required int? lastBackupMs,
    required DateTime now,
    required String trigger,
  }) {
    if (frequency == 'startup') {
      return trigger == 'startup';
    }

    if (lastBackupMs == null) return true;

    final last = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
    final diff = now.difference(last);

    if (frequency == 'weekly') {
      return diff.inDays >= 7;
    }

    return diff.inHours >= 24;
  }

  Future<File> runBackupNow({
    String backupType = 'auto',
    String? customName,
    bool interactive = true,
    bool promptIfNecessary = true,
  }) async {
    // In background isolate we should not request runtime permissions or rely on external storage.
    // So we copy the DB to a temp file and upload that.
    final File backup;
    if (!interactive) {
      backup = await _copyDatabaseToTemp();
    } else {
      backup = await EnhancedBackupService.instance.createBackup(
        backupType: backupType,
        description: backupType == 'manual' ? 'نسخة Google Drive يدوية' : 'نسخة Google Drive تلقائية',
      );
    }

    final driveFileId = await GoogleDriveBackupService.instance.uploadBackupFile(
      backup,
      customName: customName,
      interactive: interactive,
      promptIfNecessary: promptIfNecessary,
    );
    await GoogleDriveBackupService.instance.uploadMetadata({
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      'driveFileId': driveFileId,
      'localBackupFileName': backup.uri.pathSegments.isNotEmpty ? backup.uri.pathSegments.last : null,
      'sizeBytes': await backup.length(),
    }, interactive: interactive, promptIfNecessary: promptIfNecessary);

    await _setLastBackupMs(DateTime.now().millisecondsSinceEpoch);
    await _setAccountEmail(await GoogleDriveBackupService.instance.currentEmail());

    return backup;
  }

  Future<void> maybeRunAutoBackup({required String trigger}) async {
    if (_isRunning) return;
    _isRunning = true;
    try {
      final enabled = await isEnabled().timeout(const Duration(seconds: 10));
      if (!enabled) return;

      final signedIn = await GoogleDriveBackupService.instance.isSignedIn().timeout(const Duration(seconds: 10));
      if (!signedIn) return;

      final frequency = await getFrequency().timeout(const Duration(seconds: 5));
      final last = await getLastBackupMs().timeout(const Duration(seconds: 5));
      final now = DateTime.now();

      if (!_isDue(frequency: frequency, lastBackupMs: last, now: now, trigger: trigger)) {
        return;
      }

      await runBackupNow(backupType: 'auto').timeout(const Duration(minutes: 2));
    } finally {
      _isRunning = false;
    }
  }

  Future<File> downloadLatestBackupToTemp() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}finance_app_backup_latest.db');
    return await GoogleDriveBackupService.instance.downloadBackupTo(file);
  }
}
