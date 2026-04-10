import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    // Konum izni iste
    final locationStatus = await Permission.location.request();
    
    if (!locationStatus.isGranted) {
      // İzin verilmediyse ayarlara yönlendir
      if (locationStatus.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      return false;
    }

    // Konum servisi kontrolü
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Konum servisi kapalı ise açmaya çalış
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        return false;
      }
    }

    return true;
  }

  static Future<bool> checkAllPermissions() async {
    final notificationGranted = await requestNotificationPermission();
    final locationGranted = await requestLocationPermission();
    
    return notificationGranted && locationGranted;
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İzinler Gerekli'),
          content: const Text(
            'GünAlarm uygulaması için aşağıdaki izinler gereklidir:\n\n'
            '• Bildirimler: Alarm bildirimleri için\n'
            '• Konum: Hava durumu bilgisi için',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await requestAllPermissions();
              },
              child: const Text('İzin Ver'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> requestAllPermissions() async {
    await requestNotificationPermission();
    await requestLocationPermission();
  }

  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'İzin verildi';
      case PermissionStatus.denied:
        return 'İzin reddedildi';
      case PermissionStatus.restricted:
        return 'İzin kısıtlandı';
      case PermissionStatus.limited:
        return 'İzin sınırlı';
      case PermissionStatus.permanentlyDenied:
        return 'İzin kalıcı olarak reddedildi';
      case PermissionStatus.provisional:
        return 'Geçici izin';
    }
  }
}
