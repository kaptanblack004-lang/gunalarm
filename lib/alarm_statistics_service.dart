import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmStatistics {
  final String id;
  final DateTime createdAt;
  final DateTime? snoozedAt;
  final DateTime? dismissedAt;
  final DateTime? completedAt;
  final int snoozeCount;
  final bool wasCompleted;
  final String alarmLabel;

  AlarmStatistics({
    required this.id,
    required this.createdAt,
    this.snoozedAt,
    this.dismissedAt,
    this.completedAt,
    this.snoozeCount = 0,
    this.wasCompleted = false,
    required this.alarmLabel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'snoozedAt': snoozedAt?.toIso8601String(),
      'dismissedAt': dismissedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'snoozeCount': snoozeCount,
      'wasCompleted': wasCompleted,
      'alarmLabel': alarmLabel,
    };
  }

  factory AlarmStatistics.fromJson(Map<String, dynamic> json) {
    return AlarmStatistics(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      snoozedAt: json['snoozedAt'] != null ? DateTime.parse(json['snoozedAt']) : null,
      dismissedAt: json['dismissedAt'] != null ? DateTime.parse(json['dismissedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      snoozeCount: json['snoozeCount'] ?? 0,
      wasCompleted: json['wasCompleted'] ?? false,
      alarmLabel: json['alarmLabel'] ?? '',
    );
  }
}

class AlarmStatisticsService {
  static final AlarmStatisticsService _instance = AlarmStatisticsService._internal();
  factory AlarmStatisticsService() => _instance;
  AlarmStatisticsService._internal();

  static const String _statisticsKey = 'alarm_statistics';

  Future<void> recordAlarmCreated(String alarmId, String label) async {
    final stats = AlarmStatistics(
      id: alarmId,
      createdAt: DateTime.now(),
      alarmLabel: label,
    );
    
    await _saveStatistics(stats);
  }

  Future<void> recordAlarmSnoozed(String alarmId) async {
    final allStats = await getAllStatistics();
    final alarmStats = allStats.where((s) => s.id == alarmId).firstOrNull;
    
    if (alarmStats != null) {
      final updatedStats = AlarmStatistics(
        id: alarmStats.id,
        createdAt: alarmStats.createdAt,
        snoozedAt: DateTime.now(),
        dismissedAt: alarmStats.dismissedAt,
        completedAt: alarmStats.completedAt,
        snoozeCount: alarmStats.snoozeCount + 1,
        wasCompleted: alarmStats.wasCompleted,
        alarmLabel: alarmStats.alarmLabel,
      );
      
      await _updateStatistics(updatedStats);
    }
  }

  Future<void> recordAlarmDismissed(String alarmId) async {
    final allStats = await getAllStatistics();
    final alarmStats = allStats.where((s) => s.id == alarmId).firstOrNull;
    
    if (alarmStats != null) {
      final updatedStats = AlarmStatistics(
        id: alarmStats.id,
        createdAt: alarmStats.createdAt,
        snoozedAt: alarmStats.snoozedAt,
        dismissedAt: DateTime.now(),
        completedAt: alarmStats.completedAt,
        snoozeCount: alarmStats.snoozeCount,
        wasCompleted: false,
        alarmLabel: alarmStats.alarmLabel,
      );
      
      await _updateStatistics(updatedStats);
    }
  }

  Future<void> recordAlarmCompleted(String alarmId) async {
    final allStats = await getAllStatistics();
    final alarmStats = allStats.where((s) => s.id == alarmId).firstOrNull;
    
    if (alarmStats != null) {
      final updatedStats = AlarmStatistics(
        id: alarmStats.id,
        createdAt: alarmStats.createdAt,
        snoozedAt: alarmStats.snoozedAt,
        dismissedAt: alarmStats.dismissedAt,
        completedAt: DateTime.now(),
        snoozeCount: alarmStats.snoozeCount,
        wasCompleted: true,
        alarmLabel: alarmStats.alarmLabel,
      );
      
      await _updateStatistics(updatedStats);
    }
  }

  Future<List<AlarmStatistics>> getAllStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statisticsJson = prefs.getStringList(_statisticsKey) ?? [];
    
    return statisticsJson
        .map((json) => AlarmStatistics.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveStatistics(AlarmStatistics stats) async {
    final prefs = await SharedPreferences.getInstance();
    final allStats = await getAllStatistics();
    allStats.add(stats);
    
    final statisticsJson = allStats.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_statisticsKey, statisticsJson);
  }

  Future<void> _updateStatistics(AlarmStatistics updatedStats) async {
    final prefs = await SharedPreferences.getInstance();
    final allStats = await getAllStatistics();
    
    final index = allStats.indexWhere((s) => s.id == updatedStats.id);
    if (index != -1) {
      allStats[index] = updatedStats;
      
      final statisticsJson = allStats.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_statisticsKey, statisticsJson);
    }
  }

  Future<void> clearStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statisticsKey);
  }

  // Analytics methods
  Future<Map<String, dynamic>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    final allStats = await getAllStatistics();
    final weekStats = allStats.where((s) => s.createdAt.isAfter(weekStartMidnight)).toList();
    
    return {
      'totalAlarms': weekStats.length,
      'completedAlarms': weekStats.where((s) => s.wasCompleted).length,
      'dismissedAlarms': weekStats.where((s) => s.dismissedAt != null && !s.wasCompleted).length,
      'snoozedAlarms': weekStats.where((s) => s.snoozeCount > 0).length,
      'totalSnoozes': weekStats.fold<int>(0, (sum, s) => sum + s.snoozeCount),
      'completionRate': weekStats.isEmpty ? 0.0 : (weekStats.where((s) => s.wasCompleted).length / weekStats.length) * 100,
    };
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final allStats = await getAllStatistics();
    final monthStats = allStats.where((s) => s.createdAt.isAfter(monthStart)).toList();
    
    return {
      'totalAlarms': monthStats.length,
      'completedAlarms': monthStats.where((s) => s.wasCompleted).length,
      'dismissedAlarms': monthStats.where((s) => s.dismissedAt != null && !s.wasCompleted).length,
      'snoozedAlarms': monthStats.where((s) => s.snoozeCount > 0).length,
      'totalSnoozes': monthStats.fold<int>(0, (sum, s) => sum + s.snoozeCount),
      'completionRate': monthStats.isEmpty ? 0.0 : (monthStats.where((s) => s.wasCompleted).length / monthStats.length) * 100,
    };
  }

  Future<Map<String, int>> getMostUsedAlarmLabels() async {
    final allStats = await getAllStatistics();
    
    final labelCounts = <String, int>{};
    for (final stat in allStats) {
      labelCounts[stat.alarmLabel] = (labelCounts[stat.alarmLabel] ?? 0) + 1;
    }
    
    // Sýrala ve en çok kullanýlan 5 tanesini al
    final sortedLabels = Map.fromEntries(
      labelCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
    
    return Map.fromEntries(sortedLabels.entries.take(5));
  }

  Future<double> getAverageSnoozeCount() async {
    final allStats = await getAllStatistics();
    
    if (allStats.isEmpty) return 0.0;
    
    final totalSnoozes = allStats.fold<int>(0, (sum, s) => sum + s.snoozeCount);
    return totalSnoozes / allStats.length;
  }

  Future<List<Map<String, dynamic>>> getLastSevenDaysStats() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> dailyStats = [];
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final allStats = await getAllStatistics();
      final dayStats = allStats.where((s) => 
        s.createdAt.isAfter(dayStart) && s.createdAt.isBefore(dayEnd)
      ).toList();
      
      dailyStats.add({
        'date': dayStart,
        'total': dayStats.length,
        'completed': dayStats.where((s) => s.wasCompleted).length,
        'dismissed': dayStats.where((s) => s.dismissedAt != null && !s.wasCompleted).length,
        'snoozed': dayStats.where((s) => s.snoozeCount > 0).length,
      });
    }
    
    return dailyStats;
  }
}
