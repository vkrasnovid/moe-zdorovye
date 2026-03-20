import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement.dart';
import '../utils/formatters.dart';

class MeasurementChart extends StatelessWidget {
  final MeasurementType type;
  final List<Measurement> measurements;

  const MeasurementChart({
    super.key,
    required this.type,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Нет данных для отображения',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final sorted = [...measurements]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final last = sorted.length > 30 ? sorted.sublist(sorted.length - 30) : sorted;

    final spots = last.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final spots2 = type.hasTwoValues
        ? last.asMap().entries
            .where((e) => e.value.value2 != null)
            .map((e) => FlSpot(e.key.toDouble(), e.value.value2!))
            .toList()
        : <FlSpot>[];

    final allValues = [
      ...spots.map((s) => s.y),
      ...spots2.map((s) => s.y),
    ];
    final minY = (allValues.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, 9999.0);
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 5;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, meta) => Text(
                  val.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: last.length > 10 ? (last.length / 5).ceilToDouble() : 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= last.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppFormatters.formatDate(last[idx].dateTime).substring(0, 5),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF00897B),
              barWidth: 2.5,
              dotData: FlDotData(
                show: spots.length <= 15,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF00897B),
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00897B).withAlpha(25),
              ),
            ),
            if (spots2.isNotEmpty)
              LineChartBarData(
                spots: spots2,
                isCurved: true,
                color: const Color(0xFF0288D1),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: spots2.length <= 15,
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF0288D1),
                    strokeWidth: 0,
                  ),
                ),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.spotIndex;
                if (idx >= last.length) return null;
                return LineTooltipItem(
                  s.y.toStringAsFixed(1),
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
