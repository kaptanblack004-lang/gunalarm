import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_service.dart';
import 'theme_service.dart';
import 'permission_service.dart';
import 'gun_alarm_app.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final LanguageService _languageService = LanguageService();
  final ThemeService _themeService = ThemeService();

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'onboarding_title_1',
      'description': 'onboarding_desc_1',
      'icon': Icons.alarm,
      'color': Colors.orange,
    },
    {
      'title': 'onboarding_title_2',
      'description': 'onboarding_desc_2',
      'icon': Icons.wb_cloudy,
      'color': Colors.blue,
    },
    {
      'title': 'onboarding_title_3',
      'description': 'onboarding_desc_3',
      'icon': Icons.location_on,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _languageService.loadLanguage();
    _themeService.loadSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeService.currentTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip butonu
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    _languageService.translate('skip'),
                    style: TextStyle(
                      color: _themeService.currentTheme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'],
                            size: 60,
                            color: page['color'],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Title
                        Text(
                          _languageService.translate(page['title']),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _themeService.currentTheme.textTheme.displayLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          _languageService.translate(page['description']),
                          style: TextStyle(
                            fontSize: 16,
                            color: _themeService.currentTheme.textTheme.bodyMedium?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom section
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? Colors.orange 
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _languageService.translate('previous'),
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ),
                      
                      if (_currentPage > 0) const SizedBox(width: 16),
                      
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentPage == _pages.length - 1
                              ? _completeOnboarding
                              : () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? _languageService.translate('get_started')
                                : _languageService.translate('next'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
