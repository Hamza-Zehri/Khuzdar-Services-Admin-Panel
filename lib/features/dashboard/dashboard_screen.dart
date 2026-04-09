import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/stats_provider.dart';
import '../../shared/widgets/stat_card.dart';
import '../../core/constants/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Consumer<StatsProvider>(
              builder: (context, statsData, _) {
                final stats = statsData.stats;
                return GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: MediaQuery.of(context).size.width > 1200 ? 2.2 : 1.8,
                  children: [
                    StatCard(
                      title: 'Total Users',
                      value: stats['totalUsers'].toString(),
                      icon: Icons.people,
                      accentColor: AppColors.primary,
                    ),
                    StatCard(
                      title: 'Total Providers',
                      value: stats['totalProviders'].toString(),
                      icon: Icons.store,
                      accentColor: Colors.blue,
                    ),
                    StatCard(
                      title: 'Pending Approvals',
                      value: stats['pendingApprovals'].toString(),
                      icon: Icons.hourglass_top,
                      accentColor: (stats['pendingApprovals'] ?? 0) > 0 ? AppColors.accent : Colors.grey,
                    ),
                    StatCard(
                      title: 'Active Chats Today',
                      value: stats['activeChats'].toString(),
                      icon: Icons.chat,
                      accentColor: Colors.green,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Example Charts Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('New Users Per Day (Last 30 Days)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: LineChart(
                              LineChartData(
                                // Mock Data for Line Chart
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      const FlSpot(0, 1),
                                      const FlSpot(1, 3),
                                      const FlSpot(2, 2),
                                      const FlSpot(3, 5),
                                      const FlSpot(4, 3.5),
                                      const FlSpot(5, 4),
                                      const FlSpot(6, 6),
                                    ],
                                    isCurved: true,
                                    color: AppColors.primary,
                                    barWidth: 4,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.2)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (MediaQuery.of(context).size.width > 900) const SizedBox(width: 16),
                if (MediaQuery.of(context).size.width > 900)
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Provider Types', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 300,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(color: AppColors.primary, value: 60, title: 'Shop (60%)', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
                                    PieChartSectionData(color: AppColors.accent, value: 40, title: 'Ind. (40%)', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
