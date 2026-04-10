import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeatherCondition {
  clear,
  cloudy,
  rainy,
  snowy,
  stormy,
  foggy,
  windy,
}

enum WeatherMood {
  energetic,
  calm,
  cozy,
  focused,
  relaxed,
}

class WeatherBasedAlarm {
  final String id;
  final String weatherCondition;
  final String soundFile;
  final String vibrationPattern;
  final double volume;
  final String mood;

  WeatherBasedAlarm({
    required this.id,
    required this.weatherCondition,
    required this.soundFile,
    required this.vibrationPattern,
    required this.volume,
    required this.mood,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weatherCondition': weatherCondition,
      'soundFile': soundFile,
      'vibrationPattern': vibrationPattern,
      'volume': volume,
      'mood': mood,
    };
  }

  factory WeatherBasedAlarm.fromJson(Map<String, dynamic> json) {
    return WeatherBasedAlarm(
      id: json['id'],
      weatherCondition: json['weatherCondition'],
      soundFile: json['soundFile'],
      vibrationPattern: json['vibrationPattern'],
      volume: json['volume']?.toDouble() ?? 0.8,
      mood: json['mood'],
    );
  }
}

class WeatherBasedService {
  static final WeatherBasedService _instance = WeatherBasedService._internal();
  factory WeatherBasedService() => _instance;
  WeatherBasedService._internal();

  bool _isEnabled = false;
  List<WeatherBasedAlarm> _weatherAlarms = [];
  String? _currentWeather;
  WeatherCondition _currentCondition = WeatherCondition.clear;

  bool get isEnabled => _isEnabled;
  WeatherCondition get currentCondition => _currentCondition;
  String? get currentWeather => _currentWeather;

  static const Map<WeatherCondition, WeatherBasedAlarm> _defaultAlarms = {
    WeatherCondition.clear: WeatherBasedAlarm(
      id: 'clear_default',
      weatherCondition: 'clear',
      soundFile: 'classic_alarm.mp3',
      vibrationPattern: 'standard',
      volume: 0.7,
      mood: 'energetic',
    ),
    WeatherCondition.cloudy: WeatherBasedAlarm(
      id: 'cloudy_default',
      weatherCondition: 'cloudy',
      soundFile: 'gentle_wake.mp3',
      vibrationPattern: 'pulse',
      volume: 0.6,
      mood: 'calm',
    ),
    WeatherCondition.rainy: WeatherBasedAlarm(
      id: 'rainy_default',
      weatherCondition: 'rainy',
      soundFile: 'ocean_waves.mp3',
      vibrationPattern: 'gentle',
      volume: 0.5,
      mood: 'cozy',
    ),
    WeatherCondition.snowy: WeatherBasedAlarm(
      id: 'snowy_default',
      weatherCondition: 'snowy',
      soundFile: 'morning_birds.mp3',
      vibrationPattern: 'heartbeat',
      volume: 0.6,
      mood: 'relaxed',
    ),
    WeatherCondition.stormy: WeatherBasedAlarm(
      id: 'stormy_default',
      weatherCondition: 'stormy',
      soundFile: 'church_bells.mp3',
      vibrationPattern: 'strong',
      volume: 0.8,
      mood: 'focused',
    ),
    WeatherCondition.foggy: WeatherBasedAlarm(
      id: 'foggy_default',
      weatherCondition: 'foggy',
      soundFile: 'nature.mp3',
      vibrationPattern: 'wave',
      volume: 0.4,
      mood: 'calm',
    ),
    WeatherCondition.windy: WeatherBasedAlarm(
      id: 'windy_default',
      weatherCondition: 'windy',
      soundFile: 'digital_beep.mp3',
      vibrationPattern: 'standard',
      volume: 0.7,
      mood: 'energetic',
    ),
  };

