import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';

import 'package:debit_credit_app/core/services/enhanced_backup_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'drive_backup_screen.dart';

class EnhancedBackupScreen extends StatefulWidget {
  const EnhancedBackupScreen({super.key});

  @override
  State<EnhancedBackupScreen> createState() => _EnhancedBackupScreenState();
}

class _EnhancedBackupScreenState extends State<EnhancedBackupScreen> {
  late Future<List<Map<String, dynamic>>> _backupsFuture;
  String? _dirPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _backupsFuture = EnhancedBackupService.instance.getBackupsWithMetadata();
    });
    EnhancedBackupService.instance.getBackupDirPath().then(
      (value) => setState(() => _dirPath = value),
    );
  }

  Future<void> _createBackup() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري إنشاء النسخة الاحتياطية...'),
            ],
          ),
        ),
      );
      
      await EnhancedBackupService.instance.createBackup(
        description: 'نسخة احتياطية يدوية',
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreBackup(File backupFile, Map<String, dynamic> backupInfo) async {
    if (_isProcessing) return;
    
    // Show detailed confirmation dialog
    final metadata = backupInfo['metadata'] as BackupMetadata?;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('تأكيد الاستعادة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم استبدال قاعدة البيانات الحالية بهذه النسخة.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (metadata != null) ...[
              Text('اسم الملف: ${metadata.fileName}'),
              Text('تاريخ الإنشاء: ${DateFormat('yyyy-MM-dd – HH:mm').format(metadata.createdAt)}'),
              Text('إصدار قاعدة البيانات: ${metadata.databaseVersion}'),
              Text('عدد السجلات: ${metadata.recordCount}'),
              Text('نوع النسخة: ${_getBackupTypeLabel(metadata.backupType)}'),
              if (metadata.description != null)
                Text('الوصف: ${metadata.description}'),
            ] else ...[
              Text('اسم الملف: ${backupInfo['fileName']}'),
              Text('تاريخ التعديل: ${DateFormat('yyyy-MM-dd – HH:mm').format(backupInfo['lastModified'])}'),
              Text('حجم الملف: ${backupInfo['sizeKB']} KB'),
            ],
            const SizedBox(height: 16),
            const Text(
              '⚠️ سيتم إنشاء نسخة احتياطية تلقائية من البيانات الحالية قبل الاستعادة.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
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

    // Show progress dialog with steps
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري استعادة النسخة الاحتياطية...'),
            SizedBox(height: 8),
            Text(
              'يتم إنشاء نسخة احتياطية من البيانات الحالية أولاً',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      final result = await EnhancedBackupService.instance.restoreBackupSafely(backupFile);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        if (result.success) {
          // Automatically restart the app to apply the restored database
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت الاستعادة بنجاح، سيتم إعادة تشغيل التطبيق الآن.'),
              backgroundColor: Colors.green,
            ),
          );
          Phoenix.rebirth(context);
        } else {
          // Show error dialog
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.errorMessage ?? 'حدث خطأ غير معروف'),
                  if (result.preRestoreBackupPath != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'تم الاحتفاظ بالبيانات الأصلية دون تغيير.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('موافق'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاستعادة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteBackup(File backupFile, String fileName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف النسخة الاحتياطية "$fileName"؟\n\nلا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await EnhancedBackupService.instance.deleteBackup(backupFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف النسخة الاحتياطية' : 'فشل في حذف النسخة الاحتياطية'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _refresh();
      }
    }
  }

  String _getBackupTypeLabel(String backupType) {
    switch (backupType) {
      case 'manual':
        return 'يدوية';
      case 'auto':
        return 'تلقائية';
      case 'pre-restore':
        return 'قبل الاستعادة';
      default:
        return backupType;
    }
  }

  Color _getBackupTypeColor(String backupType) {
    switch (backupType) {
      case 'manual':
        return Colors.blue;
      case 'auto':
        return Colors.green;
      case 'pre-restore':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) => DateFormat('yyyy-MM-dd – HH:mm').format(dt);

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
          title: const Text('إدارة النسخ الاحتياطية المتقدمة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.cloud),
              tooltip: 'Google Drive',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriveBackupScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'تنظيف النسخ القديمة',
              onPressed: _isProcessing ? null : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text('تنظيف النسخ القديمة'),
                    content: const Text('سيتم الاحتفاظ بآخر 10 نسخ احتياطية وحذف الباقي.\n\nهل تريد المتابعة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('تنظيف'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await EnhancedBackupService.instance.cleanOldBackups();
                  _refresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تنظيف النسخ القديمة'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _backupsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('خطأ: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final backups = snapshot.data ?? [];
              if (backups.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد نسخ احتياطية بعد'),
                      SizedBox(height: 8),
                      Text(
                        'اضغط على زر "+" لإنشاء أول نسخة احتياطية',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  if (_dirPath != null)
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.folder, color: AppTheme.primaryColor),
                        title: const Text('مجلد النسخ الاحتياطية'),
                        subtitle: Text(_dirPath!),
                        trailing: Icon(Icons.open_in_new, color: AppTheme.primaryColor),
                        onTap: () => OpenFile.open(_dirPath!),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: backups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final backupInfo = backups[index];
                        final file = backupInfo['file'] as File;
                        final metadata = backupInfo['metadata'] as BackupMetadata?;
                        final fileName = backupInfo['fileName'] as String;
                        final lastModified = backupInfo['lastModified'] as DateTime;
                        final sizeKB = backupInfo['sizeKB'] as String;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.archive,
                              color: metadata != null 
                                  ? _getBackupTypeColor(metadata.backupType)
                                  : Colors.grey,
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_formatDate(lastModified)} • $sizeKB KB'),
                                if (metadata != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getBackupTypeColor(metadata.backupType).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getBackupTypeLabel(metadata.backupType),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getBackupTypeColor(metadata.backupType),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'إصدار ${metadata.databaseVersion}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (metadata != null) ...[
                                      _buildInfoRow('عدد السجلات', '${metadata.recordCount}'),
                                      _buildInfoRow('المجموع الاختباري', metadata.checksum.substring(0, 8)),
                                      if (metadata.description != null)
                                        _buildInfoRow('الوصف', metadata.description!),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: ElevatedButton.icon(
                                              onPressed: _isProcessing ? null : () => _restoreBackup(file, backupInfo),
                                              icon: const Icon(Icons.restore, size: 16),
                                              label: const Text('استعادة', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: ElevatedButton.icon(
                                              onPressed: () => EnhancedBackupService.instance.shareBackup(file),
                                              icon: const Icon(Icons.share, size: 16),
                                              label: const Text('مشاركة', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: ElevatedButton.icon(
                                              onPressed: () => _deleteBackup(file, fileName),
                                              icon: const Icon(Icons.delete, size: 16),
                                              label: const Text('حذف', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: SafeArea(
          top: false,
          child: FloatingActionButton.extended(
            heroTag: 'create_backup',
            onPressed: _isProcessing ? null : _createBackup,
            backgroundColor: Colors.white,
            foregroundColor: _isProcessing ? Colors.grey.shade500 : AppTheme.primaryColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: _isProcessing ? Colors.grey.shade400 : AppTheme.primaryColor,
                width: 1.4,
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
                : const Icon(Icons.add),
            label: const Text('إنشاء نسخة جديدة'),
          ),
        ),
      )
    );

    
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}