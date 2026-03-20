import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/record.dart';
import '../../providers/records_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/file_attachment.dart';
import '../add_record/add_record_screen.dart';

class RecordDetailScreen extends StatelessWidget {
  final MedicalRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(record.category.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddRecordScreen(editRecord: record),
              ),
            ),
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
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNotesCard(),
          ],
          if (record.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAttachmentsCard(),
          ],
          if (record.extraData.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildExtraDataCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final color = record.category.color;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(record.category.icon, color: color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                record.category.displayNameFull,
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
            _buildInfoRow(Icons.calendar_today_outlined, 'Дата', AppFormatters.formatDate(record.date)),
            _buildInfoRow(Icons.access_time_outlined, 'Добавлено', AppFormatters.formatDate(record.createdAt)),
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
            Text(record.notes!, style: const TextStyle(fontSize: 14, height: 1.5)),
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
                  'Вложения (${record.attachments.length})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FileAttachmentList(paths: record.attachments),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraDataCard() {
    final labels = _extraLabels(record.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...record.extraData.entries.map((e) {
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
        content: Text('«${record.title}» будет удалена безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RecordsProvider>().deleteRecord(record);
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
