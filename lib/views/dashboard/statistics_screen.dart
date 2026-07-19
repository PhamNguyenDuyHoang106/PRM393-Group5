import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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

  void _exportStatistics(BuildContext context) async {
    // Show a loading dialog to simulate generation/export
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting report...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate database write / CSV file generation delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statistics report exported successfully as CSV!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final stats = dashboardState.statistics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export Statistics',
            onPressed: () => _exportStatistics(context),
          ),
        ],
      ),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTimeFilter(),
                      const SizedBox(height: 16),
                      _buildSelectorToggle(),
                      const SizedBox(height: 24),
                      _buildChartSection(stats),
                      const SizedBox(height: 24),
                      _buildDetailsList(stats),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pie_chart_outline, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No statistics data available', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'All Time',
          label: Text('All'),
          icon: Icon(Icons.date_range_rounded),
        ),
        ButtonSegment<String>(
          value: 'This Week',
          label: Text('Week'),
          icon: Icon(Icons.calendar_view_week_rounded),
        ),
        ButtonSegment<String>(
          value: 'This Month',
          label: Text('Month'),
          icon: Icon(Icons.calendar_month_rounded),
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

  Widget _buildSelectorToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: true,
          label: Text('By Status'),
          icon: Icon(Icons.donut_large),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text('By Priority'),
          icon: Icon(Icons.bar_chart),
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

  Widget _buildChartSection(Statistics stats) {
    final dataMap = _showStatusStats ? stats.taskStatusDistribution : stats.taskPriorityDistribution;
    final total = dataMap.values.fold(0, (sum, val) => sum + val);

    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No tasks found')),
      );
    }

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
              _showStatusStats ? 'Status Distribution' : 'Priority Distribution',
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
            _buildLegend(dataMap),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, int> dataMap) {
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
            Text('$key (${dataMap[key]})'),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailsList(Statistics stats) {
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
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$val tasks', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
