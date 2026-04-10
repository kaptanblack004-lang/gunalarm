import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'language_service.dart';
import 'alarm_service.dart';
import 'sound_service.dart';
import 'sound_settings_screen.dart';
import 'city_data.dart';
import 'permission_service.dart';
import 'theme_service.dart';
import 'language_service.dart';
import 'onboarding_screen.dart';
import 'swipe_actions_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Alarm servisini başlat
  await AlarmService().initialize();
  
  runApp(const GunAlarmApp());
}

class GunAlarmApp extends StatefulWidget {
  const GunAlarmApp({super.key});

  @override
  State<GunAlarmApp> createState() => _GunAlarmAppState();
}

class _GunAlarmAppState extends State<GunAlarmApp> {
  final ThemeService _themeService = ThemeService();
  final LanguageService _languageService = LanguageService();
  bool _onboardingCompleted = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _themeService.loadSettings();
    await _languageService.loadLanguage();
    await _checkOnboardingStatus();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _onboardingCompleted = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        title: 'GünAlarm',
        theme: _themeService.currentTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'GünAlarm',
          theme: _themeService.currentTheme,
          home: _onboardingCompleted ? const SplashScreen() : const OnboardingScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _scaleController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Glow animasyonu
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Fade animasyonu
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Particle animasyonu
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Scale animasyonu
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Text fade animasyonu
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Animasyonlarý baþlat
    _fadeController.forward();
    _scaleController.forward();
    
