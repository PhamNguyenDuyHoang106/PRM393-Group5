import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/statistics.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  bool _showStatusStats = true; // True for Status, False for Priority

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardViewModelProvider.notifier).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final stats = dashboardState.statistics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardViewModelProvider.notifier).refreshData(),
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
          const Text('Không có dữ liệu thống kê', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.read(dashboardViewModelProvider.notifier).loadStatistics(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: true,
          label: Text('Theo Trạng thái'),
          icon: Icon(Icons.donut_large),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text('Theo Mức độ ưu tiên'),
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
        child: Center(child: Text('Không có công việc nào')),
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
              _showStatusStats ? 'Phân bổ theo trạng thái' : 'Phân bổ theo độ ưu tiên',
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
