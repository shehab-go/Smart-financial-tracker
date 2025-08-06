import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Get (and create if needed) the default backup directory under Downloads.
  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    // Try the broad MANAGE_EXTERNAL_STORAGE (Android 11+) first.
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    // Fallback to legacy storage permission for Android < 30
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<Directory> _getBackupDir() async {
    // Prefer downloads on Android; fall back to documents (desktop/tests).
    Directory baseDir;
    if (Platform.isAndroid) {
      // Ensure permission first
      await _ensureStoragePermission();
      // Use public Downloads folder on Android so the user can access via file managers.
      baseDir = Directory('/storage/emulated/0/Download');
    } else {
      // Fallback for other platforms.
      baseDir = (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(baseDir.path, 'FinanceApp', 'Backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Expose backup directory path for UI.
  Future<String> getBackupDirPath() async {
    final dir = await _getBackupDir();
    return dir.path;
  }

  Future<String> _getDbPath() async {
    final databasesPath = await getDatabasesPath();
    return p.join(databasesPath, 'finance_app.db');
  }

  /// Creates an incrementally-named backup file (db-<index>-yyyy-MM-dd.db).
  Future<File> createBackup() async {
    final dbPath = await _getDbPath();
    final backupDir = await _getBackupDir();

    // Determine next incremental number.
    final existing = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .map((f) => p.basenameWithoutExtension(f.path))
        .where((name) => name.startsWith('db-'))
        .map((name) {
          final parts = name.split('-');
          if (parts.length < 2) return -1;
          return int.tryParse(parts[1]) ?? -1;
        })
        .where((n) => n >= 0)
        .toList();
    final nextIndex = existing.isEmpty ? 0 : (existing.reduce((a, b) => a > b ? a : b) + 1);

    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final backupFileName = '$nextIndex-db-$dateStr.db';
    final backupPath = p.join(backupDir.path, backupFileName);

    final backupFile = await File(dbPath).copy(backupPath);
    return backupFile;
  }

  /// Returns list of backup files sorted by modified time desc.
  Future<List<File>> listBackups() async {
    final dir = await _getBackupDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Restores the selected backup (overwrites current DB).
  Future<void> restoreBackup(File backup) async {
    final dbPath = await _getDbPath();
    await File(dbPath).delete();
    await backup.copy(dbPath);
  }

  /// Shares the backup file using share_plus.
  Future<void> shareBackup(File backup) async {
    await Share.shareXFiles([XFile(backup.path)]);
  }
}
