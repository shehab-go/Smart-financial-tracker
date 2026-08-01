import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:open_file/open_file.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:debit_credit_app/core/services/enhanced_backup_service.dart';
import 'package:debit_credit_app/core/services/google_drive_backup_service.dart';
import 'package:debit_credit_app/core/services/auto_backup_manager.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:debit_credit_app/core/db/database_helper.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class EnhancedBackupScreen extends StatefulWidget {
  final int initialTabIndex;
  const EnhancedBackupScreen({super.key, this.initialTabIndex = 0});

  @override
  State<EnhancedBackupScreen> createState() => _EnhancedBackupScreenState();
}

class _EnhancedBackupScreenState extends State<EnhancedBackupScreen> {
  // Local Backup State
  late Future<List<Map<String, dynamic>>> _localBackupsFuture;
  String? _localDirPath;
  bool _isLocalProcessing = false;

  // Google Drive State
  bool _driveLoading = true;
  bool _driveProcessing = false;
  String? _driveLoadError;
  String? _driveLoadStage;
  bool _driveSignedIn = false;
  String? _driveEmail;
  bool _driveEnabled = false;
  String _driveFrequency = 'daily';
  int? _driveLastBackupMs;
  List<drive.File> _driveBackups = const <drive.File>[];

  @override
  void initState() {
    super.initState();
    _refreshLocal();
    _loadDrive();
  }

  void _refreshLocal() {
    setState(() {
      _localBackupsFuture = EnhancedBackupService.instance.getBackupsWithMetadata();
    });
    EnhancedBackupService.instance.getBackupDirPath().then(
      (value) => setState(() => _localDirPath = value),
    );
  }

  Future<void> _loadDrive() async {
    if (!mounted) return;
    setState(() {
      _driveLoading = true;
      _driveLoadError = null;
      _driveLoadStage = 'جاري التحميل...';
    });

    try {
      if (!mounted) return;
      setState(() => _driveLoadStage = 'التحقق من اتصال Google...');
      final signedIn = await GoogleDriveBackupService.instance.isSignedIn().timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _driveLoadStage = 'قراءة تفاصيل الحساب...');
      String? email = await GoogleDriveBackupService.instance.currentEmail().timeout(const Duration(seconds: 15));

      if (email != null) {
        await DatabaseHelper().setMetaValue(AutoBackupManager.metaAccountEmail, email);
      } else {
        email = await DatabaseHelper().getMetaValue(AutoBackupManager.metaAccountEmail);
        if (email != null && email.isEmpty) {
          email = null;
        }
      }

      final effectivelySignedIn = signedIn || (email != null);

      if (!mounted) return;
      setState(() => _driveLoadStage = 'جلب إعدادات المزامنة...');
      final enabled = await AutoBackupManager.instance.isEnabled().timeout(const Duration(seconds: 10));
      final frequency = await AutoBackupManager.instance.getFrequency().timeout(const Duration(seconds: 10));
      final last = await AutoBackupManager.instance.getLastBackupMs().timeout(const Duration(seconds: 10));

      List<drive.File> backups = const <drive.File>[];
      if (effectivelySignedIn) {
        if (!mounted) return;
        setState(() => _driveLoadStage = 'جلب النسخ من السحابة...');
        try {
          backups = await GoogleDriveBackupService.instance.listBackups(interactive: false).timeout(const Duration(seconds: 25));
        } catch (e) {
          if (signedIn) {
            rethrow;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _driveSignedIn = effectivelySignedIn;
        _driveEmail = email;
        _driveEnabled = enabled;
        _driveFrequency = frequency;
        _driveLastBackupMs = last;
        _driveBackups = backups;
        _driveLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _driveLoadError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _driveLoading = false;
        _driveLoadStage = null;
      });
    }
  }

  // ==========================================
  // LOCAL BACKUP ACTIONS
  // ==========================================