  static const Map<WeatherCondition, List<String>> _weatherSounds = {
    WeatherCondition.clear: [
      'classic_alarm.mp3',
      'digital_beep.mp3',
      'morning_birds.mp3',
      'church_bells.mp3',
    ],
    WeatherCondition.cloudy: [
      'gentle_wake.mp3',
      'nature.mp3',
      'ocean_waves.mp3',
      'forest_birds.mp3',
    ],
    WeatherCondition.rainy: [
      'ocean_waves.mp3',
      'nature.mp3',
      'gentle_wake.mp3',
      'rain_sounds.mp3',
    ],
    WeatherCondition.snowy: [
      'morning_birds.mp3',
      'gentle_wake.mp3',
      'church_bells.mp3',
      'winter_wonderland.mp3',
    ],
    WeatherCondition.stormy: [
      'church_bells.mp3',
      'classic_alarm.mp3',
      'strong_beep.mp3',
      'emergency_alarm.mp3',
    ],
    WeatherCondition.foggy: [
      'nature.mp3',
      'gentle_wake.mp3',
      'soft_melody.mp3',
      'mysterious_sounds.mp3',
    ],
    WeatherCondition.windy: [
      'digital_beep.mp3',
      'classic_alarm.mp3',
      'energetic_beats.mp3',
      'wind_chimes.mp3',
    ],
  };

  static const Map<WeatherCondition, String> _weatherDescriptions = {
    WeatherCondition.clear: 'Açýk ve güneþli',
    WeatherCondition.cloudy: 'Bulutlu',
    WeatherCondition.rainy: 'Yaðmurlu',
    WeatherCondition.snowy: 'Karlý',
    WeatherCondition.stormy: 'Fýrtýnalý',
    WeatherCondition.foggy: 'Sisli',
    WeatherCondition.windy: 'Rüzgarlý',
  };

  static const Map<WeatherCondition, Color> _weatherColors = {
    WeatherCondition.clear: Colors.orange,
    WeatherCondition.cloudy: Colors.grey,
    WeatherCondition.rainy: Colors.blue,
    WeatherCondition.snowy: Colors.lightBlue,
    WeatherCondition.stormy: Colors.purple,
    WeatherCondition.foggy: Colors.blueGrey,
    WeatherCondition.windy: Colors.teal,
  };

