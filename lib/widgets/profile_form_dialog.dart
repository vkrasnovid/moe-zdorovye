import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/profiles_provider.dart';

class ProfileFormDialog extends StatefulWidget {
  final Profile? existingProfile;
  final List<String> existingNames;

  const ProfileFormDialog({
    super.key,
    this.existingProfile,
    required this.existingNames,
  });

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  static const _colors = [
    Color(0xFF1976D2), // blue
    Color(0xFF00897B), // teal
    Color(0xFFE53935), // red
    Color(0xFF7B1FA2), // purple
    Color(0xFFF57C00), // orange
    Color(0xFF388E3C), // green
    Color(0xFF5D4037), // brown
    Color(0xFF546E7A), // blue-grey
  ];

  late TextEditingController _nameController;
  late Color _selectedColor;
  String? _error;

  bool get _isEdit => widget.existingProfile != null;

  @override
  void initState() {
    super.initState();
    debugPrint('[ProfileFormDialog] DEBUG: dialog open mode=${_isEdit ? "edit" : "create"}');
    _nameController = TextEditingController(text: widget.existingProfile?.name ?? '');
    _selectedColor = widget.existingProfile != null
        ? Color(widget.existingProfile!.avatarColor)
        : _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    debugPrint('[ProfileFormDialog] DEBUG: form submit name="$name" color=${_selectedColor.value}');
    if (name.isEmpty) {
      debugPrint('[ProfileFormDialog] WARN: validation failed — name is empty');
      setState(() => _error = 'Имя профиля не может быть пустым');
      return;
    }
    if (widget.existingNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
      debugPrint('[ProfileFormDialog] WARN: validation failed — duplicate name "$name"');
      setState(() => _error = 'Профиль с таким именем уже существует');
      return;
    }
    setState(() => _error = null);
    final provider = context.read<ProfilesProvider>();
    if (_isEdit) {
      final updated = widget.existingProfile!.copyWith(name: name, avatarColor: _selectedColor.value);
      provider.updateProfile(updated).then((_) => Navigator.pop(context));
    } else {
      provider.createProfile(name, _selectedColor).then((_) => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'Редактировать профиль' : 'Новый профиль',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: 'Имя профиля',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          const Text('Цвет аватара', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _colors.map((color) {
              final isSelected = _selectedColor.value == color.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
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
    );
  }
}
