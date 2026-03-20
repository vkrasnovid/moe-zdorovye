import 'package:flutter/material.dart';

enum RecordCategory {
  tests,
  imaging,
  prescriptions,
  vaccinations,
  conditions,
}

extension RecordCategoryExtension on RecordCategory {
  String get name {
    switch (this) {
      case RecordCategory.tests:
        return 'tests';
      case RecordCategory.imaging:
        return 'imaging';
      case RecordCategory.prescriptions:
        return 'prescriptions';
      case RecordCategory.vaccinations:
        return 'vaccinations';
      case RecordCategory.conditions:
        return 'conditions';
    }
  }

  String get displayName {
    switch (this) {
      case RecordCategory.tests:
        return 'Анализы';
      case RecordCategory.imaging:
        return 'Снимки';
      case RecordCategory.prescriptions:
        return 'Рецепты';
      case RecordCategory.vaccinations:
        return 'Вакцинации';
      case RecordCategory.conditions:
        return 'Хр. заболевания';
    }
  }

  String get displayNameFull {
    switch (this) {
      case RecordCategory.tests:
        return 'Анализы крови/мочи';
      case RecordCategory.imaging:
        return 'Медицинские снимки';
      case RecordCategory.prescriptions:
        return 'Рецепты и назначения';
      case RecordCategory.vaccinations:
        return 'Вакцинации';
      case RecordCategory.conditions:
        return 'Хронические заболевания и аллергии';
    }
  }

  IconData get icon {
    switch (this) {
      case RecordCategory.tests:
        return Icons.science_outlined;
      case RecordCategory.imaging:
        return Icons.image_search_outlined;
      case RecordCategory.prescriptions:
        return Icons.medication_outlined;
      case RecordCategory.vaccinations:
        return Icons.vaccines_outlined;
      case RecordCategory.conditions:
        return Icons.monitor_heart_outlined;
    }
  }

  Color get color {
    switch (this) {
      case RecordCategory.tests:
        return const Color(0xFF1565C0);
      case RecordCategory.imaging:
        return const Color(0xFF6A1B9A);
      case RecordCategory.prescriptions:
        return const Color(0xFF2E7D32);
      case RecordCategory.vaccinations:
        return const Color(0xFFE65100);
      case RecordCategory.conditions:
        return const Color(0xFFC62828);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case RecordCategory.tests:
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case RecordCategory.imaging:
        return [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)];
      case RecordCategory.prescriptions:
        return [const Color(0xFF2E7D32), const Color(0xFF66BB6A)];
      case RecordCategory.vaccinations:
        return [const Color(0xFFE65100), const Color(0xFFFF9800)];
      case RecordCategory.conditions:
        return [const Color(0xFFC62828), const Color(0xFFEF5350)];
    }
  }

  static RecordCategory fromName(String name) {
    return RecordCategory.values.firstWhere(
      (e) => e.name == name,
      orElse: () => RecordCategory.values.first,
    );
  }
}