    // 3 saniye sonra ana ekrana geç
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return const PermissionScreen();
            },
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Arka plan gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),
          
          // Parçacik efektleri
          ...List.generate(20, (index) {
            final random = (index * 137.5) % 1.0;
            final size = 2.0 + (index % 3) * 2.0;
            final x = (random * MediaQuery.of(context).size.width);
            final y = (random * MediaQuery.of(context).size.height);
            
            return AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                final progress = (_particleAnimation.value + random) % 1.0;
                final newY = y - (progress * MediaQuery.of(context).size.height);
                
                return Positioned(
                  left: x,
                  top: newY < 0 ? newY + MediaQuery.of(context).size.height : newY,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3 * (1 - progress)),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),

          // Ana içerik
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ve glow efekti
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(_glowAnimation.value * 0.8),
                            blurRadius: 30 * _glowAnimation.value,
                            spreadRadius: 5 * _glowAnimation.value,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(_glowAnimation.value * 0.3),
                            blurRadius: 20 * _glowAnimation.value,
                            spreadRadius: 3 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.alarm,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Uygulama adý
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: const Text(
                    'GünAlarm',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Alt yazý
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: const Text(
                    'Mükemmel Gün için Mükemmel Alarm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Yüklenme animasyonu
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// İzin Ekranı
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'İzinler Gerekli',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GünAlarm uygulaması için aşağıdaki izinler gereklidir:\n\n'
                '• Bildirimler: Alarm bildirimleri için\n'
                '• Konum: Hava durumu bilgisi için',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.orange)
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          await PermissionService.requestAllPermissions();
                          setState(() => _isLoading = false);
                          
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const MainScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'İzin Ver',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const MainScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Atla',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Alarm Modeli
class Alarm {
  final String id;
  final TimeOfDay time;
  final String label;
  final bool isEnabled;
  final bool repeat;
  final List<bool> selectedDays;
  final DateTime? date;

  Alarm({
    required this.id,
    required this.time,
    required this.label,
    required this.isEnabled,
    required this.repeat,
    required this.selectedDays,
    this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeat': repeat,
      'selectedDays': selectedDays,
      'date': date?.toIso8601String(),
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      label: json['label'],
      isEnabled: json['isEnabled'] ?? true,
      repeat: json['repeat'] ?? false,
      selectedDays: List<bool>.from(json['selectedDays'] ?? [false, false, false, false, false, false, false]),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }
}

// Ana Ekran
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Alarm> _alarms = [];
  String _weatherTemp = "--°C";
  String _weatherDesc = "Þehir girin";
  String _location = "Konumunuz";
  String _humidity = "--%";
  String _windSpeed = "-- km/sa";
  String _feelsLike = "--°C";
  String _pressure = "-- hPa";
  List<Map<String, dynamic>> _forecast = [];
  bool _isLoadingWeather = false;
  bool _isLoadingForecast = false;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  final ThemeService _themeService = ThemeService();
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
    _fetchWeather(_location);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    
    setState(() {
      _alarms = alarmsJson
          .map((json) => Alarm.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  Future<void> _fetchWeather(String city) async {
    if (city == 'Konumunuz' || city.isEmpty) {
      setState(() {
        _weatherTemp = "--°C";
        _weatherDesc = "Konum aliniyor...";
        _humidity = "--%";
        _windSpeed = "-- km/sa";
        _feelsLike = "--°C";
        _pressure = "-- hPa";
      });
      
      // Konum bazli hava durumu
      await _fetchWeatherByLocation();
      return;
    }
    
    setState(() => _isLoadingWeather = true);
    setState(() => _isLoadingForecast = true);
    
    const apiKey = 'd9a6c79645ffa3306c804d938e7c5b7e';
    
    // Mevcut hava durumu
    final weatherUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=tr',
    );
    
    // 5 günlük tahmin
    final forecastUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric&lang=tr',
    );
    
    try {
      final responses = await Future.wait([
        http.get(weatherUrl),
        http.get(forecastUrl),
      ]);
      
      final weatherResponse = responses[0];
      final forecastResponse = responses[1];
      
      if (weatherResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(weatherResponse.bodyBytes));
        if (!mounted) return;
        setState(() {
          _weatherTemp = "${data['main']['temp'].round()}°C";
          _weatherDesc = data['weather'][0]['description'];
          _humidity = "${data['main']['humidity']}%";
          _windSpeed = "${(data['wind']['speed'] * 3.6).round()} km/sa";
          _feelsLike = "${data['main']['feels_like'].round()}°C";
          _pressure = "${data['main']['pressure']} hPa";
          _location = city;
          _isLoadingWeather = false;
        });
      }
      
      if (forecastResponse.statusCode == 200) {
        final forecastData = jsonDecode(utf8.decode(forecastResponse.bodyBytes));
        if (!mounted) return;
        setState(() {
          _forecast = _parseForecastData(forecastData);
          _isLoadingForecast = false;
        });
      }
      
      if (weatherResponse.statusCode != 200 || forecastResponse.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _weatherTemp = "--°C";
          _weatherDesc = "Þehir bulunamadi";
          _humidity = "--%";
          _windSpeed = "-- km/sa";
          _feelsLike = "--°C";
          _pressure = "-- hPa";
          _forecast = [];
          _isLoadingWeather = false;
          _isLoadingForecast = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherTemp = "--°C";
        _weatherDesc = "Baglanti hatasi";
        _humidity = "--%";
        _windSpeed = "-- km/sa";
        _feelsLike = "--°C";
        _pressure = "-- hPa";
        _forecast = [];
        _isLoadingWeather = false;
        _isLoadingForecast = false;
      });
    }
  }

  Future<void> _fetchWeatherByLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (position == null) {
        setState(() {
          _weatherTemp = "--°C";
          _weatherDesc = "Konum alinamadi";
          _humidity = "--%";
          _windSpeed = "-- km/sa";
          _feelsLike = "--°C";
          _pressure = "-- hPa";
          _forecast = [];
        });
        return;
      }

      const apiKey = 'd9a6c79645ffa3306c804d938e7c5b7e';
      
      // Mevcut hava durumu
      final weatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=tr',
      );

      // 5 günlük tahmin
      final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=tr',
      );

      final responses = await Future.wait([
        http.get(weatherUrl),
        http.get(forecastUrl),
      ]);
      
      final weatherResponse = responses[0];
      final forecastResponse = responses[1];

      if (weatherResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(weatherResponse.bodyBytes));
        if (!mounted) return;
        setState(() {
          _weatherTemp = "${data['main']['temp'].round()}°C";
          _weatherDesc = data['weather'][0]['description'];
          _humidity = "${data['main']['humidity']}%";
          _windSpeed = "${(data['wind']['speed'] * 3.6).round()} km/sa";
          _feelsLike = "${data['main']['feels_like'].round()}°C";
          _pressure = "${data['main']['pressure']} hPa";
          _location = data['name'] ?? 'Mevcut Konum';
          _isLoadingWeather = false;
        });
      }

      if (forecastResponse.statusCode == 200) {
        final forecastData = jsonDecode(utf8.decode(forecastResponse.bodyBytes));
        if (!mounted) return;
        setState(() {
          _forecast = _parseForecastData(forecastData);
          _isLoadingForecast = false;
        });
      }

      if (weatherResponse.statusCode != 200 || forecastResponse.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _weatherTemp = "--°C";
          _weatherDesc = "Konum hava durumu alinamadi";
          _humidity = "--%";
          _windSpeed = "-- km/sa";
          _feelsLike = "--°C";
          _pressure = "-- hPa";
          _forecast = [];
          _isLoadingWeather = false;
          _isLoadingForecast = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherTemp = "--°C";
        _weatherDesc = "Konum hatasi";
        _humidity = "--%";
        _windSpeed = "-- km/sa";
        _feelsLike = "--°C";
        _pressure = "-- hPa";
        _forecast = [];
        _isLoadingWeather = false;
        _isLoadingForecast = false;
      });
    }
  }

  Future<void> _addAlarm() async {
    final result = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(builder: (_) => const AlarmEditScreen()),
    );
    
    if (result != null) {
      setState(() {
        _alarms.add(result);
      });
      await _saveAlarms();
      
      // Alarmı planla
      await AlarmService().scheduleAlarm(
        time: result.time,
        label: result.label,
        repeat: result.repeat,
        days: result.selectedDays.asMap().entries.where((e) => e.value).map((e) => e.key).toList(),
      );
    }
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    final updatedAlarm = Alarm(
      id: alarm.id,
      time: alarm.time,
      label: alarm.label,
      repeat: alarm.repeat,
      selectedDays: alarm.selectedDays,
      isEnabled: !alarm.isEnabled,
    );
    
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    _alarms[index] = updatedAlarm;
    
    setState(() {});
    await _saveAlarms();
    
    if (updatedAlarm.isEnabled) {
      await AlarmService().scheduleAlarm(
        time: updatedAlarm.time,
        label: updatedAlarm.label,
        repeat: updatedAlarm.repeat,
        days: updatedAlarm.selectedDays.asMap().entries.where((e) => e.value).map((e) => e.key).toList(),
      );
    } else {
      await AlarmService().cancelAlarm(int.parse(alarm.id));
    }
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    setState(() {
      _alarms.removeWhere((a) => a.id == alarm.id);
    });
    await _saveAlarms();
    await AlarmService().cancelAlarm(int.parse(alarm.id));
  }

  Future<void> _snoozeAlarm(Alarm alarm) async {
    // 5 dakika ertele
    final now = DateTime.now();
    final snoozeTime = now.add(const Duration(minutes: 5));
    
    final snoozedAlarm = Alarm(
      id: '${alarm.id}_snooze',
      time: TimeOfDay(hour: snoozeTime.hour, minute: snoozeTime.minute),
      label: '${alarm.label} (Erteleme)',
      isEnabled: true,
      repeat: false,
      selectedDays: [false, false, false, false, false, false, false],
      date: snoozeTime,
    );
    
    setState(() {
      _alarms.add(snoozedAlarm);
    });
    await _saveAlarms();
    
    // Orijinal alarmi kapat
    final updatedAlarm = Alarm(
      id: alarm.id,
      time: alarm.time,
      label: alarm.label,
      isEnabled: false,
      repeat: alarm.repeat,
      selectedDays: alarm.selectedDays,
      date: alarm.date,
    );
    
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
    }
    
    setState(() {});
    await _saveAlarms();
    
    // Bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alarm 5 dakika ertelendi!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  List<Map<String, dynamic>> _parseForecastData(Map<String, dynamic> data) {
    final List<dynamic> list = data['list'];
    
    // Her gün için bir tahmin al (12:00'deki veriler)
    final Map<String, Map<String, dynamic>> dailyData = {};
    
    for (var item in list) {
      final dateTime = DateTime.parse(item['dt_txt']);
      final dateKey = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
      
      // O günün 12:00 verisini al veya ilk veriyi kullan
      if (!dailyData.containsKey(dateKey) || dateTime.hour == 12) {
        dailyData[dateKey] = {
          'date': dateTime,
          'temp': item['main']['temp'].round(),
          'description': item['weather'][0]['description'],
          'icon': item['weather'][0]['icon'],
          'humidity': item['main']['humidity'],
          'windSpeed': (item['wind']['speed'] * 3.6).round(),
          'feelsLike': item['main']['feels_like'].round(),
        };
      }
    }
    
    // Sadece 5 gün al
    final sortedDates = dailyData.keys.toList()..sort();
    return sortedDates.take(5).map((date) => dailyData[date]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMorning = _now.hour >= 5 && _now.hour < 12;
    final isEvening = _now.hour >= 18 || _now.hour < 5;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'GünAlarm',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Dil toggle butonu
          IconButton(
            onPressed: () {
              _languageService.toggleLanguage();
            },
            icon: Icon(
              _languageService.currentLanguage == Language.turkish 
                  ? Icons.language 
                  : Icons.translate,
              color: Colors.white,
            ),
          ),
          // Tema toggle butonu
          IconButton(
            onPressed: () {
              _themeService.toggleTheme();
            },
            icon: Icon(
              _themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(currentCity: _location)),
              );
              if (result != null) {
                setState(() {
                  _location = result;
                });
                await _fetchWeather(result);
              }
            },
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SoundSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.volume_up, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _themeService.gradientBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _location,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_now.day}/${_now.month}/${_now.year}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Saat
                Text(
                  "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 24),

                // Hava Durumu
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wb_cloudy, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _weatherTemp,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _weatherDesc,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          if (_isLoadingWeather)
                            const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Detayli hava durumu bilgileri
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.blue, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                _humidity,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Nem',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.air, color: Colors.cyan, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                _windSpeed,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Rüzgar',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.thermostat, color: Colors.orange, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                _feelsLike,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Hissedilen',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.compress, color: Colors.purple, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                _pressure,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Basinç',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5 Günlük Tahmin
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '5 Günlük Tahmin',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_isLoadingForecast)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_forecast.isEmpty && !_isLoadingForecast)
                        const Center(
                          child: Text(
                            'Tahmin verisi bulunamadi',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      else
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _forecast.length,
                            itemBuilder: (context, index) {
                              final day = _forecast[index];
                              final date = day['date'] as DateTime;
                              final dayName = _getDayName(date.weekday);
                              
                              return Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${day['temp']}°',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      day['description'],
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.white54,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Alarm Bölümü
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alarmlar',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            onPressed: _addAlarm,
                            icon: const Icon(Icons.add, color: Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_alarms.isEmpty)
                        const Center(
                          child: Text(
                            'Henüz alarm eklenmemiş',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      else
                        ..._alarms.map((alarm) => SwipeActionTile(
                          onDelete: () => _deleteAlarm(alarm),
                          onSnooze: () => _snoozeAlarm(alarm),
                          child: AlarmTile(
                            alarm: alarm,
                            onToggle: () => _toggleAlarm(alarm),
                            onDelete: () => _deleteAlarm(alarm),
                            onSnooze: () => _snoozeAlarm(alarm),
                          ),
                        )),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alarm Tile Widget
class AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSnooze;

  const AlarmTile({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    required this.onSnooze,
  });

  String _getRepeatText() {
    if (!alarm.repeat) return 'Tek seferlik';
    return alarm.selectedDays.asMap().entries
        .where((entry) => entry.value)
        .map((entry) => ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][entry.key])
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(alarm.isEnabled ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: alarm.isEnabled ? Colors.white : Colors.white54,
                ),
              ),
              Text(
                alarm.label,
                style: TextStyle(
                  fontSize: 14,
                  color: alarm.isEnabled ? Colors.white70 : Colors.white38,
                ),
              ),
              Text(
                _getRepeatText(),
                style: TextStyle(
                  fontSize: 12,
                  color: alarm.isEnabled ? Colors.white54 : Colors.white24,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              // Snooze butonu
              if (alarm.isEnabled)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: onSnooze,
                    icon: const Icon(Icons.snooze, color: Colors.blue, size: 20),
                    tooltip: '5 dakika ertele',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Switch
              Switch(
                value: alarm.isEnabled,
                onChanged: (_) => onToggle(),
                activeColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

// Ayarlar Ekraný
class SettingsScreen extends StatefulWidget {
  final String currentCity;
  const SettingsScreen({super.key, required this.currentCity});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _cityController = TextEditingController();
  String? _selectedCity;
  String? _selectedDistrict;
  List<Map<String, String>> _filteredCities = CityData.turkishCities;
  List<String> _filteredDistricts = [];

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.currentCity;
    _selectedCity = widget.currentCity;
    _filteredDistricts = CityData.getDistricts(_selectedCity!);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    setState(() {
      _filteredCities = CityData.searchCities(query);
    });
  }

  void _selectCity(String cityName) {
    setState(() {
      _selectedCity = cityName;
      _selectedDistrict = null;
      _filteredDistricts = CityData.getDistricts(cityName);
    });
  }

  void _selectDistrict(String districtName) {
    setState(() {
      _selectedDistrict = districtName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konum Seçimi',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Konum butonu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mevcut Konum',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          'GPS ile otomatik konum',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, 'Konumunuz');
                    },
                    child: const Text('Kullan', style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Þehir arama
            const Text(
              'Þehir Ara',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              onChanged: _filterCities,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Þehir adi yazin...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white54),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Þehir listesi
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Þehirler
                    Expanded(
                      flex: 1,
                      child: _filteredCities.isEmpty
                          ? const Center(
                              child: Text(
                                'Þehir bulunamadi',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = _filteredCities[index];
                                final cityName = city['name']!;
                                final isSelected = _selectedCity == cityName;
                                
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    cityName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.orange : Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Plaka: ${city['code']}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: Colors.orange, size: 20)
                                      : null,
                                  onTap: () {
                                    _selectCity(cityName);
                                  },
                                );
                              },
                            ),
                    ),
                    
                    // Ayýrýcý
                    if (_filteredDistricts.isNotEmpty) ...[
                      const Divider(color: Colors.white24),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Ýlçeler',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      
                      // Ýlçeler
                      Expanded(
                        flex: 1,
                        child: ListView.builder(
                          itemCount: _filteredDistricts.length,
                          itemBuilder: (context, index) {
                                final districtName = _filteredDistricts[index];
                                final isSelected = _selectedDistrict == districtName;
                                
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    districtName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.orange : Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: Colors.orange, size: 20)
                                      : null,
                                  onTap: () {
                                    _selectDistrict(districtName);
                                  },
                                );
                              },
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCity != null
                    ? () => Navigator.pop(context, _selectedCity)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedCity != null ? '$_selectedCity Seçildi' : 'Þehir Seçin',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alarm Düzenleme Ekranı
class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  String _label = 'Alarm';
  bool _repeat = false;
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  DateTime? _selectedDate;

  final List<String> _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Alarm Ekle', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              final alarm = Alarm(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                time: _time,
                label: _label,
                repeat: _repeat,
                selectedDays: _selectedDays,
                isEnabled: true,
                date: _selectedDate,
              );
              Navigator.pop(context, alarm);
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Tarih seçimi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tarih Seçimi',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Tarih Seç',
                          style: const TextStyle(color: Colors.orange, fontSize: 16),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => setState(() => _selectedDate = null),
                          icon: const Icon(Icons.clear, color: Colors.white54),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Belirli bir gün seçin veya boþ býrakýn',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Saat Seçimi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.fromSwatch().copyWith(
                                primary: Theme.of(context).primaryColor,
                                onPrimary: Theme.of(context).primaryColor,
                                surface: Theme.of(context).colorScheme.surface,
                                onSurface: Theme.of(context).primaryColor,
                              ),
                              dialogBackgroundColor: Theme.of(context).colorScheme.surface,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _time = picked);
                      }
                    },
                    child: Text(
                      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 48,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Label
            TextField(
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelText: 'Alarm Etiketi',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                hintText: 'Örn: Uyanma zamani',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              onChanged: (value) => setState(() => _label = value),
            ),
            
            const SizedBox(height: 24),
            
            // Tekrar
            SwitchListTile(
              title: const Text('Tekrarla', style: TextStyle(color: Colors.white)),
              value: _repeat,
              onChanged: (value) => setState(() => _repeat = value),
              activeColor: Colors.orange,
            ),
            
            if (_repeat) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Günler',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dayNames.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final isSelected = _selectedDays[index];
                        
                        return FilterChip(
                          label: Text(day, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedDays[index] = selected;
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