  Future<void> _createLocalBackup() async {
    if (_isLocalProcessing) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLocalProcessing = true);
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('جاري إنشاء النسخة الاحتياطية...', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
              ],
            ),
          ),
        ),
      );
      
      await EnhancedBackupService.instance.createBackup(
        description: 'نسخة احتياطية يدوية محليّة',
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _refreshLocal();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLocalProcessing = false);
    }
  }

  Future<void> _restoreLocalBackup(File backupFile, Map<String, dynamic> backupInfo) async {
    if (_isLocalProcessing) return;
    
    HapticFeedback.vibrate();
    final metadata = backupInfo['metadata'] as BackupMetadata?;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('تأكيد الاستعادة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'سيتم استبدال قاعدة البيانات الحالية بهذه النسخة.',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
              ),
              const SizedBox(height: 16),
              if (metadata != null) ...[
                Text('اسم الملف: ${metadata.fileName}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                Text('تاريخ الإنشاء: ${_formatDate(metadata.createdAt)}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                Text('إصدار قاعدة البيانات: ${metadata.databaseVersion}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                Text('عدد السجلات: ${metadata.recordCount}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                Text('نوع النسخة: ${_getBackupTypeLabel(metadata.backupType)}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                if (metadata.description != null)
                  Text('الوصف: ${metadata.description}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
              ] else ...[
                Text('اسم الملف: ${backupInfo['fileName']}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                Text('تاريخ التعديل: ${_formatDate(backupInfo['lastModified'])}', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                Text('حجم الملف: ${backupInfo['sizeKB']} KB', style: const TextStyle(fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
              ],
              const SizedBox(height: 16),
              const Text(
                '⚠️ سيتم إنشاء نسخة احتياطية تلقائية من البيانات الحالية قبل الاستعادة.',
                style: TextStyle(color: AppTheme.warningColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('استعادة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLocalProcessing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري استعادة النسخة الاحتياطية...', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
              SizedBox(height: 8),
              Text(
                'يتم إنشاء نسخة احتياطية من البيانات الحالية أولاً',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'ArbFONTSIBMPlexArabicText'),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await EnhancedBackupService.instance.restoreBackupSafely(backupFile);
      
      if (mounted) {
        Navigator.of(context).pop();
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت الاستعادة بنجاح، سيتم إعادة تشغيل التطبيق الآن.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Phoenix.rebirth(context);
        } else {
          showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.error, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('فشل في الاستعادة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.errorMessage ?? 'حدث خطأ غير معروف', style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
                    if (result.preRestoreBackupPath != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'تم الاحتفاظ بالبيانات الأصلية دون تغيير.',
                        style: TextStyle(color: AppTheme.successColor, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: const Text('موافق'),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاستعادة: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLocalProcessing = false);
    }
  }

  Future<void> _deleteLocalBackup(File backupFile, String fileName) async {
    HapticFeedback.vibrate();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 16)),
          content: Text('هل تريد حذف النسخة الاحتياطية "$fileName"؟\n\nلا يمكن التراجع عن هذا الإجراء.', style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final success = await EnhancedBackupService.instance.deleteBackup(backupFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف النسخة الاحتياطية' : 'فشل في حذف النسخة الاحتياطية'),
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
        if (success) _refreshLocal();
      }
    }
  }

  Future<void> _cleanOldLocalBackups() async {
    HapticFeedback.vibrate();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('تنظيف النسخ القديمة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 16)),
          content: const Text('سيتم الاحتفاظ بآخر 10 نسخ احتياطية محليّة وحذف الباقي لتهيئة المساحة.\n\nهل تريد المتابعة؟', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('تنظيف', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    
    if (confirm == true) {
      await EnhancedBackupService.instance.cleanOldBackups();
      _refreshLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تنظيف النسخ القديمة بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  // ==========================================
  // GOOGLE DRIVE ACTIONS
  // ==========================================

  Future<void> _signInDrive() async {
    if (_driveProcessing) return;
    HapticFeedback.mediumImpact();
    setState(() => _driveProcessing = true);
    try {
      await GoogleDriveBackupService.instance.signIn();
      await _loadDrive();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _driveProcessing = false);
    }
  }

  Future<void> _signOutDrive() async {
    if (_driveProcessing) return;
    HapticFeedback.vibrate();
    setState(() => _driveProcessing = true);
    try {
      await GoogleDriveBackupService.instance.signOut();
      await _loadDrive();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الخروج: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _driveProcessing = false);
    }
  }

  Future<void> _setDriveEnabled(bool value) async {
    HapticFeedback.lightImpact();
    await AutoBackupManager.instance.setEnabled(value);
    await _loadDrive();
  }

  Future<void> _setDriveFrequency(String value) async {
    HapticFeedback.lightImpact();
    await AutoBackupManager.instance.setFrequency(value);
    await _loadDrive();
  }

  Future<void> _backupToDriveNow() async {
    if (_driveProcessing) return;
    HapticFeedback.mediumImpact();
    
    final nameController = TextEditingController();
    final customName = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('اسم النسخة الاحتياطية سحابياً', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 15)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'مثال: نسخة قبل التعديل السحابية',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text('تخطي'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, nameController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    setState(() => _driveProcessing = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري إنشاء ورفع النسخة سحابياً...', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
            ],
          ),
        ),
      ),
    );

    try {
      await AutoBackupManager.instance.runBackupNow(backupType: 'manual', customName: customName);
      
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
      }
      
      await _loadDrive();
      _refreshLocal(); 
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع النسخة الاحتياطية بنجاح إلى Google Drive'), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل النسخ الاحتياطي السحابي: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _driveProcessing = false);
    }
  }

  Future<void> _restoreFromDrive(String fileId) async {
    if (_driveProcessing) return;

    HapticFeedback.vibrate();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد الاستعادة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 16)),
          content: const Text('سيتم تحميل قاعدة البيانات من السحابة واستبدال الحالية بها. هل تريد المتابعة؟', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('استعادة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _driveProcessing = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل واستعادة النسخة السحابية...', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
            ],
          ),
        ),
      ),
    );

    try {
      final tempBackup = await AutoBackupManager.instance.downloadLatestBackupToTemp();
      await GoogleDriveBackupService.instance.downloadBackupTo(tempBackup, fileId: fileId);
      final result = await EnhancedBackupService.instance.restoreBackupSafely(tempBackup);

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الاستعادة بنجاح، سيتم إعادة تشغيل التطبيق.'), backgroundColor: AppTheme.successColor),
        );
        Phoenix.rebirth(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'فشل في الاستعادة'), backgroundColor: AppTheme.errorColor),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاستعادة السحابية: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _driveProcessing = false);
    }
  }

  Future<void> _restoreLatestFromDrive() async {
    if (_driveProcessing) return;

    HapticFeedback.vibrate();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد الاستعادة سحابياً', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 16)),
          content: const Text('سيتم تحميل واستعادة آخر نسخة محفوظة على Google Drive. هل تريد المتابعة؟', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('استعادة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _driveProcessing = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل واستعادة آخر نسخة من السحابة...', style: TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
            ],
          ),
        ),
      ),
    );

    try {
      final tempBackup = await AutoBackupManager.instance.downloadLatestBackupToTemp();
      final result = await EnhancedBackupService.instance.restoreBackupSafely(tempBackup);

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الاستعادة بنجاح، سيتم إعادة تشغيل التطبيق.'), backgroundColor: AppTheme.successColor),
        );
        Phoenix.rebirth(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'فشل في الاستعادة'), backgroundColor: AppTheme.errorColor),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاستعادة: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _driveProcessing = false);
    }
  }

  Future<void> _renameDriveBackup(String fileId, String currentName) async {
    if (_driveProcessing) return;
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إعادة تسمية النسخة سحابياً', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 16)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'اسم النسخة الجديد',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    setState(() => _driveProcessing = true);
    try {
      await GoogleDriveBackupService.instance.renameBackup(fileId: fileId, newName: newName.trim());
      await _loadDrive();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إعادة التسمية: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _driveProcessing = false);
    }
  }

  Future<void> _deleteDriveBackup(String fileId, String name) async {
    HapticFeedback.vibrate();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 16)),
          content: Text('هل تريد حذف النسخة "$name" من Google Drive نهائياً؟', style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _driveProcessing = true);
    try {
      await GoogleDriveBackupService.instance.deleteBackup(fileId);
      await _loadDrive();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف النسخة السحابية بنجاح'), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف النسخة: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _driveProcessing = false);
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

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
        return AppTheme.primaryColor;
      case 'auto':
        return AppTheme.successColor;
      case 'pre-restore':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) => DateFormat('yyyy-MM-dd – HH:mm').format(dt);

  String _formatDriveDate(String? driveDate) {
    if (driveDate == null) return '';
    try {
      final dt = DateTime.parse(driveDate).toLocal();
      return DateFormat('yyyy-MM-dd – HH:mm').format(dt);
    } catch (_) {
      return driveDate;
    }
  }

  String? _getDriveFileSizeKb(String? sizeStr) {
    if (sizeStr == null) return null;
    final size = int.tryParse(sizeStr);
    if (size == null) return null;
    return (size / 1024).toStringAsFixed(1);
  }

  String _formatDriveLastBackup() {
    if (_driveLastBackupMs == null) return 'غير متوفر';
    final dt = DateTime.fromMillisecondsSinceEpoch(_driveLastBackupMs!);
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ==========================================
  // WIDGET BUILDER
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'إدارة النسخ الاحتياطي',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: AppTheme.textPrimary,
                fontFamily: 'ArbFONTSIBMPlexArabicText',
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Soft slate background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    fontSize: 12.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                    fontSize: 12.5,
                  ),
                  tabs: const [
                    Tab(text: 'نسخ احتياطي محلي'),
                    Tab(text: 'نسخ احتياطي سحابي'),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                _buildLocalBackupTab(),
                _buildGoogleDriveTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB BUILDERS
  // ==========================================

  Widget _buildLocalBackupTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _localBackupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${snapshot.error}', style: const TextStyle(fontFamily: 'ArbFONTSIBMPlexArabicText')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshLocal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final backups = snapshot.data ?? [];
          return Column(
            children: [
              if (_localDirPath != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_open_rounded, color: AppTheme.primaryColor, size: 20),
                    ),
                    title: const Text('مجلد النسخ الاحتياطية المحلي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                    subtitle: Text(
                      _localDirPath!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryColor, size: 18),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      OpenFile.open(_localDirPath!);
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'النسخ الاحتياطية المحفوظة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontFamily: 'ArbFONTSIBMPlexArabicText',
                      ),
                    ),
                    if (backups.isNotEmpty)
                      TextButton.icon(
                        onPressed: _cleanOldLocalBackups,
                        icon: const Icon(Icons.cleaning_services_rounded, size: 14),
                        label: const Text(
                          'حذف النسخ التلقائية القديمة',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: backups.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.dividerColor.withOpacity(0.5),
                                width: 1,
                              ),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.archive_outlined,
                                    size: 64,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'لا توجد نسخ احتياطية محليّة بعد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'اضغط على الزر بالأسفل لإنشاء نسخة احتياطية محلية جديدة.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontFamily: 'ArbFONTSIBMPlexArabicText',
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: backups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final backupInfo = backups[index];
                          final file = backupInfo['file'] as File;
                          final metadata = backupInfo['metadata'] as BackupMetadata?;
                          final fileName = backupInfo['fileName'] as String;
                          final lastModified = backupInfo['lastModified'] as DateTime;
                          final sizeKB = backupInfo['sizeKB'] as String;

                          final typeColor = metadata != null 
                              ? _getBackupTypeColor(metadata.backupType)
                              : Colors.grey;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.dividerColor.withOpacity(0.5),
                                width: 1,
                              ),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.storage_rounded,
                                    color: typeColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_formatDate(lastModified)} • $sizeKB KB',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                      if (metadata != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: typeColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _getBackupTypeLabel(metadata.backupType),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: typeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'ArbFONTSIBMPlexArabicText',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'نسخة قاعدة بيانات ${metadata.databaseVersion}',
                                              style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(height: 1, color: AppTheme.dividerColor),
                                        const SizedBox(height: 12),
                                        if (metadata != null) ...[
                                          _buildInfoRow('عدد السجلات المخزنة', '${metadata.recordCount}'),
                                          _buildInfoRow('المجموع الاختباري (MD5)', metadata.checksum.length > 12 ? metadata.checksum.substring(0, 12) : metadata.checksum),
                                          if (metadata.description != null)
                                            _buildInfoRow('وصف النسخة', metadata.description!),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: ElevatedButton.icon(
                                                  onPressed: _isLocalProcessing ? null : () => _restoreLocalBackup(file, backupInfo),
                                                  icon: const Icon(Icons.restore_rounded, size: 14, color: Colors.white),
                                                  label: const Text('استعادة', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.warningColor,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    HapticFeedback.lightImpact();
                                                    EnhancedBackupService.instance.shareBackup(file);
                                                  },
                                                  icon: const Icon(Icons.share_rounded, size: 14, color: Colors.white),
                                                  label: const Text('مشاركة', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryColor,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _deleteLocalBackup(file, fileName),
                                                  icon: const Icon(Icons.delete_rounded, size: 14, color: Colors.white),
                                                  label: const Text('حذف', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.errorColor,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_local_backup',
        onPressed: _isLocalProcessing ? null : _createLocalBackup,
        backgroundColor: Colors.white,
        foregroundColor: _isLocalProcessing ? Colors.grey.shade500 : AppTheme.primaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _isLocalProcessing ? Colors.grey.shade400 : AppTheme.primaryColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        icon: _isLocalProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_to_photos_rounded),
        label: const Text('إنشاء نسخة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArbFONTSIBMPlexArabicText')),
      ),
    );
  }

  Widget _buildGoogleDriveTab() {
    if (_driveLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_driveLoadStage != null) ...[
              const SizedBox(height: 16),
              Text(
                _driveLoadStage!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'ArbFONTSIBMPlexArabicText'),
              ),
            ],
          ],
        ),
      );
    }

    if (_driveLoadError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.dividerColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.errorColor),
                ),
                const SizedBox(height: 24),
                const Text(
                  'فشل تحميل النسخ الاحتياطية السحابية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _driveLoadError!.contains('SocketException') || _driveLoadError!.contains('Failed host lookup')
                      ? 'يبدو أنك غير متصل بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
                      : 'حدث خطأ أثناء الاتصال بالخدمة. يرجى المحاولة مرة أخرى.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadDrive,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                  label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_driveSignedIn) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.dividerColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_queue_rounded, size: 64, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 24),
                const Text(
                  'النسخ الاحتياطي السحابي (Google Drive)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'قم بتسجيل الدخول بحساب Google لرفع واستعادة بياناتك سحابياً بشكل تلقائي وآمن لحمايتها من الضياع.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'ArbFONTSIBMPlexArabicText', height: 1.5),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _signInDrive,
                  icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                  label: const Text('ربط حساب Google Drive', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadDrive,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Connection Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cloud_done_rounded,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'متصل بـ Google Drive بنجاح',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                ),
                subtitle: Text(_driveEmail ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                trailing: TextButton.icon(
                  onPressed: _driveProcessing ? null : _signOutDrive,
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 16),
                  label: const Text('فصل الحساب', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'ArbFONTSIBMPlexArabicText')),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.dividerColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.sync_rounded,
                    title: 'النسخ الاحتياطي التلقائي سحابياً',
                    subtitle: 'آخر مزامنة ناجحة: ${_formatDriveLastBackup()}',
                    value: _driveEnabled,
                    onChanged: _driveProcessing ? null : (v) => _setDriveEnabled(v),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerColor),
                  _buildDropdownTile(
                    icon: Icons.schedule_rounded,
                    title: 'تكرار المزامنة التلقائية',
                    subtitle: 'يتم الرفع تلقائياً بالجدول المختار فور استخدام التطبيق',
                    value: _driveFrequency,
                    items: const {
                      'daily': 'يومياً',
                      'weekly': 'أسبوعياً',
                      'startup': 'عند التشغيل فقط',
                    },
                    onChanged: !_driveEnabled || _driveProcessing
                        ? null
                        : (v) {
                            if (v == null) return;
                            _setDriveFrequency(v);
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions Button Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _driveProcessing ? null : _backupToDriveNow,
                    icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                    label: const Text('رفع نسخة الآن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _driveProcessing ? null : _restoreLatestFromDrive,
                    icon: const Icon(Icons.cloud_download_rounded, color: AppTheme.primaryColor, size: 18),
                    label: const Text('استعادة آخر نسخة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontFamily: 'ArbFONTSIBMPlexArabicText', fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cloud Backups List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.dividerColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'ملفات النسخ الاحتياطي في Google Drive',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerColor),
                  if (_driveBackups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Text(
                        'لا توجد ملفات نسخ احتياطي سحابية مخزنة بعد.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _driveBackups.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.dividerColor),
                      itemBuilder: (context, index) {
                        final b = _driveBackups[index];
                        final id = b.id!;
                        final name = b.name ?? 'نسخة احتياطية';
                        final sizeKb = _getDriveFileSizeKb(b.size);

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.cloud_circle_rounded, color: AppTheme.primaryColor, size: 22),
                          ),
                          title: Text(
                            name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_formatDriveDate(b.modifiedTime?.toIso8601String())}${sizeKb != null ? ' • $sizeKb KB' : ''}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'إعادة تسمية',
                                icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor, size: 18),
                                onPressed: _driveProcessing ? null : () => _renameDriveBackup(id, name),
                              ),
                              IconButton(
                                tooltip: 'استعادة النسخة',
                                icon: const Icon(Icons.settings_backup_restore_rounded, color: AppTheme.warningColor, size: 18),
                                onPressed: _driveProcessing ? null : () => _restoreFromDrive(id),
                              ),
                              IconButton(
                                tooltip: 'حذف ملف سحابي',
                                icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor, size: 18),
                                onPressed: _driveProcessing ? null : () => _deleteDriveBackup(id, name),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary, fontFamily: 'ArbFONTSIBMPlexArabicText'),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor.withOpacity(0.8),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        activeTrackColor: AppTheme.primaryColor.withOpacity(0.2),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade200,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor.withOpacity(0.8),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontFamily: 'ArbFONTSIBMPlexArabicText',
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'ArbFONTSIBMPlexArabicText',
            ),
            onChanged: onChanged,
            items: items.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ==========================================
// CUSTOM UTILITY WIDGETS
// ==========================================

class TabBarViewListener extends StatefulWidget {
  final ValueChanged<int> onTabChanged;
  final Widget child;

  const TabBarViewListener({
    super.key,
    required this.onTabChanged,
    required this.child,
  });

  @override
  State<TabBarViewListener> createState() => _TabBarViewListenerState();
}

class _TabBarViewListenerState extends State<TabBarViewListener> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (newController != _controller) {
      _controller?.removeListener(_handleTabChange);
      _controller = newController;
      _controller?.addListener(_handleTabChange);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (_controller != null && !_controller!.indexIsChanging) {
      widget.onTabChanged(_controller!.index);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return empty widget or show widget depending on tab index
    final index = _controller?.index ?? 0;
    if (index == 0) {
      return widget.child;
    }
    return const SizedBox.shrink();
  }
}