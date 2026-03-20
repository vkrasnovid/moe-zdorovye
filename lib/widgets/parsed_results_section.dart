import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parsed_result.dart';
import '../models/record.dart';
import '../providers/parsed_results_provider.dart';
import '../screens/dynamics/dynamics_screen.dart';

/// Displays parsed lab results for a [MedicalRecord] that has PDF attachments.
///
/// Shows a "Распознать анализы" button, a loading state, the results table,
/// and allows editing individual values or re-parsing.
class ParsedResultsSection extends StatefulWidget {
  final MedicalRecord record;

  const ParsedResultsSection({super.key, required this.record});

  @override
  State<ParsedResultsSection> createState() => _ParsedResultsSectionState();
}

class _ParsedResultsSectionState extends State<ParsedResultsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ParsedResultsProvider>().loadForRecord(widget.record.id!);
    });
  }

  bool get _hasPdf => widget.record.attachments
      .any((p) => p.toLowerCase().endsWith('.pdf'));

  Future<void> _parse() async {
    final provider = context.read<ParsedResultsProvider>();
    final found = await provider.parseRecord(widget.record);
    if (!mounted) return;
    if (!found && provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Анализы не найдены. Проверьте файл или добавьте другой PDF.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPdf) return const SizedBox.shrink();

    return Consumer<ParsedResultsProvider>(
      builder: (context, provider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, provider),
                const SizedBox(height: 12),
                if (provider.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1565C0)),
                          SizedBox(height: 12),
                          Text(
                            'Распознаём анализы…',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (provider.error != null)
                  _buildError(provider.error!)
                else if (provider.recordResults.isEmpty)
                  _buildEmpty(provider)
                else
                  _buildResults(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
      BuildContext context, ParsedResultsProvider provider) {
    return Row(
      children: [
        const Icon(Icons.biotech_outlined, size: 16, color: Color(0xFF1565C0)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Результаты анализов',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1565C0),
            ),
          ),
        ),
        if (!provider.loading) ...[
          if (provider.recordResults.isNotEmpty)
            TextButton(
              onPressed: _parse,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Повторить'),
            ),
          if (provider.recordResults.isEmpty)
            FilledButton.icon(
              onPressed: _parse,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Распознать анализы'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                textStyle: const TextStyle(fontSize: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
        ],
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty(ParsedResultsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(Icons.table_chart_outlined, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'Нажмите «Распознать анализы» чтобы\nавтоматически извлечь результаты из PDF',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ошибка: $error',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _parse,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Повторить'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              side: const BorderSide(color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results table ─────────────────────────────────────────────────────────

  Widget _buildResults(
      BuildContext context, ParsedResultsProvider provider) {
    final results = provider.recordResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table header
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Expanded(
                flex: 5,
                child: Text(
                  'Показатель',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Expanded(
                flex: 3,
                child: Text(
                  'Результат',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 20,
                child: Text(
                  '',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...results.map((r) => _ResultRow(
              result: r,
              onEdit: (updated) =>
                  provider.updateResult(updated),
            )),
        const SizedBox(height: 8),
        // Navigate to dynamics
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DynamicsScreen(),
              ),
            ),
            icon: const Icon(Icons.show_chart, size: 16),
            label: const Text('Смотреть динамику'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Single result row ─────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final ParsedResult result;
  final ValueChanged<ParsedResult> onEdit;

  const _ResultRow({required this.result, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showEditDialog(context),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            // Test name
            Expanded(
              flex: 5,
              child: Text(
                result.testName,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Value + unit
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.value} ${result.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: result.flagColor,
                    ),
                  ),
                  if (result.refMin != null && result.refMax != null)
                    Text(
                      '${result.refMin}–${result.refMax}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Flag icon
            SizedBox(
              width: 20,
              child: Icon(
                result.flagIcon,
                size: 16,
                color: result.flagColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditResultDialog(result: result, onSave: onEdit),
    );
  }
}

// ─── Edit dialog ──────────────────────────────────────────────────────────

class _EditResultDialog extends StatefulWidget {
  final ParsedResult result;
  final ValueChanged<ParsedResult> onSave;

  const _EditResultDialog({required this.result, required this.onSave});

  @override
  State<_EditResultDialog> createState() => _EditResultDialogState();
}

class _EditResultDialogState extends State<_EditResultDialog> {
  late final TextEditingController _valueCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _refMinCtrl;
  late final TextEditingController _refMaxCtrl;

  @override
  void initState() {
    super.initState();
    _valueCtrl =
        TextEditingController(text: widget.result.value.toString());
    _unitCtrl =
        TextEditingController(text: widget.result.unit);
    _refMinCtrl =
        TextEditingController(text: widget.result.refMin?.toString() ?? '');
    _refMaxCtrl =
        TextEditingController(text: widget.result.refMax?.toString() ?? '');
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _unitCtrl.dispose();
    _refMinCtrl.dispose();
    _refMaxCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final value =
        double.tryParse(_valueCtrl.text.replaceAll(',', '.'));
    if (value == null) return;

    final refMin =
        double.tryParse(_refMinCtrl.text.replaceAll(',', '.'));
    final refMax =
        double.tryParse(_refMaxCtrl.text.replaceAll(',', '.'));

    String flag = 'normal';
    if (refMin != null && refMax != null) {
      if (value > refMax) flag = 'high';
      if (value < refMin) flag = 'low';
    }

    widget.onSave(
      widget.result.copyWith(
        value: value,
        unit: _unitCtrl.text.trim(),
        refMin: refMin,
        refMax: refMax,
        flag: flag,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.result.testName,
        style: const TextStyle(fontSize: 15),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Значение', _valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true)),
            const SizedBox(height: 12),
            _field('Единица измерения', _unitCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _field('Норма от', _refMinCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true))),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Норма до', _refMaxCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
