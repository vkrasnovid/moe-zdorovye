enum MeasurementType {
  bloodPressure,
  weight,
  temperature,
  bloodSugar,
  heartRate,
}

extension MeasurementTypeExtension on MeasurementType {
  String get name {
    switch (this) {
      case MeasurementType.bloodPressure:
        return 'bloodPressure';
      case MeasurementType.weight:
        return 'weight';
      case MeasurementType.temperature:
        return 'temperature';
      case MeasurementType.bloodSugar:
        return 'bloodSugar';
      case MeasurementType.heartRate:
        return 'heartRate';
    }
  }

  String get displayName {
    switch (this) {
      case MeasurementType.bloodPressure:
        return 'Давление';
      case MeasurementType.weight:
        return 'Вес';
      case MeasurementType.temperature:
        return 'Температура';
      case MeasurementType.bloodSugar:
        return 'Сахар крови';
      case MeasurementType.heartRate:
        return 'Пульс';
    }
  }

  String get unit {
    switch (this) {
      case MeasurementType.bloodPressure:
        return 'мм рт.ст.';
      case MeasurementType.weight:
        return 'кг';
      case MeasurementType.temperature:
        return '°C';
      case MeasurementType.bloodSugar:
        return 'ммоль/л';
      case MeasurementType.heartRate:
        return 'уд/мин';
    }
  }

  bool get hasTwoValues => this == MeasurementType.bloodPressure;

  String get valueName {
    if (this == MeasurementType.bloodPressure) return 'Систолическое';
    return displayName;
  }

  String get value2Name => 'Диастолическое';

  static MeasurementType fromName(String name) {
    return MeasurementType.values.firstWhere((e) => e.name == name);
  }
}

class Measurement {
  final int? id;
  final MeasurementType type;
  final double value;
  final double? value2;
  final DateTime dateTime;
  final String? notes;

  Measurement({
    this.id,
    required this.type,
    required this.value,
    this.value2,
    required this.dateTime,
    this.notes,
  });

  String get displayValue {
    if (type.hasTwoValues && value2 != null) {
      return '${value.toStringAsFixed(0)}/${value2!.toStringAsFixed(0)} ${type.unit}';
    }
    final formatted = value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$formatted ${type.unit}';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'value': value,
      'value2': value2,
      'date_time': dateTime.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      type: MeasurementTypeExtension.fromName(map['type'] as String),
      value: (map['value'] as num).toDouble(),
      value2: map['value2'] != null ? (map['value2'] as num).toDouble() : null,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      notes: map['notes'] as String?,
    );
  }

  Measurement copyWith({
    int? id,
    MeasurementType? type,
    double? value,
    double? value2,
    DateTime? dateTime,
    String? notes,
  }) {
    return Measurement(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      value2: value2 ?? this.value2,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
    );
  }
}
