import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  GoogleDriveService._();
  static final GoogleDriveService instance = GoogleDriveService._();

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  static const String _backupFolderName = 'FinanceApp_Backups';
  String? _backupFolderId;

  GoogleSignIn get _signIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        drive.DriveApi.driveFileScope,
        drive.DriveApi.driveAppdataScope,
      ],
    );
    return _googleSignIn!;
  }

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Get current user info
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _signIn.signIn();
      if (_currentUser == null) return false;

      final authClient = await _signIn.authenticatedClient();
      if (authClient == null) {
        await signOut();
        return false;
      }

      _driveApi = drive.DriveApi(authClient);
      await _ensureBackupFolder();
      return true;
    } catch (e) {
      debugPrint('Google Drive sign in error: $e');
      // User-friendly Arabic error message can be shown in UI
      throw Exception('فشل تسجيل الدخول: تحقق من اتصال الإنترنت وحساب Google');
    }
  }

  /// Silent sign in (for app restart)
  Future<bool> signInSilently() async {
    try {
      _currentUser = await _signIn.signInSilently();
      if (_currentUser == null) return false;

      final authClient = await _signIn.authenticatedClient();
      if (authClient == null) return false;

      _driveApi = drive.DriveApi(authClient);
      await _ensureBackupFolder();
      return true;
    } catch (e) {
      debugPrint('Google Drive silent sign in error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _signIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _backupFolderId = null;
  }

  /// Ensure backup folder exists in Drive
  Future<void> _ensureBackupFolder() async {
    if (_driveApi == null) return;

    try {
      final query = "mimeType='application/vnd.google-apps.folder' and name='$_backupFolderName' and trashed=false";
      final result = await _driveApi!.files.list(q: query, spaces: 'drive');
      if (result.files != null && result.files!.isNotEmpty) {
        _backupFolderId = result.files!.first.id;
        return;
      }

      // Create folder
      final folder = drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await _driveApi!.files.create(folder);
      _backupFolderId = created.id;
    } catch (e) {
      debugPrint('Error ensuring backup folder: $e');
    }
  }

  /// Upload a backup file to Google Drive
  Future<bool> uploadBackup(File file) async {
    if (_driveApi == null || _backupFolderId == null) return false;

    try {
      final fileName = p.basename(file.path);

      // Check if file already exists
      final existingQuery = "name='$fileName' and '$_backupFolderId' in parents and trashed=false";
      final existing = await _driveApi!.files.list(q: existingQuery, spaces: 'drive');

      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_backupFolderId!];

      if (existing.files != null && existing.files!.isNotEmpty) {
        // Update existing file
        final existingId = existing.files!.first.id!;
        await _driveApi!.files.update(driveFile, existingId, uploadMedia: media);
      } else {
        // Create new file
        await _driveApi!.files.create(driveFile, uploadMedia: media);
      }
      return true;
    } catch (e) {
      debugPrint('Error uploading backup to Drive: $e');
      // User-friendly Arabic error message
      throw Exception('فشل رفع النسخة: تحقق من مساحة التخزين المتاحة والاتصال بالإنترنت');
    }
  }

  /// List backups from Google Drive
  Future<List<drive.File>> listDriveBackups() async {
    if (_driveApi == null || _backupFolderId == null) return [];

    try {
      final query = "'$_backupFolderId' in parents and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        orderBy: 'modifiedTime desc',
      );
      return result.files ?? [];
    } catch (e) {
      debugPrint('Error listing Drive backups: $e');
      return [];
    }
  }

  /// Download a backup from Google Drive
  Future<File?> downloadBackup(String driveFileId, String fileName) async {
    if (_driveApi == null) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = p.join(tempDir.path, fileName);
      final localFile = File(localPath);

      final response = await _driveApi!.files.get(
        driveFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      await localFile.writeAsBytes(bytes);
      return localFile;
    } catch (e) {
      debugPrint('Error downloading backup from Drive: $e');
      // User-friendly Arabic error message
      throw Exception('فشل تحميل النسخة: تحقق من اتصال الإنترنت وصلاحيات الوصول');
    }
  }

  /// Delete a backup from Google Drive
  Future<bool> deleteDriveBackup(String driveFileId) async {
    if (_driveApi == null) return false;

    try {
      await _driveApi!.files.delete(driveFileId);
      return true;
    } catch (e) {
      debugPrint('Error deleting Drive backup: $e');
      // User-friendly Arabic error message
      throw Exception('فشل حذف النسخة: تحقق من اتصال الإنترنت وصلاحيات الوصول');
    }
  }

  /// Get Drive file size in KB
  String? getFileSizeKb(drive.File file) {
    final size = file.size;
    if (size == null) return null;
    return (int.parse(size) / 1024).toStringAsFixed(1);
  }
}
