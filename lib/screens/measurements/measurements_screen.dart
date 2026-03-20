import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/measurement.dart';
import '../../providers/measurements_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/measurement_chart.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  MeasurementType _selectedType = MeasurementType.bloodPressure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeasurementsProvider>().loadForType(_selectedType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Показатели здоровья')),
      body: Column(
        children: [
          _buildTypeSelector(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: MeasurementType.values.map((type) {
            final selected = type == _selectedType;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : const Color(0xFF00897B),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedType = type);
                  context.read<MeasurementsProvider>().loadForType(type);
                },
                backgroundColor: const Color(0xFF00897B).withAlpha(15),
                selectedColor: const Color(0xFF00897B),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<MeasurementsProvider>(
      builder: (context, provider, _) {
        final measurements = provider.getForType(_selectedType);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedType.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _selectedType.unit,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MeasurementChart(type: _selectedType, measurements: measurements),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (measurements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Нет записей', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...measurements.map((m) => _buildMeasurementItem(context, m)),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildMeasurementItem(BuildContext context, Measurement m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.monitor_heart_outlined, color: Color(0xFF00897B), size: 20),
        ),
        title: Text(m.displayValue, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(AppFormatters.formatDateTime(m.dateTime)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
          onPressed: () => _confirmDelete(context, m),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMeasurementSheet(
        type: _selectedType,
        onSaved: (m) => context.read<MeasurementsProvider>().addMeasurement(m),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Measurement m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('${m.displayValue} от ${AppFormatters.formatDate(m.dateTime)} будет удалена.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MeasurementsProvider>().deleteMeasurement(m);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _AddMeasurementSheet extends StatefulWidget {
  final MeasurementType type;
  final Function(Measurement) onSaved;

  const _AddMeasurementSheet({required this.type, required this.onSaved});

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _value2Controller = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dateTime = DateTime.now();

  @override
  void dispose() {
    _valueController.dispose();
    _value2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Добавить: ${type.displayName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (type.hasTwoValues) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valueController,
                      decoration: InputDecoration(labelText: type.valueName),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Введите значение';
                        if (double.tryParse(v.trim().replaceAll(',', '.')) == null) return 'Введите число';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _value2Controller,
                      decoration: InputDecoration(labelText: type.value2Name),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Введите значение';
                        if (double.tryParse(v.trim().replaceAll(',', '.')) == null) return 'Введите число';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ] else
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: '${type.displayName} (${type.unit})',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Введите значение';
                  if (double.tryParse(v.trim().replaceAll(',', '.')) == null) return 'Введите число';
                  return null;
                },
              ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата и время',
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: Text(DateFormat('dd.MM.yyyy HH:mm').format(_dateTime)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Заметки (необязательно)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time != null) {
      setState(() {
        _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    final value2 = widget.type.hasTwoValues
        ? double.tryParse(_value2Controller.text.replaceAll(',', '.'))
        : null;
    final m = Measurement(
      type: widget.type,
      value: value,
      value2: value2,
      dateTime: _dateTime,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    widget.onSaved(m);
    Navigator.pop(context);
  }
}
