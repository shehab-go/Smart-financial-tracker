import 'dart:convert';
import 'dart:io';

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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
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
      throw Exception('فشل تسجيل الدخول: تحقق من اتصال الإنترنت وحساب Google');
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

  Future<drive.DriveApi> _driveApi({required bool interactive, bool promptIfNecessary = false}) async {
    final account = await _requireAccount(interactive: interactive);
    final headers = await account.authHeaders;
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  Future<drive.File?> _findAppDataFileByName({
    required drive.DriveApi api,
    required String name,
  }) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$name' and trashed = false",
      $fields: 'files(id,name,modifiedTime,size,createdTime)',
      pageSize: 10,
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  String _timestampedBackupName(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '${backupFileNamePrefix}${y}${m}${d}_${hh}${mm}${ss}.db';
  }

  String _sanitizeBackupBaseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    // Replace path separators and other risky characters.
    final cleaned = trimmed.replaceAll(RegExp(r'[\\/\n\r\t]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<List<drive.File>> listBackups({bool interactive = false}) async {
    final api = await _driveApi(interactive: interactive, promptIfNecessary: interactive);
    final result = await api.files.list(
      q: "name contains '$backupFileNamePrefix' and trashed = false",
      orderBy: 'createdTime desc',
      spaces: 'appDataFolder',
      pageSize: 50,
      $fields: 'files(id,name,createdTime,modifiedTime,size)',
    );
    return (result.files ?? const <drive.File>[]).where((f) => f.id != null).toList();
  }

  Future<void> cleanupOldBackups({
    int keepCount = 5,
    bool interactive = false,
  }) async {
    final api = await _driveApi(interactive: interactive);
    final backups = await listBackups(interactive: interactive);
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
    final api = await _driveApi(interactive: interactive, promptIfNecessary: promptIfNecessary);

    final now = DateTime.now();
    final base = _sanitizeBackupBaseName(customName ?? '');
    final stampName = _timestampedBackupName(now);
    final name = base.isEmpty ? stampName : '${backupFileNamePrefix}${base}_' + stampName.substring(backupFileNamePrefix.length);

    final media = drive.Media(
      file.openRead(),
      await file.length(),
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
      await cleanupOldBackups(keepCount: keepCount, interactive: false);
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
    final api = await _driveApi(interactive: interactive, promptIfNecessary: promptIfNecessary);

    final existing = await _findAppDataFileByName(api: api, name: metadataFileName);
    final bytes = utf8.encode(jsonEncode(metadata));
    final stream = Stream<List<int>>.value(bytes);
    final media = drive.Media(stream, bytes.length, contentType: 'application/json');

    if (existing?.id != null) {
      final updated = await api.files.update(
        drive.File(name: metadataFileName),
        existing!.id!,
        uploadMedia: media,
      );
      return updated.id ?? existing.id!;
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
    final api = await _driveApi(interactive: true, promptIfNecessary: true);
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

  Future<drive.File?> getLatestBackup({bool interactive = false}) async {
    final backups = await listBackups(interactive: interactive);
    if (backups.isEmpty) return null;
    return backups.first;
  }

  Future<File> downloadBackupTo(File destination, {String? fileId}) async {
    final api = await _driveApi(interactive: true, promptIfNecessary: true);

    String? effectiveId = fileId;
    if (effectiveId == null || effectiveId.trim().isEmpty) {
      final latest = await getLatestBackup(interactive: false);
      effectiveId = latest?.id;
    }
    if (effectiveId == null) {
      throw StateError('No backup found on Google Drive');
    }

    final media = await api.files.get(effectiveId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    final sink = destination.openWrite();
    await media.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    return destination;
  }

  Future<Map<String, dynamic>?> downloadMetadata() async {
    final api = await _driveApi(interactive: true, promptIfNecessary: true);

    final existing = await _findAppDataFileByName(api: api, name: metadataFileName);
    if (existing?.id == null) return null;

    final media = await api.files.get(existing!.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
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
    return _client.send(request);
  }
}
