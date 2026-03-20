import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/reminder.dart';
import '../../providers/profiles_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../utils/reminder_utils.dart';

class ReminderFormSheet extends StatefulWidget {
  final Reminder? existingReminder;
  const ReminderFormSheet({super.key, this.existingReminder});

  @override
  State<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<ReminderFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late ReminderType _type;
  late ScheduleType _scheduleType;
  late TimeOfDay _time;
  late int _weekdaysMask;
  DateTime? _dueDate;
  String? _titleError;

  bool get _isEdit => widget.existingReminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    debugPrint('[ReminderFormSheet] DEBUG: sheet open mode=${_isEdit ? "edit" : "create"}');
    _titleController = TextEditingController(text: r?.title ?? '');
    _bodyController = TextEditingController(text: r?.body ?? '');
    _type = r?.type ?? ReminderType.medication;
    _scheduleType = r?.scheduleType ?? ScheduleType.daily;
    _time = r?.time ?? const TimeOfDay(hour: 8, minute: 0);
    _weekdaysMask = r?.weekdaysMask ?? 0;
    _dueDate = r?.nextDueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    debugPrint('[ReminderFormSheet] DEBUG: form submit title="$title" type=${_type.name} scheduleType=${_scheduleType.name} time=${_time.format(context)} weekdaysMask=$_weekdaysMask dueDate=$_dueDate');

    if (title.isEmpty) {
      debugPrint('[ReminderFormSheet] WARN: validation failed — title empty');
      setState(() => _titleError = 'Введите название');
      return;
    }
    if ((_scheduleType == ScheduleType.weekly || _scheduleType == ScheduleType.custom) &&
        _weekdaysMask == 0) {
      debugPrint('[ReminderFormSheet] WARN: validation failed — no weekdays selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один день недели')),
      );
      return;
    }
    if (_scheduleType == ScheduleType.once && _dueDate == null) {
      debugPrint('[ReminderFormSheet] WARN: validation failed — no date for once reminder');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату напоминания')),
      );
      return;
    }
    setState(() => _titleError = null);

    final profileId = context.read<ProfilesProvider>().activeProfileId ?? 0;
    final timeMinutes = _time.hour * 60 + _time.minute;
    final provider = context.read<RemindersProvider>();

    if (_isEdit) {
      final updated = widget.existingReminder!.copyWith(
        type: _type,
        title: title,
        body: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
        scheduleType: _scheduleType,
        timeMinutes: timeMinutes,
        weekdaysMask: _weekdaysMask,
        nextDueDate: _dueDate,
      );
      await provider.updateReminder(updated);
    } else {
      final reminder = Reminder(
        profileId: profileId,
        type: _type,
        title: title,
        body: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
        scheduleType: _scheduleType,
        timeMinutes: timeMinutes,
        weekdaysMask: _weekdaysMask,
        nextDueDate: _dueDate,
      );
      await provider.addReminder(reminder);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Редактировать напоминание' : 'Новое напоминание',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Тип', border: OutlineInputBorder()),
              items: ReminderType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(reminderTypeLabel(t)),
              )).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Название',
                errorText: _titleError,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ScheduleType>(
              value: _scheduleType,
              decoration: const InputDecoration(labelText: 'Расписание', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: ScheduleType.once, child: Text('Один раз')),
                DropdownMenuItem(value: ScheduleType.daily, child: Text('Ежедневно')),
                DropdownMenuItem(value: ScheduleType.weekly, child: Text('Еженедельно')),
                DropdownMenuItem(value: ScheduleType.custom, child: Text('Выбрать дни')),
              ],
              onChanged: (v) => setState(() => _scheduleType = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Время напоминания'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: Text(_time.format(context), style: const TextStyle(fontSize: 16)),
              ),
            ),
            if (_scheduleType == ScheduleType.weekly || _scheduleType == ScheduleType.custom) ...[
              const Text('Дни недели', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _WeekdaySelector(
                mask: _weekdaysMask,
                onChanged: (mask) => setState(() => _weekdaysMask = mask),
              ),
              const SizedBox(height: 8),
            ],
            if (_scheduleType == ScheduleType.once) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Дата'),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: Text(
                    _dueDate != null
                        ? DateFormat('d MMM yyyy', 'ru').format(_dueDate!)
                        : 'Выбрать',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('ru'),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }
}

class _WeekdaySelector extends StatelessWidget {
  final int mask;
  final ValueChanged<int> onChanged;

  const _WeekdaySelector({required this.mask, required this.onChanged});

  static const _labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final bit = 1 << i;
        final selected = mask & bit != 0;
        return FilterChip(
          label: Text(_labels[i]),
          selected: selected,
          onSelected: (val) => onChanged(val ? mask | bit : mask & ~bit),
          selectedColor: const Color(0xFF00897B).withAlpha(60),
        );
      }),
    );
  }
}
