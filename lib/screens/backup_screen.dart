import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';

import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late Future<List<File>> _backupsFuture;
  String? _dirPath;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _backupsFuture = BackupService.instance.listBackups();
    });
    BackupService.instance.getBackupDirPath().then(
      (value) => setState(() => _dirPath = value),
    );
  }

  Future<void> _createBackup() async {
    await BackupService.instance.createBackup();
    _refresh();
  }

  String _formatDate(DateTime dt) =>
      DateFormat('yyyy-MM-dd – HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة النسخ الاحتياطية')),
        body: FutureBuilder<List<File>>(
          future: _backupsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            }

            final backups = snapshot.data ?? [];
            if (backups.isEmpty) {
              return const Center(child: Text('لا توجد نسخ احتياطية بعد'));
            }

            return Column(
              children: [
                if (_dirPath != null)
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('Download/FinanceApp/Backups'),
                    onTap: () => OpenFile.open(_dirPath!),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: backups.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final file = backups[index];
                      final modified = file.lastModifiedSync();
                      final sizeKB =
                          (file.lengthSync() / 1024).toStringAsFixed(1);

                      return ListTile(
                        leading: const Icon(Icons.archive),
                        title: Text(p.basename(file.path)),
                        subtitle:
                            Text('${_formatDate(modified)} · $sizeKB KB'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore),
                              tooltip: 'استعادة',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('تأكيد الاستعادة'),
                                    content: const Text(
                                      'سيتم استبدال قاعدة البيانات الحالية بهذه النسخة، هل أنت متأكد؟',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('استعادة'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await BackupService.instance
                                      .restoreBackup(file);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'تمت الاستعادة بنجاح، أعد تشغيل التطبيق.'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              tooltip: 'مشاركة',
                              onPressed: () =>
                                  BackupService.instance.shareBackup(file),
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
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new',
          onPressed: _createBackup,
          label: const Text('إنشاء نسخة'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}