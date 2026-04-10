import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { turkish, english }

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Language _currentLanguage = Language.turkish;
  Language get currentLanguage => _currentLanguage;

  static const Map<String, String> _tr = {
    'app_title': 'GünAlarm',
    'app_subtitle': 'Mükemmel Gün için Mükemmel Alarm',
    'alarms': 'Alarmlar',
    'no_alarms': 'Henüz alarm eklenmedi',
    'add_alarm': 'Alarm Ekle',
    'settings': 'Ayarlar',
    'location': 'Konum',
    'current_location': 'Mevcut Konum',
    'city_search': 'Þehir Ara',
    'city_placeholder': 'Þehir adi yazin...',
    'city_not_found': 'Þehir bulunamadi',
    'use_location': 'Kullan',
    'gps_automatic': 'GPS ile otomatik konum',
    'select_city': 'Þehir Seçin',
    'city_selected': 'Seçildi',
    'weather_details': 'Hava Durumu Detaylari',
    'humidity': 'Nem',
    'wind': 'Rüzgar',
    'feels_like': 'Hissedilen',
    'pressure': 'Basinç',
    'forecast_5days': '5 Günlük Tahmin',
    'forecast_not_found': 'Tahmin verisi bulunamadi',
    'alarm_label': 'Alarm Etiketi',
    'alarm_label_placeholder': 'Örn: Uyanma zamani',
    'repeat': 'Tekrarla',
    'repeat_days': 'Tekrar Günleri',
    'everyday': 'Her gün',
    'weekdays': 'Hafta içi',
    'custom': 'Özel',
    'monday': 'Pazartesi',
    'tuesday': 'Sali',
    'wednesday': 'Çarþamba',
    'thursday': 'Perþembe',
    'friday': 'Cuma',
    'saturday': 'Cumartesi',
    'sunday': 'Pazar',
    'save': 'Kaydet',
    'cancel': 'Ýptal',
    'delete': 'Sil',
    'enable': 'Etkinleþtir',
    'disable': 'Devre dýþi býrak',
    'permission_required': 'Ýzin Gerekli',
    'notification_permission': 'Bildirim Ýzni',
    'notification_permission_desc': 'Alarm bildirimleri için bildirim izni gereklidir.',
    'location_permission': 'Konum Ýzni',
    'location_permission_desc': 'Konum bazli hava durumu için konum izni gereklidir.',
    'grant': 'Ýzin Ver',
    'skip': 'Atla',
    'loading': 'Yükleniyor...',
    'connecting': 'Baðlaniyor...',
    'error_connection': 'Baðlanti hatasi',
    'error_location': 'Konum alinamadi',
    'error_weather': 'Hava durumu alinamadi',
    'getting_location': 'Konum aliniyor...',
    'getting_weather': 'Hava durumu aliniyor...',
    'plate_code': 'Plaka',
    'onboarding_title_1': 'Akilli Alarm Sistemi',
    'onboarding_desc_1': 'Çoklu alarm, tekrar seçenekleri ve kolay yönetim ile mükemmel alarm deneyimi.',
    'onboarding_title_2': 'Hava Durumu Bilgisi',
    'onboarding_desc_2': 'Konum bazli hava durumu, 5 günlük tahmin ve detayli meteorolojik veriler.',
    'onboarding_title_3': 'Kiþiselleþtirilebilir Deneyim',
    'onboarding_desc_3': 'Karanlik/açik tema, çoklu dil desteði ve modern arayüz.',
    'previous': 'Önceki',
    'next': 'Sonraki',
    'get_started': 'Basla',
  };

  static const Map<String, String> _en = {
    'app_title': 'DayAlarm',
    'app_subtitle': 'Perfect Alarm for Perfect Day',
    'alarms': 'Alarms',
    'no_alarms': 'No alarms added yet',
    'add_alarm': 'Add Alarm',
    'settings': 'Settings',
    'location': 'Location',
    'current_location': 'Current Location',
    'city_search': 'City Search',
    'city_placeholder': 'Enter city name...',
    'city_not_found': 'City not found',
    'use_location': 'Use',
    'gps_automatic': 'GPS automatic location',
    'select_city': 'Select City',
    'city_selected': 'Selected',
    'weather_details': 'Weather Details',
    'humidity': 'Humidity',
    'wind': 'Wind',
    'feels_like': 'Feels Like',
    'pressure': 'Pressure',
    'forecast_5days': '5-Day Forecast',
    'forecast_not_found': 'Forecast data not found',
    'alarm_label': 'Alarm Label',
    'alarm_label_placeholder': 'e.g., Wake up time',
    'repeat': 'Repeat',
    'repeat_days': 'Repeat Days',
    'everyday': 'Everyday',
    'weekdays': 'Weekdays',
    'custom': 'Custom',
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'enable': 'Enable',
    'disable': 'Disable',
    'permission_required': 'Permission Required',
    'notification_permission': 'Notification Permission',
    'notification_permission_desc': 'Notification permission required for alarm notifications.',
    'location_permission': 'Location Permission',
    'location_permission_desc': 'Location permission required for location-based weather.',
    'grant': 'Grant',
    'skip': 'Skip',
    'loading': 'Loading...',
    'connecting': 'Connecting...',
    'error_connection': 'Connection error',
    'error_location': 'Location unavailable',
    'error_weather': 'Weather unavailable',
    'getting_location': 'Getting location...',
    'getting_weather': 'Getting weather...',
    'plate_code': 'Plate',
    'onboarding_title_1': 'Smart Alarm System',
    'onboarding_desc_1': 'Multiple alarms, repeat options and easy management for perfect alarm experience.',
    'onboarding_title_2': 'Weather Information',
    'onboarding_desc_2': 'Location-based weather, 5-day forecast and detailed meteorological data.',
    'onboarding_title_3': 'Customizable Experience',
    'onboarding_desc_3': 'Dark/light theme, multi-language support and modern interface.',
    'previous': 'Previous',
    'next': 'Next',
    'get_started': 'Get Started',
  };

  Map<String, String> get _translations => _currentLanguage == Language.turkish ? _tr : _en;

  String translate(String key) {
    return _translations[key] ?? key;
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'tr';
    _currentLanguage = langCode == 'en' ? Language.english : Language.turkish;
    notifyListeners();
  }

  Future<void> setLanguage(Language language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language == Language.english ? 'en' : 'tr');
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    await setLanguage(_currentLanguage == Language.turkish ? Language.english : Language.turkish);
  }
}
