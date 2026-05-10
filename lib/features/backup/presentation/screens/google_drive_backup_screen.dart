import 'package:flutter/material.dart';

import 'package:debit_credit_app/core/services/auto_backup_manager.dart';
import 'package:debit_credit_app/core/services/enhanced_backup_service.dart';
import 'package:debit_credit_app/core/services/google_drive_backup_service.dart';
import 'package:debit_credit_app/core/theme/app_theme.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class GoogleDriveBackupScreen extends StatefulWidget {
  const GoogleDriveBackupScreen({super.key});

  @override
  State<GoogleDriveBackupScreen> createState() => _GoogleDriveBackupScreenState();
}

class _GoogleDriveBackupScreenState extends State<GoogleDriveBackupScreen> {
  bool _loading = true;
  bool _processing = false;

  String? _loadError;
  String? _loadStage;

  bool _signedIn = false;
  String? _email;

  bool _enabled = false;
  String _frequency = 'daily';
  int? _lastBackupMs;

  List<dynamic> _driveBackups = const <dynamic>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
      _loadStage = 'loading';
    });

    try {
      if (!mounted) return;
      setState(() => _loadStage = 'checking sign-in');
      final signedIn = await GoogleDriveBackupService.instance.isSignedIn().timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _loadStage = 'reading account');
      final email = await GoogleDriveBackupService.instance.currentEmail().timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _loadStage = 'reading settings');
      final enabled = await AutoBackupManager.instance.isEnabled().timeout(const Duration(seconds: 10));
      final frequency = await AutoBackupManager.instance.getFrequency().timeout(const Duration(seconds: 10));
      final last = await AutoBackupManager.instance.getLastBackupMs().timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _loadStage = 'loading backups');
      final backups = signedIn
          ? await GoogleDriveBackupService.instance.listBackups(interactive: true).timeout(const Duration(seconds: 25))
          : const <dynamic>[];

      if (!mounted) return;
      setState(() {
        _signedIn = signedIn;
        _email = email;
        _enabled = enabled;
        _frequency = frequency;
        _lastBackupMs = last;
        _driveBackups = backups;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadStage = null;
      });
    }
  }

  Future<void> _renameBackup(String fileId, String currentName) async {
    if (_processing) return;
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إعادة تسمية النسخة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'اسم النسخة',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (newName == null) return;

    setState(() => _processing = true);
    try {
      await GoogleDriveBackupService.instance.renameBackup(fileId: fileId, newName: newName);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إعادة التسمية: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _restoreBackupById(String fileId) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text('سيتم استبدال قاعدة البيانات الحالية بهذه النسخة. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('استعادة')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      final tempBackup = await AutoBackupManager.instance.downloadLatestBackupToTemp();
      await GoogleDriveBackupService.instance.downloadBackupTo(tempBackup, fileId: fileId);
      final result = await EnhancedBackupService.instance.restoreBackupSafely(tempBackup);

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الاستعادة بنجاح، سيتم إعادة تشغيل التطبيق.'), backgroundColor: Colors.green),
        );
        Phoenix.rebirth(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'فشل في الاستعادة'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاستعادة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _signIn() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await GoogleDriveBackupService.instance.signIn();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _signOut() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await GoogleDriveBackupService.instance.signOut();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الخروج: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _setEnabled(bool value) async {
    await AutoBackupManager.instance.setEnabled(value);
    await _load();
  }

  Future<void> _setFrequency(String value) async {
    await AutoBackupManager.instance.setFrequency(value);
    await _load();
  }

  Future<void> _backupNow() async {
    if (_processing) return;
    final nameController = TextEditingController();
    final customName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('اسم النسخة الاحتياطية'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'مثال: نسخة قبل التعديل',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('تخطي')),
          ElevatedButton(onPressed: () => Navigator.pop(context, nameController.text), child: const Text('حفظ')),
        ],
      ),
    );

    setState(() => _processing = true);
    try {
      await AutoBackupManager.instance.runBackupNow(backupType: 'manual', customName: customName);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع النسخة الاحتياطية إلى Google Drive'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل النسخ الاحتياطي: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _formatLastBackup() {
    if (_lastBackupMs == null) return 'غير متوفر';
    final dt = DateTime.fromMillisecondsSinceEpoch(_lastBackupMs!);
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _restoreFromDrive() async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text('سيتم استبدال قاعدة البيانات الحالية بآخر نسخة من Google Drive. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('استعادة')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      final tempBackup = await AutoBackupManager.instance.downloadLatestBackupToTemp();
      final result = await EnhancedBackupService.instance.restoreBackupSafely(tempBackup);

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الاستعادة بنجاح، سيتم إعادة تشغيل التطبيق.'), backgroundColor: Colors.green),
        );
        Phoenix.rebirth(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'فشل في الاستعادة'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاستعادة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          title: const Text('Google Drive Backup'),
        ),
        body: SafeArea(
          top: false,
          child: _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (_loadStage != null) ...[
                        const SizedBox(height: 12),
                        Text(_loadStage!),
                      ],
                    ],
                  ),
                )
              : _loadError != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 36, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            'فشل تحميل النسخ من Google Drive',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _processing ? null : _load,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.account_circle),
                            title: Text(_signedIn ? 'متصل' : 'غير متصل'),
                            subtitle: Text(_email ?? ''),
                            trailing: _signedIn
                                ? TextButton(
                                    onPressed: _processing ? null : _signOut,
                                    child: const Text('تسجيل خروج'),
                                  )
                                : ElevatedButton(
                                    onPressed: _processing ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('تسجيل دخول'),
                                  ),
                          ),
                          const Divider(height: 0),
                          SwitchListTile(
                            value: _enabled,
                            onChanged: !_signedIn || _processing ? null : (v) => _setEnabled(v),
                            title: const Text('النسخ الاحتياطي التلقائي إلى Google Drive'),
                            subtitle: Text('آخر نسخة: ${_formatLastBackup()}'),
                          ),
                          ListTile(
                            title: const Text('تكرار النسخ الاحتياطي'),
                            subtitle: const Text('يتم التنفيذ عند فتح التطبيق/العودة للتطبيق'),
                            trailing: DropdownButton<String>(
                              value: _frequency,
                              onChanged: !_signedIn || !_enabled || _processing
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      _setFrequency(v);
                                    },
                              items: const [
                                DropdownMenuItem(value: 'daily', child: Text('يومي')),
                                DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                                DropdownMenuItem(value: 'startup', child: Text('عند التشغيل فقط')),
                              ],
                              underline: Container(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: (!_signedIn || _processing) ? null : _backupNow,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('نسخ احتياطي الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: (!_signedIn || _processing) ? null : _restoreFromDrive,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('استعادة آخر نسخة من Google Drive'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'النسخ الموجودة على Google Drive',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(height: 0),
                          if (!_signedIn)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('سجّل الدخول لعرض النسخ.'),
                            )
                          else if (_driveBackups.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('لا توجد نسخ على Google Drive بعد.'),
                            )
                          else
                            ..._driveBackups.map((b) {
                              final id = (b as dynamic).id as String?;
                              final name = (b as dynamic).name as String?;
                              if (id == null || name == null) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.archive),
                                    title: Text(name),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'إعادة تسمية',
                                          icon: const Icon(Icons.edit),
                                          onPressed: _processing ? null : () => _renameBackup(id, name),
                                        ),
                                        IconButton(
                                          tooltip: 'استعادة',
                                          icon: const Icon(Icons.restore),
                                          onPressed: _processing ? null : () => _restoreBackupById(id),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 0),
                                ],
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
