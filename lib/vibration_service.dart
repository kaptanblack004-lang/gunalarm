import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  static const Map<String, List<int>> vibrationPatterns = {
    'Standard': [0, 500, 200, 500],
    'Pulse': [0, 200, 100, 200, 100, 200],
    'Heartbeat': [0, 100, 50, 100, 50, 200],
    'Wave': [0, 300, 200, 300, 200, 300],
    'Morse': [0, 100, 50, 100, 50, 100, 50, 300],
    'Gentle': [0, 100, 100, 100, 100, 100],
    'Strong': [0, 1000, 500, 1000],
    'Custom': [0, 300, 200, 300, 200, 300, 200, 300],
  };

  Future<String> getVibrationPattern() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('vibration_pattern') ?? 'Standard';
  }

  Future<void> setVibrationPattern(String pattern) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vibration_pattern', pattern);
  }

  Future<bool> hasVibrator() async {
    try {
      return await Vibration.hasVibrator() ?? false;
    } catch (e) {
      debugPrint('Vibration check error: $e');
      return false;
    }
  }

  Future<void> vibratePattern(String patternName) async {
    final hasVib = await hasVibrator();
    if (!hasVib) {
      debugPrint('Device has no vibrator');
      return;
    }

    final pattern = vibrationPatterns[patternName] ?? vibrationPatterns['Standard']!;
    
    debugPrint('=== VIBRATION PATTERN ===');
    debugPrint('Pattern: $patternName');
    debugPrint('Sequence: $pattern');
    debugPrint('========================');

    try {
      await Vibration.vibrate(pattern: pattern);
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> vibrateAlarmSequence() async {
    final hasVib = await hasVibrator();
    if (!hasVib) return;

    final pattern = await getVibrationPattern();
    
    debugPrint('=== ALARM VIBRATION START ===');
    
    // 3 kere tekrar et
    for (int i = 0; i < 3; i++) {
      debugPrint('Vibration sequence ${i + 1}/3');
      await vibratePattern(pattern);
      await Future.delayed(const Duration(seconds: 2));
    }
    
    debugPrint('=== ALARM VIBRATION END ===');
  }

  Future<void> vibrateSnooze() async {
    final hasVib = await hasVibrator();
    if (!hasVib) return;

    debugPrint('=== SNOOZE VIBRATION ===');
    
    // Kýsa ve nazik titreþim
    try {
      await Vibration.vibrate(duration: 200);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 200);
    } catch (e) {
      debugPrint('Snooze vibration error: $e');
    }
    
    debugPrint('========================');
  }

  Future<void> testVibration(String patternName) async {
    await vibratePattern(patternName);
  }

  List<String> getAvailablePatterns() {
    return vibrationPatterns.keys.toList();
  }

  String getPatternDescription(String patternName) {
    switch (patternName) {
      case 'Standard':
        return 'Standart alarm titreþimi';
      case 'Pulse':
        return 'Hýzlý nabz þeklinde';
      case 'Heartbeat':
        return 'Kalp atýþý ritminde';
      case 'Wave':
        return 'Dalga þeklinde artýþ';
      case 'Morse':
        return 'Morse kodu þeklinde';
      case 'Gentle':
        return 'Nazik ve yumuþak';
      case 'Strong':
        return 'Güçlü ve uzun';
      case 'Custom':
        return 'Özel ayarlý';
      default:
        return 'Bilinmeyen pattern';
    }
  }
}
