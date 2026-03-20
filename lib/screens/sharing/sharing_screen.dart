import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/record.dart';
import '../../providers/records_provider.dart';
import '../../providers/profiles_provider.dart';
import '../../providers/measurements_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../services/backup_service.dart';
import '../../services/settings_service.dart';
import '../../services/sharing_service.dart';
import '../../utils/formatters.dart';

class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> with SingleTickerProviderStateMixin {
  final Set<int> _selectedIds = {};
  bool _serverRunning = false;
  String? _serverUrl;
  SharingService? _service;
  late TabController _tabController;

  // Backup state
  bool _backupLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _service?.stop();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          if (_serverRunning)
            TextButton(
              onPressed: _stopServer,
              child: const Text('Стоп', style: TextStyle(color: Colors.white)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Режим врача'),
            Tab(text: 'Резервная копия'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _serverRunning && _serverUrl != null ? _buildQrView() : _buildSelectionView(context),
          _buildBackupTab(),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    final settings = SettingsService.instance;
    return StatefulBuilder(
      builder: (context, setLocal) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Резервная копия section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Резервная копия', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_backupLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _exportBackup,
                          icon: const Icon(Icons.upload_outlined),
                          label: const Text('Создать резервную копию'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _importBackup,
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Восстановить из файла'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Автобекап section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Автобекап'),
                    subtitle: const Text('Автоматически создавать резервные копии'),
                    value: settings.autoBackupEnabled,
                    activeColor: const Color(0xFF00897B),
                    onChanged: (val) {
                      settings.autoBackupEnabled = val;
                      setLocal(() {});
                    },
                  ),
                  if (settings.autoBackupEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Частота'),
                      trailing: DropdownButton<String>(
                        value: settings.autoBackupFrequency,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Ежедневно')),
                          DropdownMenuItem(value: 'weekly', child: Text('Еженедельно')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            settings.autoBackupFrequency = val;
                            setLocal(() {});
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Последний бекап'),
                      subtitle: Text(
                        settings.lastAutoBackupAt != null
                            ? AppFormatters.formatDate(settings.lastAutoBackupAt!)
                            : 'Ещё не создавался',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.history, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBackup() async {
    debugPrint('[SharingScreen] DEBUG: export backup button tapped');
    setState(() => _backupLoading = true);
    try {
      final file = await BackupService.instance.exportBackup();
      debugPrint('[SharingScreen] INFO: export complete path=${file.path} size=${await file.length()}');
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], subject: 'МоёЗдоровье резервная копия');
      }
    } catch (e) {
      debugPrint('[SharingScreen] ERROR: export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания резервной копии: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _backupLoading = false);
    }
  }

  Future<void> _importBackup() async {
    debugPrint('[SharingScreen] DEBUG: import backup button tapped');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Восстановление'),
        content: const Text('Восстановление заменит все текущие данные. Продолжить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.first.path == null) return;

    setState(() => _backupLoading = true);
    try {
      await BackupService.instance.importBackup(File(result.files.first.path!));
      // Reload all providers
      if (mounted) {
        final profilesProvider = context.read<ProfilesProvider>();
        await profilesProvider.loadProfiles();
        final profileId = profilesProvider.activeProfileId;
        await context.read<RecordsProvider>().loadRecords(profileId: profileId);
        await context.read<MeasurementsProvider>().reloadAllForProfile(profileId);
        if (profileId != null) {
          await context.read<RemindersProvider>().loadReminders(profileId);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные успешно восстановлены'), backgroundColor: Colors.green),
        );
        debugPrint('[SharingScreen] INFO: import complete, providers reloaded');
      }
    } catch (e) {
      debugPrint('[SharingScreen] ERROR: import failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка восстановления: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _backupLoading = false);
    }
  }

  Widget _buildSelectionView(BuildContext context) {
    return Consumer<RecordsProvider>(
      builder: (context, provider, _) {
        final records = provider.records.isNotEmpty
            ? provider.records
            : context.read<RecordsProvider>().records;
        return Column(
          children: [
            Container(
              color: const Color(0xFFE0F2F1),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00897B), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Выберите записи для показа врачу. Оба устройства должны быть в одной Wi-Fi сети.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF00695C)),
                    ),
                  ),
                ],
              ),
            ),
            if (records.isEmpty)
              const Expanded(
                child: Center(child: Text('Нет записей для показа', style: TextStyle(color: Colors.grey))),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    if (record.id == null) return const SizedBox();
                    final selected = _selectedIds.contains(record.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (_) => setState(() {
                        if (selected) {
                          _selectedIds.remove(record.id);
                        } else {
                          _selectedIds.add(record.id!);
                        }
                      }),
                      title: Text(record.title, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        '${record.category.displayName} · ${AppFormatters.formatDate(record.date)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(record.category.icon, color: record.category.color, size: 20),
                      activeColor: const Color(0xFF00897B),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              final all = context.read<RecordsProvider>().records;
                              if (_selectedIds.length == all.length) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds.addAll(all.where((r) => r.id != null).map((r) => r.id!));
                              }
                            }),
                            child: const Text('Выбрать все'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedIds.isEmpty ? null : _startServer,
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: Text('QR (${_selectedIds.length})'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQrView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Покажите QR-код врачу',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Врач сканирует QR-код и видит выбранные записи в браузере',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: QrImageView(
                data: _serverUrl!,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF00897B),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF00695C),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Color(0xFF00897B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _serverUrl!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF00695C)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Сервер активен. Не закрывайте этот экран.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _stopServer,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Остановить сервер'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startServer() async {
    final records = context.read<RecordsProvider>().records
        .where((r) => r.id != null && _selectedIds.contains(r.id))
        .toList();

    try {
      _service = SharingService(records: records);
      final url = await _service!.start();
      setState(() {
        _serverRunning = true;
        _serverUrl = url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка запуска сервера: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _stopServer() {
    _service?.stop();
    setState(() {
      _serverRunning = false;
      _serverUrl = null;
    });
  }
}
