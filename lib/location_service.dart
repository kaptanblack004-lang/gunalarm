import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      // Konum izni kontrolü
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Konum servisi kapali');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Konum izni reddedildi');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Konum izni kalici olarak reddedildi');
        return null;
      }

      // Mevcut konumu al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      debugPrint('Konum alinamadi: $e');
      return null;
    }
  }

  static Future<String?> getLocationName(Position position) async {
    try {
      // Reverse geocoding - koordinatlardan yer adi al
      // Not: Gerçek uygulamada geocoding paketi kullanilir
      // Simdilik koordinatlari formatlayip dondur
      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      debugPrint('Konum adi alinamadi: $e');
      return null;
    }
  }

  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
