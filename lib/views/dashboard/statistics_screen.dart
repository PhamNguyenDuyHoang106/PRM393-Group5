import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_strings.dart';
import '../../providers/providers.dart';
import '../../models/statistics.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  bool _showStatusStats = true; // True for Status, False for Priority
  String _dateRange = 'All Time'; // Date range filter state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      ref.read(dashboardViewModelProvider.notifier).loadStatistics(
        dateRange: _dateRange,
        userId: user?.id,
        role: user?.role,
      );
    });
  }

  void _exportStatistics(BuildContext context, AppStrings strings, Statistics? stats) async {
    if (stats == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(strings.exportingReport, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    var succeeded = false;
    try {
      final csvBytes = Uint8List.fromList(utf8.encode(_buildCsvReport(stats, strings)));
      await Share.shareXFiles(
        [
          XFile.fromData(
            csvBytes,
            name: 'task_statistics_${DateTime.now().millisecondsSinceEpoch}.csv',
            mimeType: 'text/csv',
          ),
        ],
        subject: strings.csvReportTitle,
      );
      succeeded = true;
    } catch (_) {
      succeeded = false;
    } finally {
      if (context.mounted) Navigator.pop(context); // Dismiss loading dialog
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(succeeded ? strings.exportSuccess : strings.exportFailed),
          backgroundColor: succeeded ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _buildCsvReport(Statistics stats, AppStrings strings) {
    final now = DateTime.now();
    final dateLabel = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final buffer = StringBuffer()
      ..writeln(strings.csvReportTitle)
      ..writeln(strings.generatedOnLabel(dateLabel))
      ..writeln();

    void writeSection(String title, Map<String, int> dataMap) {
      final total = dataMap.values.fold(0, (sum, val) => sum + val);
      buffer.writeln(title);
      buffer.writeln('${strings.statusLabel},${strings.columnCount},${strings.columnPercentage}');
      dataMap.forEach((key, value) {
        final percentage = total > 0 ? (value / total) * 100 : 0.0;
        buffer.writeln('${strings.categoryLabel(key)},$value,${percentage.toStringAsFixed(1)}%');
      });
      buffer.writeln();
    }

    writeSection(strings.statusDistribution, stats.taskStatusDistribution);
    writeSection(strings.priorityDistribution, stats.taskPriorityDistribution);

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final stats = dashboardState.statistics;
    final strings = AppStrings(ref.watch(settingsViewModelProvider).isVietnamese);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.taskStatisticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: strings.exportStatistics,
            onPressed: stats == null ? null : () => _exportStatistics(context, strings, stats),
          ),
        ],
      ),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
              ? _buildEmptyState(strings)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTimeFilter(strings),
                      const SizedBox(height: 16),
                      _buildSelectorToggle(strings),
                      const SizedBox(height: 24),
                      _buildChartSection(stats, strings),
                      const SizedBox(height: 24),
                      _buildDetailsList(stats, strings),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(AppStrings strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pie_chart_outline, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(strings.noStatisticsData, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final user = ref.read(authViewModelProvider).user;
              ref.read(dashboardViewModelProvider.notifier).loadStatistics(
                dateRange: _dateRange,
                userId: user?.id,
                role: user?.role,
              );
            },
            child: Text(strings.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(AppStrings strings) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment<String>(
          value: 'All Time',
          label: Text(strings.filterAll),
          icon: const Icon(Icons.date_range_rounded),
        ),
        ButtonSegment<String>(
          value: 'This Week',
          label: Text(strings.filterWeek),
          icon: const Icon(Icons.calendar_view_week_rounded),
        ),
        ButtonSegment<String>(
          value: 'This Month',
          label: Text(strings.filterMonth),
          icon: const Icon(Icons.calendar_month_rounded),
        ),
      ],
      selected: {_dateRange},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _dateRange = newSelection.first;
        });
        final user = ref.read(authViewModelProvider).user;
        ref.read(dashboardViewModelProvider.notifier).loadStatistics(
          dateRange: _dateRange,
          userId: user?.id,
          role: user?.role,
        );
      },
    );
  }

  Widget _buildSelectorToggle(AppStrings strings) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment<bool>(
          value: true,
          label: Text(strings.byStatus),
          icon: const Icon(Icons.donut_large),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text(strings.byPriority),
          icon: const Icon(Icons.bar_chart),
        ),
      ],
      selected: {_showStatusStats},
      onSelectionChanged: (Set<bool> newSelection) {
        setState(() {
          _showStatusStats = newSelection.first;
        });
      },
    );
  }

  Widget _buildChartSection(Statistics stats, AppStrings strings) {
    final dataMap = _showStatusStats ? stats.taskStatusDistribution : stats.taskPriorityDistribution;
    final total = dataMap.values.fold(0, (sum, val) => sum + val);

    if (total == 0) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(strings.noTasksFound)),
      );
    }

    return _showStatusStats
        ? _buildPieChart(dataMap, total, strings)
        : _buildBarChart(dataMap, strings);
  }

  Widget _buildPieChart(Map<String, int> dataMap, int total, AppStrings strings) {
    final List<PieChartSectionData> sections = [];

    dataMap.forEach((key, value) {
      if (value > 0) {
        final percentage = (value / total) * 100;
        sections.add(
          PieChartSectionData(
            color: _getColorForCategory(key),
            value: value.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              strings.statusDistribution,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(dataMap, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> dataMap, AppStrings strings) {
    final keys = dataMap.keys.toList();
    final maxValue = dataMap.values.isEmpty
        ? 0
        : dataMap.values.reduce((a, b) => a > b ? a : b);

    final barGroups = <BarChartGroupData>[
      for (var i = 0; i < keys.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (dataMap[keys[i]] ?? 0).toDouble(),
              color: _getColorForCategory(keys[i]),
              width: 32,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              strings.priorityDistribution,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxValue == 0 ? 1 : maxValue + 1).toDouble(),
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= keys.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              strings.categoryLabel(keys[index]),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(dataMap, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, int> dataMap, AppStrings strings) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: dataMap.keys.map((key) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getColorForCategory(key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('${strings.categoryLabel(key)} (${dataMap[key]})'),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailsList(Statistics stats, AppStrings strings) {
    final dataMap = _showStatusStats ? stats.taskStatusDistribution : stats.taskPriorityDistribution;
    final total = dataMap.values.fold(0, (sum, val) => sum + val);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dataMap.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final key = dataMap.keys.elementAt(index);
          final val = dataMap[key] ?? 0;
          final percentage = total > 0 ? (val / total) * 100 : 0.0;

          return ListTile(
            leading: Icon(Icons.circle, color: _getColorForCategory(key), size: 16),
            title: Text(strings.categoryLabel(key), style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(strings.taskCount(val), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColorForCategory(String key) {
    switch (key.toUpperCase()) {
      case 'TODO':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'DONE':
        return Colors.green;
      case 'LOW':
        return Colors.grey;
      case 'MEDIUM':
        return Colors.indigo;
      case 'HIGH':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}
