import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/parsed_result.dart';
import '../../providers/parsed_results_provider.dart';

class DynamicsScreen extends StatefulWidget {
  const DynamicsScreen({super.key});

  @override
  State<DynamicsScreen> createState() => _DynamicsScreenState();
}

class _DynamicsScreenState extends State<DynamicsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ParsedResultsProvider>();
      if (!provider.allLoaded) provider.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Динамика анализов')),
      body: Consumer<ParsedResultsProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final grouped = provider.resultsByTestName;

          if (grouped.isEmpty) {
            return _buildEmpty();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final name = grouped.keys.elementAt(index);
              final results = grouped[name]!;
              return _TestCard(testName: name, results: results);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Нет данных',
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Откройте запись с анализами\nи нажмите «Разобрать»',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final String testName;
  final List<ParsedResult> results;

  const _TestCard({required this.testName, required this.results});

  @override
  Widget build(BuildContext context) {
    final latestFlag = results.last.flag;
    final latestValue = results.last.value;
    final unit = results.last.unit;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _TestDetailScreen(testName: testName, results: results),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      testName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: results.last.flagColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(results.last.flagIcon, size: 14, color: results.last.flagColor),
                        const SizedBox(width: 4),
                        Text(
                          '$latestValue $unit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: results.last.flagColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (latestFlag != 'normal')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    results.last.flagLabel,
                    style: TextStyle(fontSize: 12, color: results.last.flagColor),
                  ),
                ),
              if (results.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: _MiniChart(results: results),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${results.length} ${_measurementWord(results.length)} · последнее: ${results.last.testDate}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _measurementWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'измерение';
    if (n % 10 >= 2 && n % 10 <= 4 && !(n % 100 >= 12 && n % 100 <= 14)) return 'измерения';
    return 'измерений';
  }
}

class _MiniChart extends StatelessWidget {
  final List<ParsedResult> results;

  const _MiniChart({required this.results});

  @override
  Widget build(BuildContext context) {
    final spots = results.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final refMin = results.last.refMin;
    final refMax = results.last.refMax;
    final allValues = results.map((r) => r.value).toList();
    double minY = allValues.reduce((a, b) => a < b ? a : b);
    double maxY = allValues.reduce((a, b) => a > b ? a : b);
    if (refMin != null) minY = minY < refMin ? minY : refMin;
    if (refMax != null) maxY = maxY > refMax ? maxY : refMax;
    final padding = (maxY - minY) * 0.15;
    minY = minY - padding;
    maxY = maxY + padding;
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (refMin != null)
              HorizontalLine(
                y: refMin,
                color: Colors.green.withAlpha(100),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            if (refMax != null)
              HorizontalLine(
                y: refMax,
                color: Colors.green.withAlpha(100),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF1565C0),
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: results[index].flagColor,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

// ─── Detail screen with full chart ───────────────────────────────────────────

class _TestDetailScreen extends StatelessWidget {
  final String testName;
  final List<ParsedResult> results;

  const _TestDetailScreen({required this.testName, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(testName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChart(),
            const SizedBox(height: 24),
            const Text(
              'История',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...results.reversed.map((r) => _buildResultRow(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final spots = results.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final refMin = results.last.refMin;
    final refMax = results.last.refMax;

    double minY = results.map((r) => r.value).reduce((a, b) => a < b ? a : b);
    double maxY = results.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    if (refMin != null) minY = minY < refMin ? minY : refMin;
    if (refMax != null) maxY = maxY > refMax ? maxY : refMax;
    final padding = (maxY - minY) * 0.2;
    minY = minY - padding;
    maxY = maxY + padding;
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              results.last.unit,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withAlpha(40),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withAlpha(60)),
                      left: BorderSide(color: Colors.grey.withAlpha(60)),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= results.length) return const SizedBox.shrink();
                          final date = results[idx].testDate;
                          final parts = date.split('-');
                          final label = parts.length >= 2 ? '${parts[2]}.${parts[1]}' : date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label, style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (refMin != null)
                        HorizontalLine(
                          y: refMin,
                          color: Colors.green.withAlpha(160),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: const TextStyle(fontSize: 9, color: Colors.green),
                            labelResolver: (_) => 'min',
                          ),
                        ),
                      if (refMax != null)
                        HorizontalLine(
                          y: refMax,
                          color: Colors.green.withAlpha(160),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.bottomRight,
                            style: const TextStyle(fontSize: 9, color: Colors.green),
                            labelResolver: (_) => 'max',
                          ),
                        ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF1565C0),
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 5,
                          color: results[index].flagColor,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: refMin != null && refMax != null,
                        color: const Color(0xFF1565C0).withAlpha(15),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final r = results[spot.spotIndex];
                          return LineTooltipItem(
                            '${r.value} ${r.unit}\n${r.testDate}',
                            TextStyle(fontSize: 12, color: r.flagColor, fontWeight: FontWeight.w600),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (refMin != null && refMax != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 16, height: 2, color: Colors.green.withAlpha(160)),
                  const SizedBox(width: 6),
                  Text(
                    'Норма: $refMin – $refMax ${results.last.unit}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(ParsedResult r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: r.flagColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.testDate, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
          Text(
            '${r.value} ${r.unit}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: r.flagColor),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              r.flagLabel,
              style: TextStyle(fontSize: 11, color: r.flagColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
