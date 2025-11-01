import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<Directory> _getBackupDir() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      await _ensureStoragePermission();
      baseDir = Directory('/storage/emulated/0/Download');
    } else {
      baseDir = (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(baseDir.path, 'FinanceApp', 'Backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> getBackupDirPath() async {
    final dir = await _getBackupDir();
    return dir.path;
  }

  Future<String> _getDbPath() async {
    final databasesPath = await getDatabasesPath();
    return p.join(databasesPath, 'finance_app.db');
  }

  Future<File> createBackup() async {
    final dbPath = await _getDbPath();
    final backupDir = await _getBackupDir();

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

  Future<void> restoreBackup(File backup) async {
    final dbPath = await _getDbPath();
    await File(dbPath).delete();
    await backup.copy(dbPath);
  }

  Future<void> shareBackup(File backup) async {
    await Share.shareXFiles([XFile(backup.path)]);
  }
}
