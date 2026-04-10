import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SunriseAlarmService {
  static final SunriseAlarmService _instance = SunriseAlarmService._internal();
  factory SunriseAlarmService() => _instance;
  SunriseAlarmService._internal();

  Future<bool> getSunriseAlarmEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sunrise_alarm_enabled') ?? false;
  }

  Future<void> setSunriseAlarmEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sunrise_alarm_enabled', enabled);
  }

  Future<int> getSunriseDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sunrise_duration') ?? 30; // 30 dakika
  }

  Future<void> setSunriseDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sunrise_duration', minutes);
  }

  Future<String> getSunriseColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sunrise_color') ?? 'Warm';
  }

  Future<void> setSunriseColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sunrise_color', color);
  }

  static const Map<String, List<Color>> sunriseColors = {
    'Warm': [
      Color(0xFF1A0000), // Koyu kýrmýzý
      Color(0xFF330000), 
      Color(0xFF4D0000),
      Color(0xFF660000),
      Color(0xFF800000),
      Color(0xFF993300),
      Color(0xFFB36600),
      Color(0xFFCC9900),
      Color(0xFFE6CC00),
      Color(0xFFFFCC00), // Sarý
    ],
    'Cool': [
      Color(0xFF000033), // Koyu mavi
      Color(0xFF000066),
      Color(0xFF000099),
      Color(0xFF0000CC),
      Color(0xFF0033FF),
      Color(0xFF0066FF),
      Color(0xFF0099FF),
      Color(0xFF00CCFF),
      Color(0xFF33FFFF),
      Color(0xFF66FFFF), // Açýk cyan
    ],
    'Nature': [
      Color(0xFF001A00), // Koyu yeþil
      Color(0xFF003300),
      Color(0xFF004D00),
      Color(0xFF006600),
      Color(0xFF008000),
      Color(0xFF339933),
      Color(0xFF66B266),
      Color(0xFF99CC99),
      Color(0xFFCCE6CC),
      Color(0xFFE6FFE6), // Açýk yeþil
    ],
    'Purple': [
      Color(0xFF1A001A), // Koyu mor
      Color(0xFF330033),
      Color(0xFF4D004D),
      Color(0xFF660066),
      Color(0xFF800080),
      Color(0xFF993399),
      Color(0xFFB366B3),
      Color(0xFFCC99CC),
      Color(0xFFE6CCE6),
      Color(0xFFF0E6F0), // Açýk mor
    ],
  };

  Future<void> startSunriseSequence({
    required VoidCallback onComplete,
    required Function(Color) onColorChange,
  }) async {
    final enabled = await getSunriseAlarmEnabled();
    if (!enabled) return;

    final duration = await getSunriseDuration();
    final colorType = await getSunriseColor();
    final colors = sunriseColors[colorType] ?? sunriseColors['Warm']!;

    debugPrint('=== SUNRISE ALARM START ===');
    debugPrint('Duration: $duration minutes');
    debugPrint('Color Type: $colorType');
    debugPrint('==========================');

    final totalSteps = colors.length;
    final stepDuration = Duration(minutes: duration) ~/ totalSteps;

    for (int i = 0; i < colors.length; i++) {
      final color = colors[i];
      final progress = (i + 1) / colors.length;
      
      debugPrint('Sunrise step ${i + 1}/${colors.length}: ${(progress * 100).toInt()}%');
      
      onColorChange(color);
      
      // Son adýmda callback çaðýr
      if (i == colors.length - 1) {
        onComplete();
      }
      
      await Future.delayed(Duration(seconds: stepDuration));
    }

    debugPrint('=== SUNRISE ALARM COMPLETE ===');
  }

  List<String> getAvailableColors() {
    return sunriseColors.keys.toList();
  }

  String getColorDescription(String colorType) {
    switch (colorType) {
      case 'Warm':
        return 'Ilýk ve güneþ þeklinde';
      case 'Cool':
        return 'Serin ve gökyüzü þeklinde';
      case 'Nature':
        return 'Doðal ve yeþil tonlarda';
      case 'Purple':
        return 'Romantik ve mor tonlarda';
      default:
        return 'Bilinmeyen renk';
    }
  }

  Color getCurrentColor(String colorType, double progress) {
    final colors = sunriseColors[colorType] ?? sunriseColors['Warm']!;
    final index = (progress * (colors.length - 1)).floor();
    return colors[index.clamp(0, colors.length - 1));
  }

  Future<void> testSunriseSequence({
    required Function(Color) onColorChange,
  }) async {
    final colorType = await getSunriseColor();
    final colors = sunriseColors[colorType] ?? sunriseColors['Warm']!;

    debugPrint('=== SUNRISE TEST START ===');

    // Test için hýzlý gösterim (5 saniye)
    for (int i = 0; i < colors.length; i++) {
      final color = colors[i];
      onColorChange(color);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('=== SUNRISE TEST END ===');
  }
}
