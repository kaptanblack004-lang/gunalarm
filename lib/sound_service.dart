import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const List<String> defaultSounds = [
    'Classic Alarm',
    'Digital Beep',
    'Gentle Wake',
    'Nature Sounds',
    'Church Bells',
    'Rooster Call',
    'Morning Birds',
    'Ocean Waves',
  ];

  static const Map<String, String> soundPaths = {
    'Classic Alarm': 'assets/sounds/classic_alarm.mp3',
    'Digital Beep': 'assets/sounds/digital_beep.mp3',
    'Gentle Wake': 'assets/sounds/gentle_wake.mp3',
    'Nature Sounds': 'assets/sounds/nature.mp3',
    'Church Bells': 'assets/sounds/bells.mp3',
    'Rooster Call': 'assets/sounds/rooster.mp3',
    'Morning Birds': 'assets/sounds/birds.mp3',
    'Ocean Waves': 'assets/sounds/ocean.mp3',
  };

  Future<String> getSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_alarm_sound') ?? defaultSounds.first;
  }

  Future<void> setSelectedSound(String soundName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_alarm_sound', soundName);
  }

  Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('alarm_volume') ?? 0.8;
  }

  Future<void> setVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('alarm_volume', volume);
  }

  Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vibration_enabled') ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', enabled);
  }

  Future<List<String>> getCustomSounds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('custom_sounds') ?? [];
  }

  Future<void> addCustomSound(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final customSounds = await getCustomSounds();
    customSounds.add(filePath);
    await prefs.setStringList('custom_sounds', customSounds);
  }

  Future<void> removeCustomSound(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final customSounds = await getCustomSounds();
    customSounds.remove(filePath);
    await prefs.setStringList('custom_sounds', customSounds);
  }

  Future<void> playAlarmSound() async {
    final soundName = await getSelectedSound();
    final volume = await getVolume();
    final vibrationEnabled = await getVibrationEnabled();
    
    debugPrint('Playing alarm sound: $soundName');
    debugPrint('Volume: $volume');
    debugPrint('Vibration: $vibrationEnabled');
    
    // Gerçek uygulamada burada:
    // 1. AudioPlayer ile ses çal
    // 2. Vibration API ile titreþim
    // 3. Volume kontrolü
    
    // Simülasyon
    await _simulateAlarmPlay(soundName, volume, vibrationEnabled);
  }

  Future<void> _simulateAlarmPlay(String soundName, double volume, bool vibration) async {
    debugPrint('=== ALARM PLAYING ===');
    debugPrint('Sound: $soundName');
    debugPrint('Volume: ${(volume * 100).toInt()}%');
    debugPrint('Vibration: ${vibration ? "ON" : "OFF"}');
    debugPrint('==================');
  }

  Future<void> stopAlarmSound() async {
    debugPrint('Alarm sound stopped');
    // Gerçek uygulamada AudioPlayer.stop()
  }

  String getSoundPath(String soundName) {
    return soundPaths[soundName] ?? 'assets/sounds/default.mp3';
  }

  bool isCustomSound(String soundName) {
    return !defaultSounds.contains(soundName);
  }
}
