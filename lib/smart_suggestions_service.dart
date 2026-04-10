import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_statistics_service.dart';

class SleepPattern {
  final int hour;
  final int minute;
  final int frequency;
  final double completionRate;

  SleepPattern({
    required this.hour,
    required this.minute,
    required this.frequency,
    required this.completionRate,
  });
}

class SmartSuggestion {
  final String id;
  final String title;
  final String description;
  final String type; // 'sleep_time', 'wake_time', 'duration', 'habit'
  final IconData icon;
  final Color color;
  final int priority; // 1-5

  SmartSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.priority,
  });
}

class SmartSuggestionsService {
  static final SmartSuggestionsService _instance = SmartSuggestionsService._internal();
  factory SmartSuggestionsService() => _instance;
  SmartSuggestionsService._internal();

  Future<List<SmartSuggestion>> getSmartSuggestions() async {
    final suggestions = <SmartSuggestion>[];
    
    // 1. Uyku analizi
    final sleepPatterns = await _analyzeSleepPatterns();
    suggestions.addAll(_generateSleepTimeSuggestions(sleepPatterns));
    
    // 2. Uyanma analizi
    final wakePatterns = await _analyzeWakePatterns();
    suggestions.addAll(_generateWakeTimeSuggestions(wakePatterns));
    
    // 3. Snooze analizi
    final snoozeStats = await _analyzeSnoozePatterns();
    suggestions.addAll(_generateSnoozeSuggestions(snoozeStats));
    
    // 4. Haftalýk performans
    final weeklyStats = await AlarmStatisticsService().getWeeklyStats();
    suggestions.addAll(_generatePerformanceSuggestions(weeklyStats));
    
    // 5. Önerileri önceliklendir
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    
    return suggestions.take(5).toList();
  }

  Future<List<SleepPattern>> _analyzeSleepPatterns() async {
    final allStats = await AlarmStatisticsService().getAllStatistics();
    final Map<String, List<AlarmStatistics>> timeGroups = {};
    
    for (final stat in allStats) {
      final hour = stat.createdAt.hour;
      final key = '$hour';
      
      if (!timeGroups.containsKey(key)) {
        timeGroups[key] = [];
      }
      timeGroups[key]!.add(stat);
    }
    
    final patterns = <SleepPattern>[];
    for (final entry in timeGroups.entries) {
      final hour = int.parse(entry.key);
      final stats = entry.value;
      
      final completionRate = stats.isEmpty ? 0.0 : 
          stats.where((s) => s.wasCompleted).length / stats.length;
      
      patterns.add(SleepPattern(
        hour: hour,
        minute: 0,
        frequency: stats.length,
        completionRate: completionRate,
      ));
    }
    
    return patterns;
  }

  Future<List<SleepPattern>> _analyzeWakePatterns() async {
    final allStats = await AlarmStatisticsService().getAllStatistics();
    final Map<String, List<AlarmStatistics>> timeGroups = {};
    
    for (final stat in allStats) {
      if (stat.completedAt != null) {
        final hour = stat.completedAt!.hour;
        final key = '$hour';
        
        if (!timeGroups.containsKey(key)) {
          timeGroups[key] = [];
        }
        timeGroups[key]!.add(stat);
      }
    }
    
    final patterns = <SleepPattern>[];
    for (final entry in timeGroups.entries) {
      final hour = int.parse(entry.key);
      final stats = entry.value;
      
      final completionRate = stats.isEmpty ? 0.0 : 
          stats.where((s) => s.wasCompleted).length / stats.length;
      
      patterns.add(SleepPattern(
        hour: hour,
        minute: 0,
        frequency: stats.length,
        completionRate: completionRate,
      ));
    }
    
    return patterns;
  }

  Future<Map<String, dynamic>> _analyzeSnoozePatterns() async {
    final allStats = await AlarmStatisticsService().getAllStatistics();
    
    final snoozedAlarms = allStats.where((s) => s.snoozeCount > 0).toList();
    final averageSnooze = await AlarmStatisticsService().getAverageSnoozeCount();
    
    return {
      'totalSnoozed': snoozedAlarms.length,
      'averageSnoozeCount': averageSnooze,
      'maxSnoozeCount': snoozedAlarms.isEmpty ? 0 : 
          snoozedAlarms.map((s) => s.snoozeCount).reduce(max),
    };
  }

  List<SmartSuggestion> _generateSleepTimeSuggestions(List<SleepPattern> patterns) {
    final suggestions = <SmartSuggestion>[];
    
    // En geç uyku saatini bul
    final latestSleep = patterns.isEmpty ? null : 
        patterns.reduce((a, b) => a.hour > b.hour ? a : b);
    
    if (latestSleep != null && latestSleep.hour > 1) {
      suggestions.add(SmartSuggestion(
        id: 'early_sleep',
        title: 'Daha Erken Uyu',
        description: 'Genellikle saat ${latestSleep.hour}:00\'da uyuyorsun. 22:00-23:00 arasý uyumaya çalýþ.',
        type: 'sleep_time',
        icon: Icons.bedtime,
        color: Colors.purple,
        priority: 4,
      ));
    }
    
    // Düzensiz uyku
    if (patterns.length > 3) {
      final avgFrequency = patterns.map((p) => p.frequency).reduce((a, b) => a + b) / patterns.length;
      if (avgFrequency < 2) {
        suggestions.add(SmartSuggestion(
          id: 'regular_sleep',
          title: 'Düzenli Uyku Saati',
          description: 'Uyku saatlerin düzensiz görünüyor. Her gün ayný saatte uyumaya çalýþ.',
          type: 'sleep_time',
          icon: Icons.schedule,
          color: Colors.blue,
          priority: 3,
        ));
      }
    }
    
    return suggestions;
  }

