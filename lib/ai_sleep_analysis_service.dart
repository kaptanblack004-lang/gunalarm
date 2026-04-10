import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_statistics_service.dart';

class SleepData {
  final DateTime date;
  final DateTime? sleepTime;
  final DateTime? wakeTime;
  final int sleepQuality; // 1-10
  final int snoozeCount;
  final bool wasCompleted;

  SleepData({
    required this.date,
    this.sleepTime,
    this.wakeTime,
    required this.sleepQuality,
    required this.snoozeCount,
    required this.wasCompleted,
  });

  Duration? get sleepDuration {
    if (sleepTime != null && wakeTime != null) {
      return wakeTime!.difference(sleepTime!);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'sleepTime': sleepTime?.toIso8601String(),
      'wakeTime': wakeTime?.toIso8601String(),
      'sleepQuality': sleepQuality,
      'snoozeCount': snoozeCount,
      'wasCompleted': wasCompleted,
    };
  }

  factory SleepData.fromJson(Map<String, dynamic> json) {
    return SleepData(
      date: DateTime.parse(json['date']),
      sleepTime: json['sleepTime'] != null ? DateTime.parse(json['sleepTime']) : null,
      wakeTime: json['wakeTime'] != null ? DateTime.parse(json['wakeTime']) : null,
      sleepQuality: json['sleepQuality'] ?? 5,
      snoozeCount: json['snoozeCount'] ?? 0,
      wasCompleted: json['wasCompleted'] ?? false,
    );
  }
}

class SleepAnalysisResult {
  final double sleepScore;
  final String sleepType;
  final List<String> recommendations;
  final TimeOfDay optimalWakeTime;
  final TimeOfDay optimalSleepTime;
  final double sleepEfficiency;
  final String sleepPhase;

  SleepAnalysisResult({
    required this.sleepScore,
    required this.sleepType,
    required this.recommendations,
    required this.optimalWakeTime,
    required this.optimalSleepTime,
    required this.sleepEfficiency,
    required this.sleepPhase,
  });
}

class AISleepAnalysisService {
  static final AISleepAnalysisService _instance = AISleepAnalysisService._internal();
  factory AISleepAnalysisService() => _instance;
  AISleepAnalysisService._internal();

  static const String _sleepDataKey = 'ai_sleep_data';

  Future<void> recordSleepData(SleepData sleepData) async {
    final prefs = await SharedPreferences.getInstance();
    final sleepDataJson = prefs.getStringList(_sleepDataKey) ?? [];
    
    sleepDataJson.add(jsonEncode(sleepData.toJson()));
    await prefs.setStringList(_sleepDataKey, sleepDataJson);
  }

