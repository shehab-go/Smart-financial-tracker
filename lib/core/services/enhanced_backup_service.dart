import 'dart:io';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

import '../db/database_helper.dart';
import '../db/migration_helper.dart';

/// Backup metadata model
class BackupMetadata {
  final String fileName;
  final DateTime createdAt;
  final int databaseVersion;
  final String checksum;
  final int recordCount;
  final String backupType; // manual, auto, pre-restore
  final String? description;
  final Map<String, int> tableCounts;

  BackupMetadata({
    required this.fileName,
    required this.createdAt,
    required this.databaseVersion,
    required this.checksum,
    required this.recordCount,
    required this.backupType,
    this.description,
    required this.tableCounts,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'createdAt': createdAt.toIso8601String(),
    'databaseVersion': databaseVersion,
    'checksum': checksum,
    'recordCount': recordCount,
    'backupType': backupType,
    'description': description,
    'tableCounts': tableCounts,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    fileName: json['fileName'],
    createdAt: DateTime.parse(json['createdAt']),
    databaseVersion: json['databaseVersion'],
    checksum: json['checksum'],
    recordCount: json['recordCount'],
    backupType: json['backupType'],
    description: json['description'],
    tableCounts: Map<String, int>.from(json['tableCounts'] ?? {}),
  );
}

/// Restore operation result
class RestoreResult {
  final bool success;
  final String? errorMessage;
  final String? preRestoreBackupPath;
  final BackupMetadata? restoredBackupMetadata;

  RestoreResult({
    required this.success,
    this.errorMessage,
    this.preRestoreBackupPath,
    this.restoredBackupMetadata,
  });
}

/// Enhanced backup service with professional restore workflow
/// 
/// Features:
/// - Automatic pre-restore backup creation
/// - Database integrity validation
/// - Rollback functionality
/// - Backup metadata management
/// - Database switching with safety checks
class EnhancedBackupService {
  EnhancedBackupService._();
  static final EnhancedBackupService instance = EnhancedBackupService._();

  static const String _metadataFileName = 'backup_metadata.json';
  static const String _preRestoreBackupPrefix = 'pre-restore';
  static const String _autoBackupPrefix = 'auto';
  static const String _manualBackupPrefix = 'manual';

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

  /// Calculate MD5 checksum of a file
  Future<String> _calculateChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Get database statistics
  Future<Map<String, int>> _getDatabaseStats() async {
    final db = await DatabaseHelper().database;
    final stats = <String, int>{};
    
    final tables = ['accounts', 'transactions', 'categories', 'currencies', 'user_profile', 'persons'];
    
    for (final table in tables) {
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        stats[table] = result.first['count'] as int;
      } catch (e) {
        // Table might not exist in older versions
        stats[table] = 0;
      }
    }
    
    return stats;
  }

  /// Get total record count across all tables
  Future<int> _getTotalRecordCount() async {
    final stats = await _getDatabaseStats();
    return stats.values.fold<int>(0, (sum, count) => sum + count);
  }

  /// Create backup with metadata
  Future<File> createBackup({
    String backupType = 'manual',
    String? description,
  }) async {
    final dbPath = await _getDbPath();
    final backupDir = await _getBackupDir();

    // Generate backup filename
    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
    final backupFileName = '${backupType}-db-$dateStr-$timeStr.db';
    final backupPath = p.join(backupDir.path, backupFileName);

    // Create backup file
    final backupFile = await File(dbPath).copy(backupPath);
    
    // Generate metadata
    final checksum = await _calculateChecksum(backupFile);
    final recordCount = await _getTotalRecordCount();
    final tableCounts = await _getDatabaseStats();
    
    final metadata = BackupMetadata(
      fileName: backupFileName,
      createdAt: now,
      databaseVersion: MigrationHelper.currentVersion,
      checksum: checksum,
      recordCount: recordCount,
      backupType: backupType,
      description: description,
      tableCounts: tableCounts,
    );

    // Save metadata
    await _saveBackupMetadata(metadata);

    return backupFile;
  }

  /// Save backup metadata
  Future<void> _saveBackupMetadata(BackupMetadata metadata) async {
    final backupDir = await _getBackupDir();
    final metadataFile = File(p.join(backupDir.path, _metadataFileName));
    
    List<BackupMetadata> allMetadata = [];
    if (await metadataFile.exists()) {
      try {
        final content = await metadataFile.readAsString();
        final jsonList = jsonDecode(content) as List;
        allMetadata = jsonList.map((json) => BackupMetadata.fromJson(json)).toList();
      } catch (e) {
        // If metadata file is corrupted, start fresh
        print('Warning: Corrupted metadata file, starting fresh: $e');
      }
    }
    
    // Add new metadata
    allMetadata.add(metadata);
    
    // Sort by creation date (newest first)
    allMetadata.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Save updated metadata
    final jsonString = jsonEncode(allMetadata.map((m) => m.toJson()).toList());
    await metadataFile.writeAsString(jsonString);
  }

  /// Load backup metadata
  Future<List<BackupMetadata>> _loadBackupMetadata() async {
    final backupDir = await _getBackupDir();
    final metadataFile = File(p.join(backupDir.path, _metadataFileName));
    
    if (!await metadataFile.exists()) {
      return [];
    }
    
    try {
      final content = await metadataFile.readAsString();
      final jsonList = jsonDecode(content) as List;
      return jsonList.map((json) => BackupMetadata.fromJson(json)).toList();
    } catch (e) {
      print('Error loading backup metadata: $e');
      return [];
    }
  }

  /// Get backup metadata for a specific file
  Future<BackupMetadata?> getBackupMetadata(String fileName) async {
    final allMetadata = await _loadBackupMetadata();
    try {
      return allMetadata.firstWhere((m) => m.fileName == fileName);
    } catch (e) {
      return null;
    }
  }

