/// Maps common lab test name variants (Russian + English + abbreviations)
/// to a canonical normalized key. Used for aggregating the same test
/// across different labs and dates in the dynamics chart.
class LabNormalizer {
  static const Map<String, String> _normalMap = {
    // Hemoglobin
    'гемоглобин': 'hemoglobin',
    'гемоглобин (hgb)': 'hemoglobin',
    'hgb': 'hemoglobin',
    'hb': 'hemoglobin',
    'hemoglobin': 'hemoglobin',
    // WBC (Leukocytes)
    'лейкоциты': 'wbc',
    'лейк': 'wbc',
    'wbc': 'wbc',
    'white blood cells': 'wbc',
    'лейкоциты (wbc)': 'wbc',
    // RBC (Erythrocytes)
    'эритроциты': 'rbc',
    'эр': 'rbc',
    'rbc': 'rbc',
    'red blood cells': 'rbc',
    'эритроциты (rbc)': 'rbc',
    // Platelets
    'тромбоциты': 'plt',
    'тромб': 'plt',
    'plt': 'plt',
    'platelets': 'plt',
    'тромбоциты (plt)': 'plt',
    // Neutrophils
    'нейтрофилы': 'neutrophils',
    'нейтрофилы (общ.)': 'neutrophils',
    'нейтр': 'neutrophils',
    'neu': 'neutrophils',
    'neut': 'neutrophils',
    'neutrophils': 'neutrophils',
    // Lymphocytes
    'лимфоциты': 'lymphocytes',
    'лимф': 'lymphocytes',
    'lym': 'lymphocytes',
    'lymphocytes': 'lymphocytes',
    'лимфоциты (lym)': 'lymphocytes',
    // Monocytes
    'моноциты': 'monocytes',
    'mono': 'monocytes',
    'monocytes': 'monocytes',
    // Eosinophils
    'эозинофилы': 'eosinophils',
    'эоз': 'eosinophils',
    'eos': 'eosinophils',
    'eosinophils': 'eosinophils',
    // Basophils
    'базофилы': 'basophils',
    'баз': 'basophils',
    'baso': 'basophils',
    'basophils': 'basophils',
    // Hematocrit
    'гематокрит': 'hematocrit',
    'hct': 'hematocrit',
    'ht': 'hematocrit',
    'hematocrit': 'hematocrit',
    // MCV
    'mcv': 'mcv',
    'средний объем эритроцитов': 'mcv',
    'средний объём эритроцитов': 'mcv',
    // MCH
    'mch': 'mch',
    'среднее содержание гемоглобина': 'mch',
    // MCHC
    'mchc': 'mchc',
    // ESR
    'соэ': 'esr',
    'сое': 'esr',
    'esr': 'esr',
    'скорость оседания эритроцитов': 'esr',
    'скорость оседания': 'esr',
    // Glucose
    'глюкоза': 'glucose',
    'glucose': 'glucose',
    'глюкоза (glucose)': 'glucose',
    // Total Cholesterol
    'холестерин': 'cholesterol_total',
    'холестерин общий': 'cholesterol_total',
    'общий холестерин': 'cholesterol_total',
    'chol': 'cholesterol_total',
    'total cholesterol': 'cholesterol_total',
    // LDL
    'лпнп': 'ldl',
    'лпнп-холестерин': 'ldl',
    'холестерин лпнп': 'ldl',
    'ldl': 'ldl',
    'ldl-холестерин': 'ldl',
    // HDL
    'лпвп': 'hdl',
    'лпвп-холестерин': 'hdl',
    'холестерин лпвп': 'hdl',
    'hdl': 'hdl',
    'hdl-холестерин': 'hdl',
    // Triglycerides
    'триглицериды': 'triglycerides',
    'tg': 'triglycerides',
    'triglycerides': 'triglycerides',
    // ALT
    'алт': 'alt',
    'алт (аланинаминотрансфераза)': 'alt',
    'alt': 'alt',
    'alat': 'alt',
    'аланинаминотрансфераза': 'alt',
    'аланинаминотрансфераза (алт)': 'alt',
    // AST
    'аст': 'ast',
    'аст (аспартатаминотрансфераза)': 'ast',
    'ast': 'ast',
    'asat': 'ast',
    'аспартатаминотрансфераза': 'ast',
    'аспартатаминотрансфераза (аст)': 'ast',
    // Total Bilirubin
    'билирубин общий': 'bilirubin_total',
    'билирубин (общий)': 'bilirubin_total',
    'общий билирубин': 'bilirubin_total',
    'total bilirubin': 'bilirubin_total',
    // Direct Bilirubin
    'билирубин прямой': 'bilirubin_direct',
    'билирубин (прямой)': 'bilirubin_direct',
    'прямой билирубин': 'bilirubin_direct',
    'direct bilirubin': 'bilirubin_direct',
    // Indirect Bilirubin
    'билирубин непрямой': 'bilirubin_indirect',
    'непрямой билирубин': 'bilirubin_indirect',
    // Total Protein
    'белок общий': 'protein_total',
    'общий белок': 'protein_total',
    'total protein': 'protein_total',
    'protein': 'protein_total',
    // Albumin
    'альбумин': 'albumin',
    'albumin': 'albumin',
    // Urea
    'мочевина': 'urea',
    'urea': 'urea',
    'bun': 'urea',
    'мочевина (urea)': 'urea',
    // Creatinine
    'креатинин': 'creatinine',
    'creatinine': 'creatinine',
    'креатинин (creatinine)': 'creatinine',
    // GFR
    'скф': 'gfr',
    'скф (ckd-epi)': 'gfr',
    'gfr': 'gfr',
    'egfr': 'gfr',
    'клубочковая фильтрация': 'gfr',
    'скорость клубочковой фильтрации': 'gfr',
    // Uric Acid
    'мочевая кислота': 'uric_acid',
    'uric acid': 'uric_acid',
    // ALP
    'щелочная фосфатаза': 'alp',
    'щф': 'alp',
    'alp': 'alp',
    // GGT
    'ггтп': 'ggt',
    'гамма-гт': 'ggt',
    'гамма-глутамилтрансфераза': 'ggt',
    'ggt': 'ggt',
    // TSH
    'ттг': 'tsh',
    'тиреотропный гормон': 'tsh',
    'tsh': 'tsh',
    // Free T3
    'т3 свободный': 'ft3',
    'свободный т3': 'ft3',
    'ft3': 'ft3',
    'трийодтиронин свободный': 'ft3',
    // Free T4
    'т4 свободный': 'ft4',
    'свободный т4': 'ft4',
    'ft4': 'ft4',
    'тироксин свободный': 'ft4',
    // Ferritin
    'ферритин': 'ferritin',
    'ferritin': 'ferritin',
    // Iron
    'железо': 'iron',
    'железо (fe)': 'iron',
    'iron': 'iron',
    'fe': 'iron',
    // Vitamin D
    'витамин d': 'vitamin_d',
    '25-он витамин d': 'vitamin_d',
    '25(oh)d': 'vitamin_d',
    '25-гидроксивитамин d': 'vitamin_d',
    // B12
    'витамин b12': 'vitamin_b12',
    'b12': 'vitamin_b12',
    'цианокобаламин': 'vitamin_b12',
    'кобаламин': 'vitamin_b12',
    // Folic Acid
    'фолиевая кислота': 'folic_acid',
    'folate': 'folic_acid',
    'folic acid': 'folic_acid',
    // C-Reactive Protein
    'с-реактивный белок': 'crp',
    'срб': 'crp',
    'crp': 'crp',
    'c-reactive protein': 'crp',
    // Insulin
    'инсулин': 'insulin',
    'insulin': 'insulin',
    // Hemoglobin A1c
    'гликированный гемоглобин': 'hba1c',
    'hba1c': 'hba1c',
    'гликозилированный гемоглобин': 'hba1c',
  };