  Future<List<SleepData>> getSleepData() async {
    final prefs = await SharedPreferences.getInstance();
    final sleepDataJson = prefs.getStringList(_sleepDataKey) ?? [];
    
    return sleepDataJson
        .map((json) => SleepData.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<SleepAnalysisResult> analyzeSleepPatterns() async {
    final sleepData = await getSleepData();
    
    if (sleepData.isEmpty) {
      return _getDefaultAnalysis();
    }

    // Son 30 günün verilerini al
    final recentData = sleepData.where((data) {
      final daysSince = DateTime.now().difference(data.date).inDays;
      return daysSince <= 30;
    }).toList();

    if (recentData.isEmpty) {
      return _getDefaultAnalysis();
    }

    // Uyku kalitesi analizi
    final avgSleepQuality = recentData
        .map((data) => data.sleepQuality.toDouble())
        .reduce((a, b) => a + b) / recentData.length;

    // Uyku süresi analizi
    final sleepDurations = recentData
        .map((data) => data.sleepDuration?.inHours ?? 0.0)
        .where((hours) => hours > 0)
        .toList();

    final avgSleepDuration = sleepDurations.isEmpty ? 0.0 :
        sleepDurations.reduce((a, b) => a + b) / sleepDurations.length;

    // Snooze analizi
    final avgSnoozeCount = recentData
        .map((data) => data.snoozeCount)
        .reduce((a, b) => a + b) / recentData.length;

    // Tamamlanma orani
    final completionRate = recentData
        .where((data) => data.wasCompleted)
        .length / recentData.length;

    // AI skor hesaplama
    final sleepScore = _calculateSleepScore(
      avgSleepQuality,
      avgSleepDuration,
      avgSnoozeCount,
      completionRate,
    );

    // Uyku tipi belirleme
    final sleepType = _determineSleepType(avgSleepDuration, avgSleepQuality);

    // Optimal zamanlar
    final optimalWakeTime = _calculateOptimalWakeTime(recentData);
    final optimalSleepTime = _calculateOptimalSleepTime(optimalWakeTime);

    // Uyku verimliliði
    final sleepEfficiency = _calculateSleepEfficiency(avgSleepDuration, avgSleepQuality);

    // Uyku fazý
    final sleepPhase = _determineSleepPhase(DateTime.now());

    // Öneriler
    final recommendations = _generateRecommendations(
      sleepScore,
      avgSleepDuration,
      avgSleepQuality,
      avgSnoozeCount,
      completionRate,
    );

    return SleepAnalysisResult(
      sleepScore: sleepScore,
      sleepType: sleepType,
      recommendations: recommendations,
      optimalWakeTime: optimalWakeTime,
      optimalSleepTime: optimalSleepTime,
      sleepEfficiency: sleepEfficiency,
      sleepPhase: sleepPhase,
    );
  }

  double _calculateSleepScore(
    double quality,
    double duration,
    double snoozeCount,
    double completionRate,
  ) {
    double score = 0.0;

    // Uyku kalitesi (40%)
    score += (quality / 10) * 40;

    // Uyku süresi (30%) - 7-8 saat ideal
    if (duration >= 7 && duration <= 8) {
      score += 30;
    } else if (duration >= 6 && duration <= 9) {
      score += 20;
    } else {
      score += 10;
    }

    // Snooze sayýsý (15%) - daha az snooze daha iyi
    if (snoozeCount <= 0.5) {
      score += 15;
    } else if (snoozeCount <= 1.5) {
      score += 10;
    } else if (snoozeCount <= 2.5) {
      score += 5;
    } else {
      score += 0;
    }

    // Tamamlanma orani (15%)
    score += completionRate * 15;

    return score.clamp(0.0, 100.0);
  }

  String _determineSleepType(double duration, double quality) {
    if (duration >= 7.5 && duration <= 8.5 && quality >= 7) {
      return 'Ýdeal Uyku';
    } else if (duration >= 6 && duration <= 9 && quality >= 6) {
      return 'Ýyi Uyku';
    } else if (duration >= 5 && duration <= 10 && quality >= 4) {
      return 'Orta Uyku';
    } else if (duration >= 4 && quality >= 3) {
      return 'Zayýf Uyku';
    } else {
      return 'Kötü Uyku';
    }
  }

  TimeOfDay _calculateOptimalWakeTime(List<SleepData> data) {
    // En yüksek tamamlanma oranýna sahip uyanma saatini bul
    final wakeTimeStats = <int, List<bool>>{};
    
    for (final sleepData in data) {
      if (sleepData.wakeTime != null) {
        final hour = sleepData.wakeTime!.hour;
        wakeTimeStats.putIfAbsent(hour, () => []).add(sleepData.wasCompleted);
      }
    }

    double bestScore = 0.0;
    int bestHour = 7; // Varsayýlan

    for (final entry in wakeTimeStats.entries) {
      final completions = entry.value.where((completed) => completed).length;
      final total = entry.value.length;
      final score = total > 0 ? completions / total : 0.0;
      
      if (score > bestScore) {
        bestScore = score;
        bestHour = entry.key;
      }
    }

    // Biyolojik saat ayarý
    final adjustedHour = _adjustForChronotype(bestHour);
    
    return TimeOfDay(hour: adjustedHour, minute: 0);
  }

  TimeOfDay _calculateOptimalSleepTime(TimeOfDay wakeTime) {
    // 7.5 saat uyku önerisi
    final sleepHour = (wakeTime.hour - 7 + 24) % 24;
    return TimeOfDay(hour: sleepHour, minute: 30);
  }

  int _adjustForChronotype(int preferredHour) {
    // Basit kronotip ayarý
    // Bu daha geliþtirilebilir (kullanýcý verilerine göre)
    if (preferredHour < 6) return 6; // Çok erken
    if (preferredHour > 9) return 8; // Çok geç
    return preferredHour;
  }

  double _calculateSleepEfficiency(double duration, double quality) {
    // Uyku verimliliði = (Uyku süresi * Kalite) / Maksimum
    final maxDuration = 10.0; // 10 saat maksimum
    return (duration * quality) / (maxDuration * 10) * 100;
  }

  String _determineSleepPhase(DateTime now) {
    final hour = now.hour;
    
    if (hour >= 22 || hour < 2) {
      return 'Derin Uyku Zamaný';
    } else if (hour >= 2 && hour < 6) {
      return 'REM Uyku Zamaný';
    } else if (hour >= 6 && hour < 10) {
      return 'Uyanma Zamaný';
    } else if (hour >= 10 && hour < 14) {
      return 'Aktif Gün';
    } else if (hour >= 14 && hour < 18) {
      return 'Ýkindi Durgunluðu';
    } else {
      return 'Akþam Hazýrlýðý';
    }
  }

  List<String> _generateRecommendations(
    double score,
    double duration,
    double quality,
    double snoozeCount,
    double completionRate,
  ) {
    final recommendations = <String>[];

    if (duration < 6) {
      recommendations.add('Uyku sürenizi 7-8 saate çýkarýn. Bu daha iyi dinlenme saðlar.');
    } else if (duration > 9) {
      recommendations.add('Uyku sürenüz fazla. 7-8 saat idealdir.');
    }

    if (quality < 6) {
      recommendations.add('Uyku kalitenizi artýrmak için yatak odasýnýzý karanlatýn ve serin tutun.');
    }

    if (snoozeCount > 2) {
      recommendations.add('Erteleme sayýsýný azaltmak için daha erken uyanmayý deneyin.');
    }

    if (completionRate < 70) {
      recommendations.add('Alarm baþarý oranýnýzý artýrmak için daha düzenli uyku saati belirleyin.');
    }

    if (score >= 80) {
      recommendations.add('Harika uyku alýþkanlýklarýnýz! Mevcut rutininizi devam ettirin.');
    }

    // Genel öneriler
    recommendations.add('Uyumadan 1 saat önce ekran kullanýmýný azaltýn.');
    recommendations.add('Kafein alýmýný öðleden sonra sýnýrlayýn.');
    recommendations.add('Her gün ayný saatte uyanmaya çalýþýn.');

    return recommendations;
  }

  SleepAnalysisResult _getDefaultAnalysis() {
    return SleepAnalysisResult(
      sleepScore: 50.0,
      sleepType: 'Veri Yok',
      recommendations: [
        'Daha iyi analiz için en az 1 hafta kullaným verisi gerekli.',
        'Her gün alarm kurarak uyku verilerinizi toplamaya baþlayýn.',
      ],
      optimalWakeTime: const TimeOfDay(hour: 7, minute: 0),
      optimalSleepTime: const TimeOfDay(hour: 23, minute: 30),
      sleepEfficiency: 50.0,
      sleepPhase: 'Analiz Bekleniyor',
    );
  }

  Future<void> clearSleepData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepDataKey);
  }

  Future<void> exportSleepData() async {
    // Veri export fonksiyonu
    final sleepData = await getSleepData();
    // CSV veya JSON formatýnda export edilebilir
    debugPrint('Exported ${sleepData.length} sleep records');
  }
}
