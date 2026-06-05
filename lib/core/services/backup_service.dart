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
    // Only request the regular storage permission; do not use MANAGE_EXTERNAL_STORAGE.
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<Directory> _getBackupDir() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      await _ensureStoragePermission();
      // Use app-specific external storage directory on Android to avoid All Files access.
      baseDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
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

    final backupFileList = await backupDir.list().toList();
    final existing = backupFileList
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

  Future<List<BackupFileItem>> listBackups() async {
    final dir = await _getBackupDir();
    final backupFileList = await dir.list().toList();
    final files = backupFileList
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();
        
    final items = await Future.wait(
      files.map((file) async {
        final time = await file.lastModified();
        final size = await file.length();
        return BackupFileItem(file, time, size);
      }),
    );
    
    items.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return items;
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

class BackupFileItem {
  final File file;
  final DateTime lastModified;
  final int sizeInBytes;

  BackupFileItem(this.file, this.lastModified, this.sizeInBytes);
}
