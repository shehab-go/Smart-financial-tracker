import 'dart:io';

import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;

import 'package:debit_credit_app/core/services/enhanced_backup_service.dart';
import 'package:debit_credit_app/core/services/google_drive_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class DriveBackupScreen extends StatefulWidget {
  const DriveBackupScreen({super.key});

  @override
  State<DriveBackupScreen> createState() => _DriveBackupScreenState();
}

class _DriveBackupScreenState extends State<DriveBackupScreen> {
  bool _isLoading = true;
  bool _isSignedIn = false;
  String? _userName;
  List<drive.File> _driveFiles = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final silent = await GoogleDriveService.instance.signInSilently();
    setState(() {
      _isSignedIn = silent;
      _userName = GoogleDriveService.instance.currentUser?.displayName;
      _isLoading = false;
    });
    if (silent) {
      await _refreshDriveList();
    }
  }

  Future<void> _signIn() async {
    setState(() => _isProcessing = true);
    final success = await GoogleDriveService.instance.signIn();
    setState(() {
      _isSignedIn = success;
      _userName = GoogleDriveService.instance.currentUser?.displayName;
      _isProcessing = false;
    });
    if (success) {
      await _refreshDriveList();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تسجيل الدخول إلى Google Drive'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await GoogleDriveService.instance.signOut();
    setState(() {
      _isSignedIn = false;
      _userName = null;
      _driveFiles = [];
    });
  }

  Future<void> _refreshDriveList() async {
    setState(() => _isLoading = true);
    final files = await GoogleDriveService.instance.listDriveBackups();
    setState(() {
      _driveFiles = files;
      _isLoading = false;
    });
  }

  Future<void> _uploadCurrentBackup() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري رفع النسخة الاحتياطية...'),
          ],
        ),
      ),
    );

    try {
      final backup = await EnhancedBackupService.instance.createBackup(
        description: 'رفع يدوي إلى Google Drive',
      );
      final success = await GoogleDriveService.instance.uploadBackup(backup);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم الرفع إلى Google Drive بنجاح' : 'فشل في الرفع إلى Google Drive'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) await _refreshDriveList();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الرفع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreFromDrive(drive.File driveFile) async {
    if (_isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('تأكيد الاستعادة من Drive'),
        content: Text('سيتم استبدال قاعدة البيانات الحالية بنسخة "${driveFile.name}" من Google Drive. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري التحميل من Google Drive...'),
          ],
        ),
      ),
    );

    try {
      final localFile = await GoogleDriveService.instance.downloadBackup(
        driveFile.id!,
        driveFile.name!,
      );

      if (localFile == null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في تحميل الملف من Drive'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      final result = await EnhancedBackupService.instance.restoreBackupSafely(localFile);

      // Clean up temp file
      try { await localFile.delete(); } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop();
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت الاستعادة بنجاح، سيتم إعادة تشغيل التطبيق الآن.'),
              backgroundColor: Colors.green,
            ),
          );
          Phoenix.rebirth(context);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('فشل في الاستعادة'),
                ],
              ),
              content: Text(result.errorMessage ?? 'حدث خطأ غير معروف'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('موافق')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاستعادة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteFromDrive(drive.File driveFile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('تأكيد الحذف من Drive'),
        content: Text('هل تريد حذف "${driveFile.name}" من Google Drive؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      final success = await GoogleDriveService.instance.deleteDriveBackup(driveFile.id!);
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم الحذف من Google Drive' : 'فشل في الحذف'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) await _refreshDriveList();
      }
    }
  }

  String _formatDriveDate(String? driveDate) {
    if (driveDate == null) return '';
    try {
      final dt = DateTime.parse(driveDate).toLocal();
      return DateFormat('yyyy-MM-dd – HH:mm').format(dt);
    } catch (_) {
      return driveDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.grey.shade700, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Google Drive'),
          actions: [
            if (_isSignedIn)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'تسجيل الخروج',
                onPressed: _isProcessing ? null : _signOut,
              ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: _isSignedIn
            ? FloatingActionButton.extended(
                heroTag: 'upload_drive',
                onPressed: _isProcessing ? null : _uploadCurrentBackup,
                backgroundColor: _isProcessing ? Colors.grey.shade300 : AppTheme.primaryColor,
                label: Text(
                  'رفع نسخة حالية',
                  style: TextStyle(
                    color: _isProcessing ? Colors.grey.shade600 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: _isProcessing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                        ),
                      )
                    : const Icon(Icons.cloud_upload, color: Colors.white, size: 24),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isSignedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لم يتم تسجيل الدخول إلى Google Drive',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'سجل الدخول لرفع واستعادة النسخ الاحتياطية',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _signIn,
              icon: _isProcessing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login),
              label: const Text('تسجيل الدخول باستخدام Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDriveList,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'متصل بـ Google Drive',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_userName != null)
                        Text(
                          'الحساب: $_userName',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _driveFiles.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد نسخ احتياطية في Drive'),
                        SizedBox(height: 8),
                        Text(
                          'اضغط على "رفع نسخة حالية" لإنشاء نسخة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _driveFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final file = _driveFiles[index];
                      final sizeKb = GoogleDriveService.instance.getFileSizeKb(file);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.cloud, color: AppTheme.primaryColor),
                          title: Text(
                            file.name ?? 'غير معروف',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${_formatDriveDate(file.modifiedTime?.toIso8601String())}${sizeKb != null ? ' • $sizeKb KB' : ''}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore, color: Colors.orange),
                                tooltip: 'استعادة',
                                onPressed: _isProcessing ? null : () => _restoreFromDrive(file),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'حذف من Drive',
                                onPressed: _isProcessing ? null : () => _deleteFromDrive(file),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
