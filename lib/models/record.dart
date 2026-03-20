import 'dart:convert';
import 'category.dart';
export 'category.dart';

class MedicalRecord {
  final int? id;
  final RecordCategory category;
  final String title;
  final DateTime date;
  final String? notes;
  final List<String> attachments;
  final Map<String, dynamic> extraData;
  final DateTime createdAt;

  MedicalRecord({
    this.id,
    required this.category,
    required this.title,
    required this.date,
    this.notes,
    List<String>? attachments,
    Map<String, dynamic>? extraData,
    DateTime? createdAt,
  })  : attachments = attachments ?? [],
        extraData = extraData ?? {},
        createdAt = createdAt ?? DateTime.now();

  MedicalRecord copyWith({
    int? id,
    RecordCategory? category,
    String? title,
    DateTime? date,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? extraData,
    DateTime? createdAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      extraData: extraData ?? this.extraData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category.name,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'attachments': jsonEncode(attachments),
      'extra_data': jsonEncode(extraData),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] as int?,
      category: RecordCategoryExtension.fromName(map['category'] as String),
      title: map['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      attachments: List<String>.from(jsonDecode(map['attachments'] as String? ?? '[]')),
      extraData: Map<String, dynamic>.from(jsonDecode(map['extra_data'] as String? ?? '{}')),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
