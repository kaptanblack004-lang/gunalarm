import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalendarEventType {
  meeting,
  appointment,
  reminder,
  task,
  personal,
  work,
  travel,
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final CalendarEventType type;
  final bool isAllDay;
  final String? location;
  final List<String> attendees;
  final String? calendarId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isAllDay = false,
    this.location,
    this.attendees = const [],
    this.calendarId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.toString(),
      'isAllDay': isAllDay,
      'location': location,
      'attendees': attendees,
      'calendarId': calendarId,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: CalendarEventType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => CalendarEventType.personal,
      ),
      isAllDay: json['isAllDay'] ?? false,
      location: json['location'],
      attendees: List<String>.from(json['attendees'] ?? []),
      calendarId: json['calendarId'],
    );
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(startTime.year, startTime.month, startTime.day);
    return eventDay.isAtSameMomentAs(today);
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final eventDay = DateTime(startTime.year, startTime.month, startTime.day);
    return eventDay.isAtSameMomentAs(tomorrowDay);
  }

  String get timeRange {
    if (isAllDay) return 'Tüm Gün';
    
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    
    return '$start - $end';
  }
}

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  bool _isConnected = false;
  String? _accessToken;
  List<CalendarEvent> _events = [];
  List<String> _calendarIds = [];
  bool _autoAdjustAlarms = false;
  int _alarmAdjustmentMinutes = 30;

  bool get isConnected => _isConnected;
  String? get accessToken => _accessToken;
  List<CalendarEvent> get events => List.from(_events);
  bool get autoAdjustAlarms => _autoAdjustAlarms;
  int get alarmAdjustmentMinutes => _alarmAdjustmentMinutes;

  static const List<CalendarEvent> _mockEvents = [
    CalendarEvent(
      id: '1',
      title: 'Sabah Toplantýsý',
      description: 'Ekip toplantýsý ve proje deðerlendirmesi',
      startTime: DateTime(2024, 1, 15, 9, 0),
      endTime: DateTime(2024, 1, 15, 10, 0),
      type: CalendarEventType.meeting,
      location: 'Toplantý Odasý A',
    ),
    CalendarEvent(
      id: '2',
      title: 'Öðle Yemeði',
      description: 'Müþteri ile öðle yemeði',
      startTime: DateTime(2024, 1, 15, 12, 30),
      endTime: DateTime(2024, 1, 15, 14, 0),
      type: CalendarEventType.appointment,
      location: 'Italian Restaurant',
    ),
    CalendarEvent(
      id: '3',
      title: 'Proje Teslim Tarihi',
      description: 'Önemli proje teslim tarihi',
      startTime: DateTime(2024, 1, 16, 17, 0),
      endTime: DateTime(2024, 1, 16, 18, 0),
      type: CalendarEventType.task,
    ),
    CalendarEvent(
      id: '4',
      title: 'Spor Saati',
      description: 'Haftalýk spor rutini',
      startTime: DateTime(2024, 1, 15, 18, 30),
      endTime: DateTime(2024, 1, 15, 19, 30),
      type: CalendarEventType.personal,
      location: 'Spor Salonu',
    ),
    CalendarEvent(
      id: '5',
      title: 'Uçak Bileti',
      description: 'Ýstanbul - Ankara uçuþu',
      startTime: DateTime(2024, 1, 17, 8, 0),
      endTime: DateTime(2024, 1, 17, 12, 0),
      type: CalendarEventType.travel,
      location: 'Atatürk Havalimaný',
    ),
  ];

  Future<bool> connectToGoogleCalendar() async {
    try {
      // Simüle edilmiþ Google Calendar baðlantýsý
      await Future.delayed(const Duration(seconds: 2));
      
      _isConnected = true;
      _accessToken = 'mock_calendar_token_${DateTime.now().millisecondsSinceEpoch}';
      _calendarIds = ['primary', 'work', 'personal'];
      
      await _loadMockEvents();
      await _saveConnectionState();
      
      debugPrint('=== GOOGLE CALENDAR CONNECTED ===');
      debugPrint('Access Token: ${_accessToken?.substring(0, 20)}...');
      debugPrint('Calendars: ${_calendarIds.length}');
      debugPrint('Events: ${_events.length}');
      debugPrint('===============================');
      
      return true;
    } catch (e) {
      debugPrint('Google Calendar connection error: $e');
      return false;
    }
  }

  Future<void> disconnectFromGoogleCalendar() async {
    _isConnected = false;
    _accessToken = null;
    _events.clear();
    _calendarIds.clear();
    
    await _saveConnectionState();
    
    debugPrint('=== GOOGLE CALENDAR DISCONNECTED ===');
  }

  Future<void> _loadMockEvents() async {
    _events = List.from(_mockEvents);
    
    // Bugünkü ve yarýnkki etkinlikleri ekle
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Bugün için rastgele etkinlikler
    _events.addAll([
      CalendarEvent(
        id: 'today_1',
        title: 'Sabah Egzersizi',
        description: '30 dakika sabah egzersizi',
        startTime: DateTime(today.year, today.month, today.day, 7, 0),
        endTime: DateTime(today.year, today.month, today.day, 7, 30),
        type: CalendarEventType.personal,
      ),
      CalendarEvent(
        id: 'today_2',
        title: 'Kahvaltý Toplantýsý',
        description: 'Ekip kahvaltýsý',
        startTime: DateTime(today.year, today.month, today.day, 8, 30),
        endTime: DateTime(today.year, today.month, today.day, 9, 30),
        type: CalendarEventType.meeting,
        location: 'Company Café',
      ),
    ]);
    
    // Yarýn için rastgele etkinlikler
    _events.add(CalendarEvent(
      id: 'tomorrow_1',
      title: 'Yarýnkki Sunum',
      description: 'Önemli proje sunumu',
      startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
      endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 0),
      type: CalendarEventType.work,
      location: 'Konferans Salonu',
    ));
  }

  Future<void> _saveConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_connected', _isConnected);
    await prefs.setString('calendar_access_token', _accessToken ?? '');
    await prefs.setStringList('calendar_ids', _calendarIds);
    await prefs.setBool('auto_adjust_alarms', _autoAdjustAlarms);
    await prefs.setInt('alarm_adjustment_minutes', _alarmAdjustmentMinutes);
    
    final eventsJson = _events.map((event) => jsonEncode(event.toJson())).toList();
    await prefs.setStringList('calendar_events', eventsJson);
  }

  Future<void> _loadConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('calendar_connected') ?? false;
    _accessToken = prefs.getString('calendar_access_token');
    _calendarIds = prefs.getStringList('calendar_ids') ?? [];
    _autoAdjustAlarms = prefs.getBool('auto_adjust_alarms') ?? false;
    _alarmAdjustmentMinutes = prefs.getInt('alarm_adjustment_minutes') ?? 30;
    
    final eventsJson = prefs.getStringList('calendar_events') ?? [];
    _events = eventsJson
        .map((json) => CalendarEvent.fromJson(jsonDecode(json)))
        .toList();
    
    if (_isConnected && _events.isEmpty) {
      await _loadMockEvents();
    }
  }

  Future<List<CalendarEvent>> getTodayEvents() async {
    if (!_isConnected) return [];
    
    return _events.where((event) => event.isToday).toList();
  }

  Future<List<CalendarEvent>> getTomorrowEvents() async {
    if (!_isConnected) return [];
    
    return _events.where((event) => event.isTomorrow).toList();
  }

  Future<List<CalendarEvent>> getWeekEvents() async {
    if (!_isConnected) return [];
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return _events.where((event) =>
      event.startTime.isAfter(weekStart) && event.startTime.isBefore(weekEnd)
    ).toList();
  }

  Future<List<CalendarEvent>> getEventsByType(CalendarEventType type) async {
    if (!_isConnected) return [];
    
    return _events.where((event) => event.type == type).toList();
  }

  Future<CalendarEvent?> getNextEvent() async {
    if (!_isConnected) return null;
    
    final now = DateTime.now();
    final upcomingEvents = _events.where((event) => event.startTime.isAfter(now)).toList();
    
    if (upcomingEvents.isEmpty) return null;
    
    upcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcomingEvents.first;
  }

  Future<TimeOfDay?> getRecommendedWakeUpTime() async {
    if (!_isConnected) return null;
    
    final todayEvents = await getTodayEvents();
    if (todayEvents.isEmpty) return null;
    
    // Bugünkü ilk etkinliði bul
    final firstEvent = todayEvents.reduce((a, b) => 
        a.startTime.isBefore(b.startTime) ? a : b
    );
    
    // Etkinlikten _alarmAdjustmentMinutes önce uyanma önerisi
    final wakeUpTime = firstEvent.startTime.subtract(
      Duration(minutes: _alarmAdjustmentMinutes)
    );
    
    return TimeOfDay(hour: wakeUpTime.hour, minute: wakeUpTime.minute);
  }

  Future<List<String>> getCalendarRecommendations() async {
    final recommendations = <String>[];
    
    if (!_isConnected) {
      recommendations.add('Google Calendar baðlantýsý kurun ki etkinliklerinizi görebilim.');
      return recommendations;
    }
    
    final todayEvents = await getTodayEvents();
    final tomorrowEvents = await getTomorrowEvents();
    
    if (todayEvents.isNotEmpty) {
      recommendations.add('Bugün ${todayEvents.length} etkinliðiniz var. Erken uyanmayý düþünün.');
      
      final firstEvent = todayEvents.reduce((a, b) => 
          a.startTime.isBefore(b.startTime) ? a : b
      );
      
      recommendations.add('Ýlk etkinliðiniz: "${firstEvent.title}" saat ${firstEvent.timeRange}');
    }
    
    if (tomorrowEvents.isNotEmpty) {
      recommendations.add('Yarýn ${tomorrowEvents.length} etkinliðiniz var.');
      
      final importantEvents = tomorrowEvents.where((event) => 
        event.type == CalendarEventType.meeting || event.type == CalendarEventType.appointment
      ).toList();
      
      if (importantEvents.isNotEmpty) {
        recommendations.add('Yarýn ${importantEvents.length} önemli etkinliðiniz var.');
      }
    }
    
    final weekEvents = await getWeekEvents();
    if (weekEvents.length > 10) {
      recommendations.add('Bu hafta çok yoðun. Dinlenmeye zaman ayýrýn.');
    }
    
    final workEvents = await getEventsByType(CalendarEventType.work);
    if (workEvents.length > 5) {
      recommendations.add('Bu hafta çok iþ etkinliðiniz var. Çalýþma-yaþam dengesine dikkat edin.');
    }
    
    return recommendations;
  }

  Future<void> setAutoAdjustAlarms(bool enabled) async {
    _autoAdjustAlarms = enabled;
    await _saveConnectionState();
    
    debugPrint('Auto-adjust alarms ${enabled ? 'ENABLED' : 'DISABLED'}');
  }

  Future<void> setAlarmAdjustmentMinutes(int minutes) async {
    _alarmAdjustmentMinutes = minutes;
    await _saveConnectionState();
    
    debugPrint('Alarm adjustment set to $minutes minutes');
  }

  Future<void> createEvent(CalendarEvent event) async {
    if (!_isConnected) return;
    
    _events.add(event);
    await _saveConnectionState();
    
    debugPrint('Created event: ${event.title}');
  }

  Future<void> updateEvent(CalendarEvent event) async {
    if (!_isConnected) return;
    
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      await _saveConnectionState();
      
      debugPrint('Updated event: ${event.title}');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    if (!_isConnected) return;
    
    _events.removeWhere((event) => event.id == eventId);
    await _saveConnectionState();
    
    debugPrint('Deleted event: $eventId');
  }

  Future<void> syncCalendar() async {
    if (!_isConnected) return;
    
    debugPrint('=== SYNCING CALENDAR ===');
    await Future.delayed(const Duration(seconds: 2));
    
    // Simüle edilmiþ senkronizasyon
    await _loadMockEvents();
    
    debugPrint('Calendar synced: ${_events.length} events');
    debugPrint('======================');
  }

  Future<void> initialize() async {
    await _loadConnectionState();
    
    if (_isConnected) {
      debugPrint('Google Calendar already connected');
      await syncCalendar();
    } else {
      debugPrint('Google Calendar not connected');
    }
  }

  // Premium özellikler
  Future<List<CalendarEvent>> getConflictingEvents(DateTime startTime, DateTime endTime) async {
    if (!_isConnected) return [];
    
    return _events.where((event) =>
      (event.startTime.isBefore(endTime) && event.endTime.isAfter(startTime)) ||
      (event.startTime.isAfter(startTime) && event.startTime.isBefore(endTime)) ||
      (event.endTime.isAfter(startTime) && event.endTime.isBefore(endTime))
    ).toList();
  }

  Future<void> setAlarmForEvent(String eventId, TimeOfDay alarmTime) async {
    if (!_isConnected) return;
    
    final event = _events.firstWhere((e) => e.id == eventId);
    
    debugPrint('=== ALARM SET FOR EVENT ===');
    debugPrint('Event: ${event.title}');
    debugPrint('Event Time: ${event.timeRange}');
    debugPrint('Alarm Time: ${alarmTime.hour}:${alarmTime.minute}');
    debugPrint('==========================');
    
    // Gerçek uygulamada burada alarm oluþturulur
  }

  Future<Map<String, dynamic>> getCalendarStatistics() async {
    if (!_isConnected) return {};
    
    final weekEvents = await getWeekEvents();
    final workEvents = weekEvents.where((e) => e.type == CalendarEventType.work).toList();
    final personalEvents = weekEvents.where((e) => e.type == CalendarEventType.personal).toList();
    
    return {
      'totalEvents': weekEvents.length,
      'workEvents': workEvents.length,
      'personalEvents': personalEvents.length,
      'todayEvents': (await getTodayEvents()).length,
      'tomorrowEvents': (await getTomorrowEvents()).length,
      'averageDailyEvents': (weekEvents.length / 7).toStringAsFixed(1),
      'connectedCalendars': _calendarIds.length,
      'lastSync': DateTime.now().toIso8601String(),
    };
  }
}
