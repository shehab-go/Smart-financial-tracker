import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveBackupService {
  GoogleDriveBackupService._();
  static final GoogleDriveBackupService instance = GoogleDriveBackupService._();

  static const String backupFileNamePrefix = 'finance_app_backup_';
  static const String metadataFileName = 'finance_app_backup.json';

  static const String _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static const List<String> _scopes = <String>[drive.DriveApi.driveAppdataScope];

  static String? get _desktopClientId {
    if (kIsWeb) return null;
    if (Platform.isAndroid || Platform.isIOS) return null;
    return '68995492033-t9754odssr17isc9u0o403lgighu1o9k.apps.googleusercontent.com';
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _desktopClientId,
    scopes: _scopes,
  );

  Future<GoogleSignInAccount?> _silentAccount() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<GoogleSignInAccount?> _interactiveAccount() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: $e\nتحقق من اتصال الإنترنت وحساب Google');
    }
  }

  Future<GoogleSignInAccount> _requireAccount({required bool interactive}) async {
    final silent = await _silentAccount();
    if (silent != null) return silent;
    if (!interactive) {
      throw StateError('Not signed in');
    }
    final account = await _interactiveAccount();
    if (account == null) {
      throw StateError('User cancelled sign-in');
    }
    return account;
  }

  Future<GoogleSignInAccount?> signIn() async {
    return await _interactiveAccount();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<bool> isSignedIn() async {
    final account = await _silentAccount();
    return account != null;
  }

  Future<String?> currentEmail() async {
    final account = await _silentAccount();
    return account?.email;
  }

  Future<String?> currentPhotoUrl() async {
    final account = await _silentAccount();
    return account?.photoUrl;
  }

  static String _timestampedBackupName(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '${backupFileNamePrefix}${y}${m}${d}_${hh}${mm}${ss}.db';
  }

  static String _sanitizeBackupBaseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    // Replace path separators and other risky characters.
    final cleaned = trimmed.replaceAll(RegExp(r'[\\/\n\r\t]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<List<drive.File>> listBackups({bool interactive = false}) async {
    final account = await _requireAccount(interactive: interactive);
    final headers = await account.authHeaders;

    return await Isolate.run(() => _listBackupsBg(headers));
  }

  static Future<List<drive.File>> _listBackupsBg(Map<String, String> headers) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);
    final result = await api.files.list(
      q: "name contains '$backupFileNamePrefix' and trashed = false",
      orderBy: 'createdTime desc',
      spaces: 'appDataFolder',
      pageSize: 50,
      $fields: 'files(id,name,createdTime,modifiedTime,size)',
    );
    return (result.files ?? const <drive.File>[])
        .where((f) => f.id != null)
        .map((f) => drive.File(
              id: f.id,
              name: f.name,
              createdTime: f.createdTime,
              modifiedTime: f.modifiedTime,
              size: f.size,
            ))
        .toList();
  }

  Future<void> cleanupOldBackups({
    int keepCount = 5,
    bool interactive = false,
  }) async {
    final account = await _requireAccount(interactive: interactive);
    final headers = await account.authHeaders;

    await Isolate.run(() => _cleanupOldBackupsBg(headers, keepCount));
  }

  static Future<void> _cleanupOldBackupsBg(Map<String, String> headers, int keepCount) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);

    final result = await api.files.list(
      q: "name contains '$backupFileNamePrefix' and trashed = false",
      orderBy: 'createdTime desc',
      spaces: 'appDataFolder',
      pageSize: 50,
      $fields: 'files(id,name,createdTime,modifiedTime,size)',
    );
    final backups = (result.files ?? const <drive.File>[]).where((f) => f.id != null).toList();

    if (backups.length <= keepCount) return;
    final toDelete = backups.skip(keepCount);
    for (final f in toDelete) {
      if (f.id == null) continue;
      await api.files.delete(f.id!);
    }
  }

  Future<String> uploadBackupFile(
    File file, {
    int keepCount = 5,
    String? customName,
    bool interactive = true,
    bool promptIfNecessary = true,
  }) async {
    final account = await _requireAccount(interactive: interactive);
    final headers = await account.authHeaders;
    final filePath = file.path;

    return await Isolate.run(() => _uploadBackupFileBg(
          headers: headers,
          filePath: filePath,
          keepCount: keepCount,
          customName: customName,
        ));
  }

  static Future<String> _uploadBackupFileBg({
    required Map<String, String> headers,
    required String filePath,
    required int keepCount,
    required String? customName,
  }) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);
    final bgFile = File(filePath);

    final now = DateTime.now();
    final base = _sanitizeBackupBaseName(customName ?? '');
    final stampName = _timestampedBackupName(now);
    final name = base.isEmpty ? stampName : '${backupFileNamePrefix}${base}_' + stampName.substring(backupFileNamePrefix.length);

    final media = drive.Media(
      bgFile.openRead(),
      await bgFile.length(),
      contentType: 'application/octet-stream',
    );

    final created = await api.files.create(
      drive.File(name: name, parents: const <String>['appDataFolder']),
      uploadMedia: media,
      $fields: 'id,name',
    );
    if (created.id == null) {
      throw StateError('Failed to upload backup file to Drive');
    }

    try {
      final result = await api.files.list(
        q: "name contains '$backupFileNamePrefix' and trashed = false",
        orderBy: 'createdTime desc',
        spaces: 'appDataFolder',
        pageSize: 50,
        $fields: 'files(id,name,createdTime,modifiedTime,size)',
      );
      final backups = (result.files ?? const <drive.File>[]).where((f) => f.id != null).toList();
      if (backups.length > keepCount) {
        final toDelete = backups.skip(keepCount);
        for (final f in toDelete) {
          if (f.id == null) continue;
          await api.files.delete(f.id!);
        }
      }
    } catch (_) {
      // Cleanup failure should not fail a successful backup upload.
    }

    return created.id!;
  }

  Future<String> uploadMetadata(
    Map<String, dynamic> metadata, {
    bool interactive = true,
    bool promptIfNecessary = true,
  }) async {
    final account = await _requireAccount(interactive: interactive);
    final headers = await account.authHeaders;

    return await Isolate.run(() => _uploadMetadataBg(headers, metadata));
  }

  static Future<String> _uploadMetadataBg(Map<String, String> headers, Map<String, dynamic> metadata) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);

    // Find app data file by name (inlined _findAppDataFileByName)
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$metadataFileName' and trashed = false",
      $fields: 'files(id,name,modifiedTime,size,createdTime)',
      pageSize: 10,
    );
    final files = result.files;
    final existingMeta = (files == null || files.isEmpty) ? null : files.first;

    final bytes = utf8.encode(jsonEncode(metadata));
    final stream = Stream<List<int>>.value(bytes);
    final media = drive.Media(stream, bytes.length, contentType: 'application/json');

    if (existingMeta?.id != null) {
      final updated = await api.files.update(
        drive.File(name: metadataFileName),
        existingMeta!.id!,
        uploadMedia: media,
      );
      return updated.id ?? existingMeta.id!;
    }

    final created = await api.files.create(
      drive.File(name: metadataFileName, parents: const <String>['appDataFolder']),
      uploadMedia: media,
    );
    if (created.id == null) {
      throw StateError('Failed to create metadata file on Drive');
    }
    return created.id!;
  }

  Future<void> renameBackup({
    required String fileId,
    required String newName,
  }) async {
    final account = await _requireAccount(interactive: true);
    final headers = await account.authHeaders;

    await Isolate.run(() => _renameBackupBg(
          headers: headers,
          fileId: fileId,
          newName: newName,
        ));
  }

  static Future<void> _renameBackupBg({
    required Map<String, String> headers,
    required String fileId,
    required String newName,
  }) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('newName is empty');
    }
    final finalName = trimmed.toLowerCase().endsWith('.db') ? trimmed : '$trimmed.db';
    await api.files.update(
      drive.File(name: finalName),
      fileId,
      $fields: 'id,name',
    );
  }

  Future<void> deleteBackup(String fileId) async {
    final account = await _requireAccount(interactive: true);
    final headers = await account.authHeaders;

    await Isolate.run(() => _deleteBackupBg(headers, fileId));
  }

  static Future<void> _deleteBackupBg(Map<String, String> headers, String fileId) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);
    await api.files.delete(fileId);
  }

  Future<drive.File?> getLatestBackup({bool interactive = false}) async {
    final backups = await listBackups(interactive: interactive);
    if (backups.isEmpty) return null;
    return backups.first;
  }

  Future<File> downloadBackupTo(File destination, {String? fileId}) async {
    final account = await _requireAccount(interactive: true);
    final headers = await account.authHeaders;
    final destPath = destination.path;
    final effectiveFileId = fileId;

    final path = await Isolate.run(() => _downloadBackupToBg(
          headers: headers,
          destPath: destPath,
          fileId: effectiveFileId,
        ));
    return File(path);
  }

  static Future<String> _downloadBackupToBg({
    required Map<String, String> headers,
    required String destPath,
    required String? fileId,
  }) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);

    String? activeId = fileId;
    if (activeId == null || activeId.trim().isEmpty) {
      // Find latest backup
      final result = await api.files.list(
        q: "name contains '$backupFileNamePrefix' and trashed = false",
        orderBy: 'createdTime desc',
        spaces: 'appDataFolder',
        pageSize: 10,
        $fields: 'files(id,name,createdTime,modifiedTime,size)',
      );
      final backups = (result.files ?? const <drive.File>[])
          .where((f) => f.id != null)
          .toList();
      if (backups.isEmpty) {
        throw StateError('No backup found on Google Drive');
      }
      activeId = backups.first.id;
    }

    if (activeId == null) {
      throw StateError('No backup found on Google Drive');
    }

    final media = await api.files.get(activeId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final bgDest = File(destPath);
    final sink = bgDest.openWrite();
    await media.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    return bgDest.path;
  }

  Future<Map<String, dynamic>?> downloadMetadata() async {
    final account = await _requireAccount(interactive: true);
    final headers = await account.authHeaders;

    return await Isolate.run(() => _downloadMetadataBg(headers));
  }

  static Future<Map<String, dynamic>?> _downloadMetadataBg(Map<String, String> headers) async {
    final authClient = _GoogleAuthClient(headers);
    final api = drive.DriveApi(authClient);

    // Find metadata file
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$metadataFileName' and trashed = false",
      $fields: 'files(id,name,modifiedTime,size,createdTime)',
      pageSize: 10,
    );
    final files = result.files;
    final existingMeta = (files == null || files.isEmpty) ? null : files.first;
    if (existingMeta?.id == null) return null;

    final media = await api.files.get(existingMeta!.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final bytes = await media.stream.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
    final decoded = jsonDecode(utf8.decode(bytes));
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    request.headers['accept-encoding'] = 'identity';
    return _client.send(request);
  }
}
