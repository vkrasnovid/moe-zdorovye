import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/record.dart';
import '../../providers/records_provider.dart';
import '../../widgets/record_list_item.dart';
import '../add_record/add_record_screen.dart';
import '../record_detail/record_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  final RecordCategory? initialCategory;

  const RecordsScreen({super.key, this.initialCategory});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecordsProvider>();
      provider.setFilterCategory(widget.initialCategory);
      if (provider.records.isEmpty) provider.loadRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsProvider>(
      builder: (context, provider, _) {
        final title = provider.filterCategory?.displayNameFull ?? 'Все записи';
        return Scaffold(
          appBar: AppBar(
            title: _searchVisible
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      hintText: 'Поиск...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: provider.setSearchQuery,
                  )
                : Text(title),
            actions: [
              IconButton(
                icon: Icon(_searchVisible ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() => _searchVisible = !_searchVisible);
                  if (!_searchVisible) {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCategoryFilter(provider),
              Expanded(child: _buildList(context, provider)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecordScreen(initialCategory: provider.filterCategory),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(RecordsProvider provider) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _FilterChip(
              label: 'Все',
              selected: provider.filterCategory == null,
              onSelected: (_) => provider.setFilterCategory(null),
            ),
            const SizedBox(width: 6),
            ...RecordCategory.values.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterChip(
                    label: cat.displayName,
                    selected: provider.filterCategory == cat,
                    color: cat.color,
                    onSelected: (_) => provider.setFilterCategory(
                      provider.filterCategory == cat ? null : cat,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, RecordsProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)));
    }
    final records = provider.records;
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Нет записей', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return RecordListItem(
          record: record,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecordDetailScreen(record: record)),
            );
          },
          onDelete: () => _confirmDelete(context, record),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, MedicalRecord record) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('«${record.title}» будет удалена безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RecordsProvider>().deleteRecord(record);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF00897B);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : c,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: c.withAlpha(15),
      selectedColor: c,
      checkmarkColor: Colors.white,
      side: BorderSide(color: c.withAlpha(80)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
