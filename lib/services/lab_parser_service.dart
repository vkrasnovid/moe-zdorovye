import '../models/parsed_result.dart';

class LabParserService {
  // Normalization map: lowercase key → canonical display name
  static const Map<String, String> _normMap = {
    // Общий анализ крови
    'гемоглобин': 'Гемоглобин',
    'hgb': 'Гемоглобин',
    'hb': 'Гемоглобин',
    'hemoglobin': 'Гемоглобин',
    'лейкоциты': 'Лейкоциты',
    'wbc': 'Лейкоциты',
    'leukocytes': 'Лейкоциты',
    'эритроциты': 'Эритроциты',
    'rbc': 'Эритроциты',
    'erythrocytes': 'Эритроциты',
    'тромбоциты': 'Тромбоциты',
    'plt': 'Тромбоциты',
    'platelets': 'Тромбоциты',
    'соэ': 'СОЭ',
    'esr': 'СОЭ',
    'soe': 'СОЭ',
    'гематокрит': 'Гематокрит',
    'hct': 'Гематокрит',
    'ht': 'Гематокрит',
    'нейтрофилы': 'Нейтрофилы',
    'neutrophils': 'Нейтрофилы',
    'neu': 'Нейтрофилы',
    'лимфоциты': 'Лимфоциты',
    'lymphocytes': 'Лимфоциты',
    'lym': 'Лимфоциты',
    'моноциты': 'Моноциты',
    'monocytes': 'Моноциты',
    'mon': 'Моноциты',
    'эозинофилы': 'Эозинофилы',
    'eosinophils': 'Эозинофилы',
    'eos': 'Эозинофилы',
    'базофилы': 'Базофилы',
    'basophils': 'Базофилы',
    'bas': 'Базофилы',
    // Биохимия
    'глюкоза': 'Глюкоза',
    'glucose': 'Глюкоза',
    'холестерин': 'Холестерин',
    'cholesterol': 'Холестерин',
    'хс': 'Холестерин',
    'лпнп': 'ЛПНП',
    'ldl': 'ЛПНП',
    'лпвп': 'ЛПВП',
    'hdl': 'ЛПВП',
    'триглицериды': 'Триглицериды',
    'triglycerides': 'Триглицериды',
    'tg': 'Триглицериды',
    'билирубин': 'Билирубин общий',
    'bilirubin': 'Билирубин общий',
    'билирубин общий': 'Билирубин общий',
    'билирубин прямой': 'Билирубин прямой',
    'алт': 'АЛТ',
    'alt': 'АЛТ',
    'аланинаминотрансфераза': 'АЛТ',
    'аст': 'АСТ',
    'ast': 'АСТ',
    'аспартатаминотрансфераза': 'АСТ',
    'мочевина': 'Мочевина',
    'urea': 'Мочевина',
    'bun': 'Мочевина',
    'креатинин': 'Креатинин',
    'creatinine': 'Креатинин',
    'crea': 'Креатинин',
    'cre': 'Креатинин',
    'мочевая кислота': 'Мочевая кислота',
    'uric acid': 'Мочевая кислота',
    'общий белок': 'Общий белок',
    'total protein': 'Общий белок',
    'белок': 'Общий белок',
    'protein': 'Общий белок',
    'альбумин': 'Альбумин',
    'albumin': 'Альбумин',
    'alb': 'Альбумин',
    'щелочная фосфатаза': 'Щелочная фосфатаза',
    'alkaline phosphatase': 'Щелочная фосфатаза',
    'alp': 'Щелочная фосфатаза',
    'ггт': 'ГГТ',
    'ggt': 'ГГТ',
    'гамма-гт': 'ГГТ',
    'фибриноген': 'Фибриноген',
    'fibrinogen': 'Фибриноген',
    'crp': 'СРБ',
    'срб': 'СРБ',
    'с-реактивный белок': 'СРБ',
    'c-reactive protein': 'СРБ',
    'инсулин': 'Инсулин',
    'insulin': 'Инсулин',
    'тиреотропный гормон': 'ТТГ',
    'ттг': 'ТТГ',
    'tsh': 'ТТГ',
    'т4 свободный': 'Т4 свободный',
    'ft4': 'Т4 свободный',
    'т3 свободный': 'Т3 свободный',
    'ft3': 'Т3 свободный',
    'ферритин': 'Ферритин',
    'ferritin': 'Ферритин',
    'железо': 'Железо',
    'iron': 'Железо',
    'fe': 'Железо',
    'витамин d': 'Витамин D',
    'vitamin d': 'Витамин D',
    '25-oh-d': 'Витамин D',
    'витамин b12': 'Витамин B12',
    'b12': 'Витамин B12',
    'фолиевая кислота': 'Фолиевая кислота',
    'folate': 'Фолиевая кислота',
    // Анализ мочи
    'ph мочи': 'pH мочи',
    'удельный вес': 'Удельный вес',
    'specific gravity': 'Удельный вес',
  };