  List<SmartSuggestion> _generateWakeTimeSuggestions(List<SleepPattern> patterns) {
    final suggestions = <SmartSuggestion>[];
    
    // En erken uyanma saati
    if (patterns.isNotEmpty) {
      final earliestWake = patterns.reduce((a, b) => a.hour < b.hour ? a : b);
      
      if (earliestWake.hour < 6) {
        suggestions.add(SmartSuggestion(
          id: 'late_wake',
          title: 'Daha Geç Uyan',
          description: 'Genellikle saat ${earliestWake.hour}:00\'da uyanýyorsun. 7:00-8:00 arasý uyanmayý dene.',
          type: 'wake_time',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          priority: 2,
        ));
      }
      
      if (earliestWake.hour > 9) {
        suggestions.add(SmartSuggestion(
          id: 'early_wake',
          title: 'Daha Erken Uyan',
          description: 'Genellikle saat ${earliestWake.hour}:00\'da uyanýyorsun. 7:00-8:00 arasý uyanmayý dene.',
          type: 'wake_time',
          icon: Icons.wb_twilight,
          color: Colors.yellow,
          priority: 3,
        ));
      }
    }
    
    return suggestions;
  }

  List<SmartSuggestion> _generateSnoozeSuggestions(Map<String, dynamic> snoozeStats) {
    final suggestions = <SmartSuggestion>[];
    
    final averageSnooze = snoozeStats['averageSnoozeCount'] as double;
    final maxSnooze = snoozeStats['maxSnoozeCount'] as int;
    
    if (averageSnooze > 2) {
      suggestions.add(SmartSuggestion(
        id: 'reduce_snooze',
        title: 'Erteleme Sayýsýný Azalt',
        description: 'Ortalama ${averageSnooze.toStringAsFixed(1)} kez erteliyorsun. Daha erken uyanmayý dene.',
        type: 'habit',
        icon: Icons.snooze,
        color: Colors.red,
        priority: 5,
      ));
    }
    
    if (maxSnooze > 5) {
      suggestions.add(SmartSuggestion(
        id: 'extreme_snooze',
        title: 'Çok Fazla Erteleme',
        description: 'Bazý günler ${maxSnooze} kez erteliyorsun! Bu uyku kaliteni etkileyebilir.',
        type: 'habit',
        icon: Icons.warning,
        color: Colors.red,
        priority: 5,
      ));
    }
    
    return suggestions;
  }

  List<SmartSuggestion> _generatePerformanceSuggestions(Map<String, dynamic> weeklyStats) {
    final suggestions = <SmartSuggestion>[];
    
    final completionRate = weeklyStats['completionRate'] as double;
    final totalAlarms = weeklyStats['totalAlarms'] as int;
    
    if (completionRate < 50 && totalAlarms > 5) {
      suggestions.add(SmartSuggestion(
        id: 'low_completion',
        title: 'Alarm Baþarý Oraný Düþük',
        description: 'Bu hafta sadece %${completionRate.toStringAsFixed(0)} oranýnda baþarýlý oldun. Daha erken uyu.',
        type: 'habit',
        icon: Icons.trending_down,
        color: Colors.red,
        priority: 4,
      ));
    }
    
    if (completionRate > 80) {
      suggestions.add(SmartSuggestion(
        id: 'high_completion',
        title: 'Harika Ýlerleme!',
        description: 'Bu hafta %${completionRate.toStringAsFixed(0)} oranýnda baþarýlý oldun. Devam et!',
        type: 'habit',
        icon: Icons.emoji_events,
        color: Colors.green,
        priority: 1,
      ));
    }
    
    return suggestions;
  }

  Future<String> getOptimalWakeTime() async {
    final wakePatterns = await _analyzeWakePatterns();
    
    if (wakePatterns.isEmpty) {
      return '07:00'; // Varsayýlan
    }
    
    // En yüksek baþarý oranýna sahip zamaný bul
    final bestPattern = wakePatterns.reduce((a, b) => 
        a.completionRate > b.completionRate ? a : b);
    
    return '${bestPattern.hour.toString().padLeft(2, '0')}:00';
  }

  Future<String> getOptimalSleepTime() async {
    final optimalWakeTime = await getOptimalWakeTime();
    final wakeHour = int.parse(optimalWakeTime.split(':')[0]);
    
    // 7-8 saat uyku önerisi
    final sleepHour = (wakeHour - 8 + 24) % 24;
    
    return '${sleepHour.toString().padLeft(2, '0')}:00';
  }

  Future<void> saveUserFeedback(String suggestionId, bool helpful) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbackKey = 'suggestion_feedback_$suggestionId';
    await prefs.setBool(feedbackKey, helpful);
  }

  Future<bool> getSuggestionFeedback(String suggestionId) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbackKey = 'suggestion_feedback_$suggestionId';
    return prefs.getBool(feedbackKey) ?? false;
  }
}