  /// Validate database integrity
  Future<bool> validateDatabaseIntegrity(String dbPath) async {
    try {
      final db = await openDatabase(dbPath, readOnly: true);
      
      // Check if database can be opened
      await db.rawQuery('SELECT COUNT(*) FROM sqlite_master');
      
      // Check essential tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      final requiredTables = {'accounts', 'transactions', 'categories', 'currencies'};
      
      if (!requiredTables.every((table) => tableNames.contains(table))) {
        await db.close();
        return false;
      }
      
      // Check database version compatibility
      final version = await db.getVersion();
      if (version > MigrationHelper.currentVersion) {
        await db.close();
        return false; // Future version, not compatible
      }
      
      await db.close();
      return true;
    } catch (e) {
      print('Database validation failed: $e');
      return false;
    }
  }

  /// Professional restore with automatic backup creation
  Future<RestoreResult> restoreBackupSafely(File backupFile) async {
    String? preRestoreBackupPath;
    
    try {
      // Step 1: Validate backup file integrity
      if (!await validateDatabaseIntegrity(backupFile.path)) {
        return RestoreResult(
          success: false,
          errorMessage: 'ملف النسخة الاحتياطية تالف أو غير متوافق',
        );
      }
      
      // Step 2: Create pre-restore backup of current database
      final preRestoreBackup = await createBackup(
        backupType: _preRestoreBackupPrefix,
        description: 'نسخة احتياطية تلقائية قبل الاستعادة من ${p.basename(backupFile.path)}',
      );
      preRestoreBackupPath = preRestoreBackup.path;
      
      // Step 3: Get backup metadata
      final backupMetadata = await getBackupMetadata(p.basename(backupFile.path));
      
      // Step 4: Close current database connection
      await DatabaseHelper().close();
      
      // Step 5: Replace database file
      final dbPath = await _getDbPath();
      final currentDbFile = File(dbPath);
      
      if (await currentDbFile.exists()) {
        await currentDbFile.delete();
      }
      
      await backupFile.copy(dbPath);
      
      // Step 6: Validate restored database
      if (!await validateDatabaseIntegrity(dbPath)) {
        // Rollback: restore pre-restore backup
        await File(preRestoreBackupPath).copy(dbPath);
        return RestoreResult(
          success: false,
          errorMessage: 'فشل في التحقق من سلامة قاعدة البيانات المستعادة، تم التراجع',
          preRestoreBackupPath: preRestoreBackupPath,
        );
      }
      
      // Step 7: Initialize new database connection (this will trigger migrations if needed)
      await DatabaseHelper().database;
      
      return RestoreResult(
        success: true,
        preRestoreBackupPath: preRestoreBackupPath,
        restoredBackupMetadata: backupMetadata,
      );
      
    } catch (e) {
      // Rollback if pre-restore backup exists
      if (preRestoreBackupPath != null) {
        try {
          final dbPath = await _getDbPath();
          await File(preRestoreBackupPath).copy(dbPath);
        } catch (rollbackError) {
          print('Rollback failed: $rollbackError');
        }
      }
      
      return RestoreResult(
        success: false,
        errorMessage: 'خطأ أثناء الاستعادة: $e',
        preRestoreBackupPath: preRestoreBackupPath,
      );
    }
  }

  /// Switch to a different database backup
  Future<RestoreResult> switchToBackup(File backupFile) async {
    return await restoreBackupSafely(backupFile);
  }

  /// List all backups with metadata
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

  /// Get enhanced backup list with metadata
  Future<List<Map<String, dynamic>>> getBackupsWithMetadata() async {
    final files = await listBackups();
    final metadata = await _loadBackupMetadata();
    
    return files.map((file) {
      final fileName = p.basename(file.path);
      final meta = metadata.cast<BackupMetadata?>().firstWhere(
        (m) => m?.fileName == fileName,
        orElse: () => null,
      );
      
      return {
        'file': file,
        'metadata': meta,
        'fileName': fileName,
        'lastModified': file.lastModifiedSync(),
        'sizeKB': (file.lengthSync() / 1024).toStringAsFixed(1),
      };
    }).toList();
  }

  /// Delete backup and its metadata
  Future<bool> deleteBackup(File backupFile) async {
    try {
      final fileName = p.basename(backupFile.path);
      
      // Remove from metadata
      final allMetadata = await _loadBackupMetadata();
      final updatedMetadata = allMetadata.where((m) => m.fileName != fileName).toList();
      
      final backupDir = await _getBackupDir();
      final metadataFile = File(p.join(backupDir.path, _metadataFileName));
      
      if (updatedMetadata.isNotEmpty) {
        final jsonString = jsonEncode(updatedMetadata.map((m) => m.toJson()).toList());
        await metadataFile.writeAsString(jsonString);
      } else {
        // Delete metadata file if no backups left
        if (await metadataFile.exists()) {
          await metadataFile.delete();
        }
      }
      
      // Delete backup file
      await backupFile.delete();
      
      return true;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }

  /// Share backup file
  Future<void> shareBackup(File backup) async {
    await Share.shareXFiles([XFile(backup.path)]);
  }

  /// Clean old backups (keep only specified number of recent backups)
  Future<void> cleanOldBackups({int keepCount = 10}) async {
    final files = await listBackups();
    
    if (files.length <= keepCount) return;
    
    final filesToDelete = files.skip(keepCount).toList();
    
    for (final file in filesToDelete) {
      await deleteBackup(file);
    }
  }

  /// Create automatic backup (called periodically)
  Future<File> createAutoBackup() async {
    return await createBackup(
      backupType: _autoBackupPrefix,
      description: 'نسخة احتياطية تلقائية',
    );
  }
}