  // Pattern 1: "Name  Value  Unit  RefMin - RefMax" (tabular format with 2+ spaces)
  static final _patternTabular = RegExp(
    r'^([А-Яа-яёЁA-Za-z][А-Яа-яёЁA-Za-z\s\-/,().]+?)\s{2,}([\d]+[.,]?\d*)\s+([а-яА-ЯёЁa-zA-Z%/µ*×·^]+(?:[/·][а-яА-ЯёЁa-zA-Z]+)?(?:\d+)?)\s+([\d]+[.,]?\d*)\s*[-–—]\s*([\d]+[.,]?\d*)',
    multiLine: true,
    caseSensitive: false,
  );

  // Pattern 2: "Name: Value Unit (RefMin-RefMax)"
  static final _patternColon = RegExp(
    r'([А-Яа-яёЁA-Za-z][А-Яа-яёЁA-Za-z\s\-/,().]+?):\s*([\d]+[.,]?\d*)\s+([а-яА-ЯёЁa-zA-Z%/µ*×·^]+(?:[/·][а-яА-ЯёЁa-zA-Z]+)?(?:\d+)?)\s*\(\s*([\d]+[.,]?\d*)\s*[-–—]\s*([\d]+[.,]?\d*)\s*\)',
    multiLine: true,
    caseSensitive: false,
  );

  // Pattern 3: "Name: Value Unit RefMin-RefMax" (no parentheses)
  static final _patternColonNoParens = RegExp(
    r'([А-Яа-яёЁA-Za-z][А-Яа-яёЁA-Za-z\s\-/,().]+?):\s*([\d]+[.,]?\d*)\s+([а-яА-ЯёЁa-zA-Z%/µ*×·^]+(?:[/·][а-яА-ЯёЁa-zA-Z]+)?(?:\d+)?)\s+([\d]+[.,]?\d*)\s*[-–—]\s*([\d]+[.,]?\d*)',
    multiLine: true,
    caseSensitive: false,
  );

  static double _parseDouble(String s) {
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }

  static String _normalize(String raw) {
    final key = raw.trim().toLowerCase();
    // Exact match
    if (_normMap.containsKey(key)) return _normMap[key]!;
    // Partial match: check if any key is contained in the raw name
    for (final entry in _normMap.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    // Fallback: capitalize first letter
    return raw.trim().isEmpty ? raw : raw.trim()[0].toUpperCase() + raw.trim().substring(1);
  }

  static String _computeFlag(double value, double? refMin, double? refMax) {
    if (refMin == null || refMax == null) return 'normal';
    if (value < refMin) return 'low';
    if (value > refMax) return 'high';
    return 'normal';
  }

  static List<ParsedResult> parse(String text, int recordId, String testDate) {
    final results = <ParsedResult>[];
    final seen = <String>{};

    void addMatches(RegExp pattern) {
      for (final match in pattern.allMatches(text)) {
        final name = match.group(1)?.trim() ?? '';
        final valueStr = match.group(2) ?? '0';
        final unit = match.group(3)?.trim() ?? '';
        final refMinStr = match.group(4) ?? '';
        final refMaxStr = match.group(5) ?? '';

        if (name.isEmpty || name.length < 2) continue;

        final value = _parseDouble(valueStr);
        final refMin = refMinStr.isNotEmpty ? _parseDouble(refMinStr) : null;
        final refMax = refMaxStr.isNotEmpty ? _parseDouble(refMaxStr) : null;
        final normalized = _normalize(name);
        final key = '$normalized-$testDate';

        if (seen.contains(key)) continue;
        seen.add(key);

        // Skip if value is zero and looks like a header row
        if (value == 0.0 && refMin == null) continue;

        results.add(ParsedResult(
          recordId: recordId,
          testName: name,
          testNameNormalized: normalized,
          value: value,
          unit: unit,
          refMin: refMin,
          refMax: refMax,
          flag: _computeFlag(value, refMin, refMax),
          testDate: testDate,
          parsedAt: DateTime.now(),
        ));
      }
    }

    addMatches(_patternTabular);
    addMatches(_patternColon);
    addMatches(_patternColonNoParens);

    return results;
  }
}
