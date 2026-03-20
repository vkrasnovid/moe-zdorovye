import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/record.dart';
import '../../providers/records_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/file_attachment.dart';
import '../../services/file_service.dart';
import '../add_record/add_record_screen.dart';

class RecordDetailScreen extends StatefulWidget {
  final MedicalRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  late MedicalRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _deleteAttachment(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить вложение?'),
        content: const Text('Файл будет удален из записи.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final newAttachments = List<String>.from(_record.attachments)..remove(path);
    final updated = _record.copyWith(attachments: newAttachments);
    await context.read<RecordsProvider>().updateRecord(updated);
    if (!mounted) return;
    setState(() => _record = updated);
    await FileService.deleteAttachment(path);
  }

  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddRecordScreen(editRecord: _record)),
    );
    if (!mounted) return;
    final provider = context.read<RecordsProvider>();
    final idx = provider.records.indexWhere((r) => r.id == _record.id);
    if (idx != -1) setState(() => _record = provider.records[idx]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_record.category.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildInfoCard(),
          if (_record.notes != null && _record.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNotesCard(),
          ],
          if (_record.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAttachmentsCard(),
          ],
          if (_record.extraData.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildExtraDataCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final color = _record.category.color;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_record.category.icon, color: color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _record.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _record.category.displayNameFull,
                style: TextStyle(fontSize: 13, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.calendar_today_outlined, 'Дата', AppFormatters.formatDate(_record.date)),
            _buildInfoRow(Icons.access_time_outlined, 'Добавлено', AppFormatters.formatDate(_record.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text('Заметки', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_record.notes!, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Вложения (${_record.attachments.length})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FileAttachmentList(
              paths: _record.attachments,
              onRemove: _deleteAttachment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraDataCard() {
    final labels = _extraLabels(_record.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._record.extraData.entries.map((e) {
              final label = labels[e.key] ?? e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Expanded(
                      child: Text(
                        e.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('«${_record.title}» будет удалена безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RecordsProvider>().deleteRecord(_record);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Map<String, String> _extraLabels(RecordCategory cat) {
    switch (cat) {
      case RecordCategory.tests:
        return {'lab': 'Лаборатория'};
      case RecordCategory.imaging:
        return {'type': 'Тип', 'body_area': 'Область тела', 'clinic': 'Клиника'};
      case RecordCategory.prescriptions:
        return {'doctor_name': 'Врач', 'specialty': 'Специальность', 'medications': 'Назначения'};
      case RecordCategory.vaccinations:
        return {'vaccine': 'Вакцина', 'dose': 'Доза', 'clinic': 'Клиника', 'next_dose': 'Следующая доза'};
      case RecordCategory.conditions:
        return {'severity': 'Степень тяжести'};
    }
  }
}
