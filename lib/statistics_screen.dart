import 'package:flutter/material.dart';
import 'alarm_statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _weeklyStats;
  Map<String, dynamic>? _monthlyStats;
  Map<String, int>? _mostUsedLabels;
  double? _averageSnoozeCount;
  List<Map<String, dynamic>>? _lastSevenDaysStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final weeklyStats = await AlarmStatisticsService().getWeeklyStats();
      final monthlyStats = await AlarmStatisticsService().getMonthlyStats();
      final mostUsedLabels = await AlarmStatisticsService().getMostUsedAlarmLabels();
      final averageSnoozeCount = await AlarmStatisticsService().getAverageSnoozeCount();
      final lastSevenDaysStats = await AlarmStatisticsService().getLastSevenDaysStats();
      
      setState(() {
        _weeklyStats = weeklyStats;
        _monthlyStats = monthlyStats;
        _mostUsedLabels = mostUsedLabels;
        _averageSnoozeCount = averageSnoozeCount;
        _lastSevenDaysStats = lastSevenDaysStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri yüklenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Alarm Ýstatistikleri', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Haftalýk Ýstatistikler
                  _buildStatsCard(
                    title: 'Bu Hafta',
                    stats: _weeklyStats,
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Aylýk Ýstatistikler
                  _buildStatsCard(
                    title: 'Bu Ay',
                    stats: _monthlyStats,
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Son 7 Gün Grafik
                  _buildWeeklyChart(),
                  
                  const SizedBox(height: 16),
                  
                  // En Çok Kullanýlan Alarm Etiketleri
                  _buildMostUsedLabels(),
                  
                  const SizedBox(height: 16),
                  
                  // Ortalama Snooze
                  _buildAverageSnooze(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required Map<String, dynamic>? stats,
    required Color color,
  }) {
    if (stats == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Veri yok', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Toplam Alarm',
                  '${stats['totalAlarms']}',
                  Icons.alarm,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Tamamlandý',
                  '${stats['completedAlarms']}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Erteleme',
                  '${stats['totalSnoozes']}',
                  Icons.snooze,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Baþarý Oraný',
                  '${stats['completionRate'].toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    if (_lastSevenDaysStats == null || _lastSevenDaysStats!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Haftalýk veri yok', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son 7 Gün',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _lastSevenDaysStats!.length,
              itemBuilder: (context, index) {
                final dayData = _lastSevenDaysStats![index];
                final date = dayData['date'] as DateTime;
                final total = dayData['total'] as int;
                final completed = dayData['completed'] as int;
                
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: double.infinity,
                                height: (completed / (total == 0 ? 1 : total)) * 100,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostUsedLabels() {
    if (_mostUsedLabels == null || _mostUsedLabels!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'En Çok Kullanýlan Etiketler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._mostUsedLabels!.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key.isEmpty ? 'Ýsimsiz' : entry.key,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAverageSnooze() {
    if (_averageSnoozeCount == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.snooze, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ortalama Erteleme',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_averageSnoozeCount!.toStringAsFixed(1)} kez',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
