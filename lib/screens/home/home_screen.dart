import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/records_provider.dart';
import '../../widgets/category_card.dart';
import '../../widgets/record_list_item.dart';
import '../records/records_screen.dart';
import '../add_record/add_record_screen.dart';
import '../record_detail/record_detail_screen.dart';
import '../measurements/measurements_screen.dart';
import '../sharing/sharing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F9),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildBody(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddRecord(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF00897B),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'МоёЗдоровье',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00897B), Color(0xFF00695C)],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          tooltip: 'Поделиться с врачом',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SharingScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.monitor_heart_outlined, color: Colors.white),
          tooltip: 'Показатели здоровья',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<RecordsProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryGrid(context, provider),
            _buildRecentSection(context, provider),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildCategoryGrid(BuildContext context, RecordsProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категории',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: RecordCategory.values.map((cat) {
              return CategoryCard(
                category: cat,
                count: provider.countForCategory(cat),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordsScreen(initialCategory: cat),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Measurements tile
          _buildMeasurementsTile(context),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTile(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_outlined, color: Color(0xFF1565C0), size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Показатели здоровья', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Давление, вес, температура...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context, RecordsProvider provider) {
    final recent = provider.recentRecords;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Последние записи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecordsScreen()),
                ),
                child: const Text('Все', style: TextStyle(color: Color(0xFF00897B))),
              ),
            ],
          ),
          if (provider.loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)))
          else if (recent.isEmpty)
            _buildEmptyState()
          else
            ...recent.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: RecordListItem(
                    record: r,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordDetailScreen(record: r),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Нет записей',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Нажмите + чтобы добавить первую запись',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openAddRecord(BuildContext context, RecordCategory? category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(initialCategory: category),
      ),
    );
  }
}
