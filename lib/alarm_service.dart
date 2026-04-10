import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Timer? _alarmTimer;

  Future<void> initialize() async {
    debugPrint('AlarmService initialized');
    _startAlarmChecker();
  }

  void _startAlarmChecker() {
    _alarmTimer?.cancel();
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  Future<void> _checkAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    
    for (final alarmJson in alarmsJson) {
      try {
        // Basit parse - gerçek uygulamada dart:convert kullanýlmalý
        debugPrint('Checking alarm: ${alarmJson.substring(0, 50)}...');
        
        // Simülasyon - her alarm için kontrol
        _simulateAlarmCheck();
      } catch (e) {
        debugPrint('Error checking alarm: $e');
      }
    }
  }

  void _simulateAlarmCheck() {
    final now = DateTime.now();
    debugPrint('Checking alarms at: ${now.hour}:${now.minute}:${now.second}');
    
    // Simülasyon - rastgele alarm tetikleme
    if (now.second == 0) {
      debugPrint('ALARM CHECK COMPLETE - No alarms ringing');
    }
  }

  DateTime? _getAlarmDateTime(Map<String, dynamic> alarmData) {
    final hour = alarmData['hour'] as int?;
    final minute = alarmData['minute'] as int?;
    final dateStr = alarmData['date'] as String?;
    
    if (hour == null || minute == null) return null;
    
    final now = DateTime.now();
    
    // Belirli bir tarih varsa
    if (dateStr != null) {
      final date = DateTime.parse(dateStr);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    
    // Tekrarlayan alarm
    if (alarmData['repeat'] == true) {
      final selectedDays = List<bool>.from(alarmData['selectedDays'] ?? []);
      final todayIndex = now.weekday % 7; // Pazartesi = 1
      
      if (selectedDays.isNotEmpty && selectedDays[todayIndex]) {
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    }
    
    return null;
  }

  bool _shouldAlarmRing(DateTime alarmTime, Map<String, dynamic> alarmData) {
    final now = DateTime.now();
    final isEnabled = alarmData['isEnabled'] ?? true;
    
    if (!isEnabled) return false;
    
    // Belirli tarihli alarm için
    if (alarmData['date'] != null) {
      final alarmDate = DateTime.parse(alarmData['date']);
      final today = DateTime(now.year, now.month, now.day);
      final alarmDay = DateTime(alarmDate.year, alarmDate.month, alarmDate.day);
      
      if (today.isAtSameMomentAs(alarmDay)) {
        final alarmDateTime = DateTime(alarmDate.year, alarmDate.month, alarmDate.day, alarmTime.hour, alarmTime.minute);
        final difference = now.difference(alarmDateTime);
        
        // Alarm zamaný geldi ve 1 dakikadan az geçti
        return difference.inSeconds >= 0 && difference.inSeconds < 60;
      }
    }
    
    return false;
  }

  void _triggerAlarm(Map<String, dynamic> alarmData) async {
    final label = alarmData['label'] ?? 'Alarm';
    debugPrint('ALARM RINGING: $label');
    
    // Ses seviyesi ve titreþim ayarlarýný al
    final soundService = SoundService();
    final volume = await soundService.getVolume();
    final vibrationEnabled = await soundService.getVibrationEnabled();
    
    // Kademeli ses artýþý
    await _playWithGradualVolume(volume, vibrationEnabled);
    
    // Gerçek uygulamada burada:
    // 1. Bildirim gönder
    // 2. Ses çal (kademeli)
    // 3. Titreþim (pattern)
    // 4. Alarm UI göster
    
    // Alarmý devre dýþý býrak (isteðe baðlý)
    _disableAlarm(alarmData['id']);
  }

  Future<void> _playWithGradualVolume(double targetVolume, bool vibration) async {
    debugPrint('=== GRADUAL ALARM START ===');
    debugPrint('Target Volume: ${(targetVolume * 100).toInt()}%');
    debugPrint('Vibration: ${vibration ? "ON" : "OFF"}');
    
    // 10 saniye boyunca kademeli artýþ
    for (int i = 1; i <= 10; i++) {
      final currentVolume = (targetVolume * i) / 10;
      debugPrint('Volume step $i/10: ${(currentVolume * 100).toInt()}%');
      
      // Titreþim pattern'i
      if (vibration && i % 3 == 0) {
        debugPrint('Vibration pattern: SHORT-LONG-SHORT');
      }
      
      await Future.delayed(const Duration(seconds: 1));
    }
    
    debugPrint('=== GRADUAL ALARM COMPLETE ===');
  }

  Future<void> _disableAlarm(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    
    final updatedAlarms = alarmsJson.map((json) {
      // Basit string manipulation - gerçek uygulamada dart:convert kullanýlmalý
      if (json.contains('"id":"$alarmId"')) {
        return json.replaceFirst('"isEnabled":true', '"isEnabled":false');
      }
      return json;
    }).toList();
    
    await prefs.setStringList('alarms', updatedAlarms);
  }

  Future<void> scheduleAlarm({
    required TimeOfDay time,
    required String label,
    required bool repeat,
    List<int> days = const [],
    DateTime? date,
  }) async {
    await _saveAlarmToPrefs(time, label, repeat, days, date);
    debugPrint('Alarm scheduled: $label at ${time.hour}:${time.minute}');
  }

  Future<void> _saveAlarmToPrefs(
    TimeOfDay time,
    String label,
    bool repeat,
    List<int> days,
    DateTime? date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    
    final alarmId = DateTime.now().millisecondsSinceEpoch.toString();
    final alarmJson = '''
    {
      "id": "$alarmId",
      "hour": ${time.hour},
      "minute": ${time.minute},
      "label": "$label",
      "isEnabled": true,
      "repeat": $repeat,
      "selectedDays": [${days.map((d) => 'true').join(',')}],
      "date": ${date?.toIso8601String() ?? 'null'}
    }
    ''';
    
    alarmsJson.add(alarmJson);
    await prefs.setStringList('alarms', alarmsJson);
  }

  void dispose() {
    _alarmTimer?.cancel();
  }

  Future<void> cancelAlarm(int id) async {
    // SharedPreferences'ten sil
    final prefs = await SharedPreferences.getInstance();
    final alarms = prefs.getStringList('alarms') ?? [];
    if (id < alarms.length) {
      alarms.removeAt(id);
      await prefs.setStringList('alarms', alarms);
    }
    
    debugPrint('Alarm cancelled: $id');
  }

  Future<void> playAlarmSound() async {
    debugPrint('Alarm sound playing - placeholder');
    // Gerçek ses çalma placeholder
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> stopAlarmSound() async {
    debugPrint('Alarm sound stopped');
  }

  Future<List<Map<String, dynamic>>> getSavedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = prefs.getStringList('alarms') ?? [];
    
    return alarms.map((alarm) {
      final parts = alarm.substring(1, alarm.length - 1).split(',');
      final Map<String, dynamic> alarmMap = {};
      for (final part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          alarmMap[keyValue[0].trim()] = keyValue[1].trim();
        }
      }
      return alarmMap;
    }).toList();
  }
}
