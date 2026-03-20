import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../models/record.dart';
import '../../providers/records_provider.dart';
import '../../services/file_service.dart';
import '../../widgets/file_attachment.dart';

class AddRecordScreen extends StatefulWidget {
  final RecordCategory? initialCategory;
  final MedicalRecord? editRecord;

  const AddRecordScreen({super.key, this.initialCategory, this.editRecord});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _extraControllers = <String, TextEditingController>{};

  late RecordCategory _selectedCategory;
  late DateTime _selectedDate;
  List<String> _attachments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.editRecord;
    _selectedCategory = edit?.category ?? widget.initialCategory ?? RecordCategory.tests;
    _selectedDate = edit?.date ?? DateTime.now();
    if (edit != null) {
      _titleController.text = edit.title;
      _notesController.text = edit.notes ?? '';
      _attachments = List.from(edit.attachments);
      for (final key in edit.extraData.keys) {
        _extraControllers[key] = TextEditingController(text: edit.extraData[key]?.toString() ?? '');
      }
    }
    _initExtraControllers();
  }

  void _initExtraControllers() {
    for (final field in _extraFieldsForCategory(_selectedCategory)) {
      _extraControllers.putIfAbsent(field['key']!, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final c in _extraControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editRecord != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать' : 'Новая запись'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            ..._buildExtraFields(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildAttachmentsSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Категория', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: RecordCategory.values.map((cat) {
            final selected = cat == _selectedCategory;
            return ChoiceChip(
              label: Text(cat.displayName),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                  _initExtraControllers();
                });
              },
              avatar: Icon(cat.icon, size: 16, color: selected ? Colors.white : cat.color),
              backgroundColor: cat.color.withAlpha(15),
              selectedColor: cat.color,
              labelStyle: TextStyle(
                color: selected ? Colors.white : cat.color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(labelText: 'Название *', hintText: 'Напр. Общий анализ крови'),
      validator: (v) => v == null || v.trim().isEmpty ? 'Введите название' : null,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Дата',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
      ),
    );
  }

  List<Widget> _buildExtraFields() {
    return _extraFieldsForCategory(_selectedCategory).map((field) {
      final controller = _extraControllers.putIfAbsent(
        field['key']!,
        () => TextEditingController(),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: field['label']),
          textCapitalization: TextCapitalization.sentences,
        ),
      );
    }).toList();
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Заметки',
        hintText: 'Дополнительная информация...',
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Вложения', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        FileAttachmentList(
          paths: _attachments,
          editable: true,
          onAdd: _pickFile,
          onRemove: (path) => setState(() => _attachments.remove(path)),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saving ? null : _save,
      child: _saving
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(widget.editRecord != null ? 'Сохранить' : 'Добавить запись'),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickFile() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF00897B)),
              title: const Text('Сфотографировать'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF00897B)),
              title: const Text('Из галереи'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF00897B)),
              title: const Text('Выбрать файл'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    String? savedPath;
    if (choice == 'camera') {
      final xFile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
      if (xFile != null) savedPath = await FileService.saveAttachment(File(xFile.path));
    } else if (choice == 'gallery') {
      final xFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (xFile != null) savedPath = await FileService.saveAttachment(File(xFile.path));
    } else {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result?.files.single.path != null) {
        savedPath = await FileService.saveAttachment(File(result!.files.single.path!));
      }
    }
    if (savedPath != null) setState(() => _attachments.add(savedPath!));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final extraData = <String, dynamic>{};
    for (final field in _extraFieldsForCategory(_selectedCategory)) {
      final key = field['key']!;
      final value = _extraControllers[key]?.text.trim() ?? '';
      if (value.isNotEmpty) extraData[key] = value;
    }

    final record = MedicalRecord(
      id: widget.editRecord?.id,
      category: _selectedCategory,
      title: _titleController.text.trim(),
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      attachments: _attachments,
      extraData: extraData,
    );

    final provider = context.read<RecordsProvider>();
    if (widget.editRecord != null) {
      await provider.updateRecord(record);
    } else {
      await provider.addRecord(record);
    }

    if (mounted) Navigator.pop(context);
  }

  List<Map<String, String>> _extraFieldsForCategory(RecordCategory cat) {
    switch (cat) {
      case RecordCategory.tests:
        return [
          {'key': 'lab', 'label': 'Лаборатория'},
        ];
      case RecordCategory.imaging:
        return [
          {'key': 'type', 'label': 'Тип снимка (Рентген, КТ, МРТ, УЗИ)'},
          {'key': 'body_area', 'label': 'Область тела'},
          {'key': 'clinic', 'label': 'Клиника'},
        ];
      case RecordCategory.prescriptions:
        return [
          {'key': 'doctor_name', 'label': 'Врач'},
          {'key': 'specialty', 'label': 'Специальность'},
          {'key': 'medications', 'label': 'Препараты / назначения'},
        ];
      case RecordCategory.vaccinations:
        return [
          {'key': 'vaccine', 'label': 'Название вакцины'},
          {'key': 'dose', 'label': 'Номер дозы'},
          {'key': 'clinic', 'label': 'Клиника / врач'},
          {'key': 'next_dose', 'label': 'Дата следующей дозы'},
        ];
      case RecordCategory.conditions:
        return [
          {'key': 'severity', 'label': 'Степень тяжести'},
        ];
    }
  }
}
