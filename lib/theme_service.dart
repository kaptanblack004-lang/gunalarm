import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GradientTheme {
  final String name;
  final String description;
  final List<Color> colors;
  final IconData icon;
  final bool isPremium;

  GradientTheme({
    required this.name,
    required this.description,
    required this.colors,
    required this.icon,
    this.isPremium = false,
  });
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = true;
  String _selectedGradientTheme = 'Midnight';
  bool get isDarkMode => _isDarkMode;
  String get selectedGradientTheme => _selectedGradientTheme;

  static List<GradientTheme> get gradientThemes => [
    GradientTheme(
      name: 'Midnight',
      description: 'Klasik gece temasý',
      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      icon: Icons.nightlight,
    ),
    GradientTheme(
      name: 'Ocean',
      description: 'Okyanus mavisi',
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      icon: Icons.waves,
    ),
    GradientTheme(
      name: 'Sunset',
      description: 'Gün batýmý renkleri',
      colors: [Color(0xFF4B134F), Color(0xFFC94B4B), Color(0xFF4B134F)],
      icon: Icons.wb_twilight,
    ),
    GradientTheme(
      name: 'Forest',
      description: 'Orman yeþili',
      colors: [Color(0xFF134E5E), Color(0xFF71B280)],
      icon: Icons.forest,
    ),
    GradientTheme(
      name: 'Galaxy',
      description: 'Galaksi moru',
      colors: [Color(0xFF2E1A47), Color(0xFF6A1B9A), Color(0xFF9C27B0)],
      icon: Icons.star,
    ),
    GradientTheme(
      name: 'Fire',
      description: 'Ateþ turuncusu',
      colors: [Color(0xFF8B0000), Color(0xFFFF4500), Color(0xFFFF6347)],
      icon: Icons.local_fire_department,
      isPremium: true,
    ),
    GradientTheme(
      name: 'Arctic',
      description: 'Kutup mavisi',
      colors: [Color(0xFFE6F2FF), Color(0xFFB3D9FF), Color(0xFF80BFFF)],
      icon: Icons.ac_unit,
      isPremium: true,
    ),
    GradientTheme(
      name: 'Aurora',
      description: 'Kutup ýþýklarý',
      colors: [Color(0xFF00FF41), Color(0xFF00FFD4), Color(0xFF0099FF)],
      icon: Icons.auto_awesome,
      isPremium: true,
    ),
    GradientTheme(
      name: 'Volcano',
      description: 'Volkan kýrmýzýsý',
      colors: [Color(0xFF8B0000), Color(0xFFDC143C), Color(0xFFFF69B4)],
      icon: Icons.terrain,
      isPremium: true,
    ),
  ];

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  GradientTheme get currentGradientTheme {
    return gradientThemes.firstWhere(
      (theme) => theme.name == _selectedGradientTheme,
      orElse: () => gradientThemes.first,
    );
  }

  LinearGradient get gradientBackground {
    final theme = currentGradientTheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: theme.colors,
    );
  }

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1A1A2E),
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1A1A2E),
      secondary: Colors.orange,
      surface: Color(0xFF16213E),
      background: Color(0xFF1A1A2E),
      error: Colors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF16213E),
      elevation: 4,
    ),
  );

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[50]!,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.orange,
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: Colors.red,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
    ),
  );

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setGradientTheme(String themeName) async {
    _selectedGradientTheme = themeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gradient_theme', themeName);
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    _selectedGradientTheme = prefs.getString('gradient_theme') ?? 'Midnight';
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  List<GradientTheme> getAvailableThemes() {
    return gradientThemes;
  }

  List<GradientTheme> getPremiumThemes() {
    return gradientThemes.where((theme) => theme.isPremium).toList();
  }

  List<GradientTheme> getFreeThemes() {
    return gradientThemes.where((theme) => !theme.isPremium).toList();
  }

  bool isThemeUnlocked(String themeName) {
    final theme = gradientThemes.firstWhere((t) => t.name == themeName);
    return !theme.isPremium;
  }

  Future<void> unlockTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedThemes = prefs.getStringList('unlocked_themes') ?? [];
    if (!unlockedThemes.contains(themeName)) {
      unlockedThemes.add(themeName);
      await prefs.setStringList('unlocked_themes', unlockedThemes);
    }
  }

  Future<bool> isThemePurchased(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedThemes = prefs.getStringList('unlocked_themes') ?? [];
    return unlockedThemes.contains(themeName);
  }
}
