/// Parses raw text extracted from a lab result PDF and returns a list of
/// [LabTestResult] objects. Handles common Russian lab formats
/// (Invitro, KDL, Helix, CMD, etc.).
class LabTextParser {
  // Pattern 1: name (2+ spaces or tab) value (spaces) unit (spaces) refMin - refMax
  // Covers: "Гемоглобин        140,0     г/л     115,0 - 160,0"
  static final RegExp _pattern1 = RegExp(
    r'([A-ZА-ЯЁa-zа-яё][A-ZА-ЯЁa-zа-яё0-9 ,.()/\-+]{1,60}?)'
    r'(?:\t|\s{2,})'
    r'([<>≤≥]?\s*\d+[,.]?\d*)'
    r'[ \t]+'
    r'([^\s\d][^\s\t]{0,25})'
    r'[ \t]+'
    r'(\d+[,.]?\d*)[ \t]*[-–—][ \t]*(\d+[,.]?\d*)',
    multiLine: true,
    caseSensitive: false,
  );

  // Pattern 2: name (spaces) value (spaces) refMin-refMax (spaces) unit
  // Covers Invitro: "Глюкоза         4,5      3,3 - 6,1      ммоль/л"
  static final RegExp _pattern2 = RegExp(
    r'([A-ZА-ЯЁa-zа-яё][A-ZА-ЯЁa-zа-яё0-9 ,.()/\-+]{1,60}?)'
    r'(?:\t|\s{2,})'
    r'([<>≤≥]?\s*\d+[,.]?\d*)'
    r'[ \t]+'
    r'(\d+[,.]?\d*)[ \t]*[-–—][ \t]*(\d+[,.]?\d*)'
    r'[ \t]+'
    r'([^\s\d][^\s\t]{0,25})',
    multiLine: true,
    caseSensitive: false,
  );

  // Pattern 3: name (spaces) value (spaces) unit — no reference range
  // Covers simpler formats; used as fallback only if above yield no results
  static final RegExp _pattern3 = RegExp(
    r'([A-ZА-ЯЁa-zа-яё][A-ZА-ЯЁa-zа-яё0-9 ,.()/\-+]{1,60}?)'
    r'(?:\t|\s{2,})'
    r'([<>≤≥]?\s*\d+[,.]?\d*)'
    r'[ \t]+'
    r'([^\s\d\r\n][^\s\t\r\n]{0,25})',
    multiLine: true,
    caseSensitive: false,
  );

  // Words that indicate a non-result line (header/footer/clinic info)
  static const List<String> _skipKeywords = [
    'дата',
    'пациент',
    'врач',
    'лаборатория',
    'клиника',
    'адрес',
    'телефон',
    'результат',
    'референс',
    'единицы',
    'норма',
    'показатель',
    'заключение',
    'подпись',
    'печать',
    'стр.',
    'итого',
    'направление',
    'doctor',
    'patient',
    'date',
    'laboratory',
  ];

  /// Parses [text] and returns extracted lab test results.
  static List<LabTestResult> parseText(String text) {
    // Normalize line endings and tabs
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final results = <LabTestResult>[];
    final seen = <String>{};

    // Try pattern 1 (name … value … unit … min-max)
    for (final match in _pattern1.allMatches(normalized)) {
      final r = _extract1(match);
      if (r != null && seen.add(r.testName.toLowerCase().trim())) {
        results.add(r);
      }
    }

    // Try pattern 2 (name … value … min-max … unit)
    for (final match in _pattern2.allMatches(normalized)) {
      final r = _extract2(match);
      if (r != null && seen.add(r.testName.toLowerCase().trim())) {
        results.add(r);
      }
    }

    // Fallback: pattern 3 (no ref range) — only if we have very few results
    if (results.length < 3) {
      for (final match in _pattern3.allMatches(normalized)) {
        final r = _extract3(match);
        if (r != null && seen.add(r.testName.toLowerCase().trim())) {
          results.add(r);
        }
      }
    }

    return results;
  }

  static LabTestResult? _extract1(RegExpMatch m) {
    final name = m.group(1)!.trim();
    if (!_isValidName(name)) return null;

    final value = _parseValue(m.group(2));
    if (value == null) return null;

    final unit = m.group(3)!.trim();
    if (!_isValidUnit(unit)) return null;

    final refMin = _parseDouble(m.group(4));
    final refMax = _parseDouble(m.group(5));

    return LabTestResult(
      testName: name,
      value: value,
      unit: unit,
      refMin: refMin,
      refMax: refMax,
      flag: _flag(value, refMin, refMax),
    );
  }

  static LabTestResult? _extract2(RegExpMatch m) {
    final name = m.group(1)!.trim();
    if (!_isValidName(name)) return null;

    final value = _parseValue(m.group(2));
    if (value == null) return null;

    final refMin = _parseDouble(m.group(3));
    final refMax = _parseDouble(m.group(4));

    final unit = m.group(5)!.trim();
    if (!_isValidUnit(unit)) return null;

    return LabTestResult(
      testName: name,
      value: value,
      unit: unit,
      refMin: refMin,
      refMax: refMax,
      flag: _flag(value, refMin, refMax),
    );
  }

  static LabTestResult? _extract3(RegExpMatch m) {
    final name = m.group(1)!.trim();
    if (!_isValidName(name)) return null;

    final value = _parseValue(m.group(2));
    if (value == null) return null;

    final unit = m.group(3)!.trim();
    if (!_isValidUnit(unit)) return null;

    return LabTestResult(
      testName: name,
      value: value,
      unit: unit,
      refMin: null,
      refMax: null,
      flag: 'normal',
    );
  }

  static bool _isValidName(String name) {
    if (name.length < 2 || name.length > 70) return false;
    // Must contain at least one Cyrillic or Latin letter
    if (!RegExp(r'[a-zA-ZА-ЯЁа-яё]').hasMatch(name)) return false;
    final lower = name.toLowerCase();
    for (final word in _skipKeywords) {
      if (lower.contains(word)) return false;
    }
    return true;
  }

  static bool _isValidUnit(String unit) {
    if (unit.isEmpty || unit.length > 30) return false;
    // Must start with a letter or %
    if (!RegExp(r'^[a-zA-ZА-ЯЁа-яё%µ]').hasMatch(unit)) return false;
    // Must not look like a date (DD.MM.YYYY)
    if (RegExp(r'^\d{2}\.\d{2}').hasMatch(unit)) return false;
    return true;
  }

  static double? _parseValue(String? raw) {
    if (raw == null) return null;
    // Strip comparison signs, spaces; replace comma decimal
    final clean = raw
        .replaceAll(RegExp(r'[<>≤≥\s]'), '')
        .replaceAll(',', '.');
    final v = double.tryParse(clean);
    if (v == null || v < 0 || v > 999999) return null;
    return v;
  }

  static double? _parseDouble(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', '.').trim());
  }

  static String _flag(double value, double? refMin, double? refMax) {
    if (refMin != null && refMax != null) {
      if (value > refMax) return 'high';
      if (value < refMin) return 'low';
    }
    return 'normal';
  }
}

class LabTestResult {
  final String testName;
  final double value;
  final String unit;
  final double? refMin;
  final double? refMax;
  final String flag; // normal / high / low

  const LabTestResult({
    required this.testName,
    required this.value,
    required this.unit,
    this.refMin,
    this.refMax,
    required this.flag,
  });
}
