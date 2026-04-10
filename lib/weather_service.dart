import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static Future<List<Map<String, dynamic>>> getForecast({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=tr',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseForecastData(data);
      }
      return [];
    } catch (e) {
      print('Forecast error: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseForecastData(Map<String, dynamic> data) {
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

  static Future<List<Map<String, dynamic>>> getForecastByCity({
    required String city,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric&lang=tr',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseForecastData(data);
      }
      return [];
    } catch (e) {
      print('Forecast error: $e');
      return [];
    }
  }
}