  Future<void> initialize() async {
    await _loadSettings();
    await _updateCurrentWeather();
    
    // Her 30 dakikada bir hava durumunu güncelle
    Timer.periodic(const Duration(minutes: 30), (timer) {
      _updateCurrentWeather();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('weather_based_enabled') ?? false;
    
    final weatherAlarmsJson = prefs.getStringList('weather_alarms') ?? [];
    _weatherAlarms = weatherAlarmsJson
        .map((json) => WeatherBasedAlarm.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_based_enabled', _isEnabled);
    
    final weatherAlarmsJson = _weatherAlarms
        .map((alarm) => jsonEncode(alarm.toJson()))
        .toList();
    await prefs.setStringList('weather_alarms', weatherAlarmsJson);
  }

  Future<void> _updateCurrentWeather() async {
    // Simüle edilmiþ hava durumu güncellemesi
    await Future.delayed(const Duration(seconds: 1));
    
    final conditions = WeatherCondition.values;
    final randomCondition = conditions[DateTime.now().millisecond % conditions.length];
    
    _currentCondition = randomCondition;
    _currentWeather = _weatherDescriptions[randomCondition] ?? 'Bilinmeyen';
    
    debugPrint('=== WEATHER UPDATE ===');
    debugPrint('Condition: ${_weatherDescriptions[_currentCondition]}');
    debugPrint('======================');
  }

  Future<void> setWeatherBasedEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();
    
    debugPrint('Weather-based alarms ${enabled ? 'ENABLED' : 'DISABLED'}');
  }

  Future<void> setCustomAlarm(WeatherCondition condition, WeatherBasedAlarm alarm) async {
    final existingIndex = _weatherAlarms.indexWhere((a) => a.weatherCondition == condition.toString());
    
    if (existingIndex != -1) {
      _weatherAlarms[existingIndex] = alarm;
    } else {
      _weatherAlarms.add(alarm);
    }
    
    await _saveSettings();
    
    debugPrint('Custom alarm set for ${_weatherDescriptions[condition]}');
  }

  WeatherBasedAlarm? getCurrentAlarm() {
    if (!_isEnabled) return null;
    
    // Önce özel ayarlanmýþ alarmý ara
    final customAlarm = _weatherAlarms.where((a) => a.weatherCondition == _currentCondition.toString()).firstOrNull;
    if (customAlarm != null) return customAlarm;
    
    // Varsayýlan alarmý döndür
    return _defaultAlarms[_currentCondition];
  }

  Future<void> playWeatherBasedAlarm() async {
    final alarm = getCurrentAlarm();
    if (alarm == null) return;
    
    debugPrint('=== WEATHER-BASED ALARM ===');
    debugPrint('Weather: ${_weatherDescriptions[_currentCondition]}');
    debugPrint('Sound: ${alarm.soundFile}');
    debugPrint('Volume: ${(alarm.volume * 100).toInt()}%');
    debugPrint('Vibration: ${alarm.vibrationPattern}');
    debugPrint('Mood: ${alarm.mood}');
    debugPrint('==========================');
    
    // Gerçek uygulamada burada:
    // 1. Ses çal
    // 2. Titreþim yap
    // 3. Hava durumu bildirimi göster
  }

  List<String> getAvailableSounds(WeatherCondition condition) {
    return _weatherSounds[condition] ?? [];
  }

  String getWeatherDescription(WeatherCondition condition) {
    return _weatherDescriptions[condition] ?? 'Bilinmeyen';
  }

  Color getWeatherColor(WeatherCondition condition) {
    return _weatherColors[condition] ?? Colors.grey;
  }

  List<WeatherBasedAlarm> getCustomAlarms() {
    return List.from(_weatherAlarms);
  }

  Future<void> removeCustomAlarm(String weatherCondition) async {
    _weatherAlarms.removeWhere((alarm) => alarm.weatherCondition == weatherCondition);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    _weatherAlarms.clear();
    await _saveSettings();
    
    debugPrint('Weather-based alarms reset to defaults');
  }

  WeatherMood getRecommendedMood(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return WeatherMood.energetic;
      case WeatherCondition.cloudy:
        return WeatherMood.calm;
      case WeatherCondition.rainy:
        return WeatherMood.cozy;
      case WeatherCondition.snowy:
        return WeatherMood.relaxed;
      case WeatherCondition.stormy:
        return WeatherMood.focused;
      case WeatherCondition.foggy:
        return WeatherMood.calm;
      case WeatherCondition.windy:
        return WeatherMood.energetic;
    }
  }

  double getRecommendedVolume(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return 0.7;
      case WeatherCondition.cloudy:
        return 0.6;
      case WeatherCondition.rainy:
        return 0.5;
      case WeatherCondition.snowy:
        return 0.6;
      case WeatherCondition.stormy:
        return 0.8;
      case WeatherCondition.foggy:
        return 0.4;
      case WeatherCondition.windy:
        return 0.7;
    }
  }

  String getRecommendedVibration(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return 'standard';
      case WeatherCondition.cloudy:
        return 'pulse';
      case WeatherCondition.rainy:
        return 'gentle';
      case WeatherCondition.snowy:
        return 'heartbeat';
      case WeatherCondition.stormy:
        return 'strong';
      case WeatherCondition.foggy:
        return 'wave';
      case WeatherCondition.windy:
        return 'standard';
    }
  }

  Future<Map<String, dynamic>> getWeatherStatistics() async {
    // Simüle edilmi÷ istatistikler
    return {
      'totalWeatherAlarms': _weatherAlarms.length,
      'mostUsedCondition': 'clear',
      'averageVolume': 0.65,
      'enabledConditions': _weatherAlarms.map((a) => a.weatherCondition).toList(),
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> exportWeatherSettings() async {
    final settings = {
      'enabled': _isEnabled,
      'customAlarms': _weatherAlarms.map((a) => a.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
    
    debugPrint('Weather settings exported: ${settings.length} items');
  }

  Future<void> importWeatherSettings(Map<String, dynamic> settings) async {
    _isEnabled = settings['enabled'] ?? false;
    
    if (settings['customAlarms'] != null) {
      _weatherAlarms = (settings['customAlarms'] as List)
          .map((json) => WeatherBasedAlarm.fromJson(json))
          .toList();
    }
    
    await _saveSettings();
    
    debugPrint('Weather settings imported successfully');
  }
}