  static const Map<String, String> _displayNames = {
    'hemoglobin': 'Гемоглобин',
    'wbc': 'Лейкоциты',
    'rbc': 'Эритроциты',
    'plt': 'Тромбоциты',
    'neutrophils': 'Нейтрофилы',
    'lymphocytes': 'Лимфоциты',
    'monocytes': 'Моноциты',
    'eosinophils': 'Эозинофилы',
    'basophils': 'Базофилы',
    'hematocrit': 'Гематокрит',
    'mcv': 'MCV',
    'mch': 'MCH',
    'mchc': 'MCHC',
    'esr': 'СОЭ',
    'glucose': 'Глюкоза',
    'cholesterol_total': 'Холестерин общий',
    'ldl': 'ЛПНП (LDL)',
    'hdl': 'ЛПВП (HDL)',
    'triglycerides': 'Триглицериды',
    'alt': 'АЛТ',
    'ast': 'АСТ',
    'bilirubin_total': 'Билирубин общий',
    'bilirubin_direct': 'Билирубин прямой',
    'bilirubin_indirect': 'Билирубин непрямой',
    'protein_total': 'Белок общий',
    'albumin': 'Альбумин',
    'urea': 'Мочевина',
    'creatinine': 'Креатинин',
    'gfr': 'СКФ (GFR)',
    'uric_acid': 'Мочевая кислота',
    'alp': 'Щелочная фосфатаза',
    'ggt': 'ГГТП',
    'tsh': 'ТТГ',
    'ft3': 'Т3 свободный',
    'ft4': 'Т4 свободный',
    'ferritin': 'Ферритин',
    'iron': 'Железо',
    'vitamin_d': 'Витамин D',
    'vitamin_b12': 'Витамин B12',
    'folic_acid': 'Фолиевая кислота',
    'crp': 'С-реактивный белок',
    'insulin': 'Инсулин',
    'hba1c': 'Гликированный гемоглобин',
  };

  /// Returns a canonical key for the given test name (case-insensitive).
  static String normalize(String testName) {
    final lower = testName.toLowerCase().trim();

    // Exact match
    if (_normalMap.containsKey(lower)) return _normalMap[lower]!;

    // Try starts-with / contains match (handles slightly longer names)
    for (final entry in _normalMap.entries) {
      if (lower.startsWith(entry.key)) return entry.value;
      if (entry.key.length > 3 && lower.contains(entry.key)) return entry.value;
    }

    // Fallback: sanitized original name
    return lower
        .replaceAll(RegExp(r'[^a-zA-Zа-яёА-ЯЁ0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Returns a human-readable Russian name for the normalized key.
  static String displayName(String normalized) {
    return _displayNames[normalized] ?? normalized;
  }
}
