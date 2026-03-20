import 'package:flutter/material.dart';

class ParsedResult {
  final int? id;
  final int recordId;
  final String testName;
  final String testNameNormalized;
  final double value;
  final String unit;
  final double? refMin;
  final double? refMax;
  final String flag; // normal / high / low
  final String testDate; // ISO date, e.g. "2024-01-15"
  final DateTime parsedAt;

  const ParsedResult({
    this.id,
    required this.recordId,
    required this.testName,
    required this.testNameNormalized,
    required this.value,
    required this.unit,
    this.refMin,
    this.refMax,
    required this.flag,
    required this.testDate,
    required this.parsedAt,
  });

  bool get isNormal => flag == 'normal';
  bool get isHigh => flag == 'high';
  bool get isLow => flag == 'low';

  Color get flagColor {
    switch (flag) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'low':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  IconData get flagIcon {
    switch (flag) {
      case 'high':
        return Icons.arrow_upward;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.check;
    }
  }

  String get flagLabel {
    switch (flag) {
      case 'high':
        return 'Повышен';
      case 'low':
        return 'Понижен';
      default:
        return 'Норма';
    }
  }

  ParsedResult copyWith({
    int? id,
    int? recordId,
    String? testName,
    String? testNameNormalized,
    double? value,
    String? unit,
    double? refMin,
    double? refMax,
    String? flag,
    String? testDate,
    DateTime? parsedAt,
  }) {
    return ParsedResult(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      testName: testName ?? this.testName,
      testNameNormalized: testNameNormalized ?? this.testNameNormalized,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      refMin: refMin ?? this.refMin,
      refMax: refMax ?? this.refMax,
      flag: flag ?? this.flag,
      testDate: testDate ?? this.testDate,
      parsedAt: parsedAt ?? this.parsedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'test_name': testName,
      'test_name_normalized': testNameNormalized,
      'value': value,
      'unit': unit,
      'ref_min': refMin,
      'ref_max': refMax,
      'flag': flag,
      'test_date': testDate,
      'parsed_at': parsedAt.millisecondsSinceEpoch,
    };
  }

  factory ParsedResult.fromMap(Map<String, dynamic> map) {
    return ParsedResult(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      testName: map['test_name'] as String,
      testNameNormalized: map['test_name_normalized'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      refMin: map['ref_min'] != null ? (map['ref_min'] as num).toDouble() : null,
      refMax: map['ref_max'] != null ? (map['ref_max'] as num).toDouble() : null,
      flag: map['flag'] as String,
      testDate: map['test_date'] as String,
      parsedAt: DateTime.fromMillisecondsSinceEpoch(map['parsed_at'] as int),
    );
  }
}
