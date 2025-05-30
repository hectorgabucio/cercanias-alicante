import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const platform = MethodChannel('com.example.cercanias_schedule/widget');

  static Future<void> updateWidget({
    required String origin,
    required String destination,
    required List<Map<String, dynamic>> schedules,
  }) async {
    try {
      // Save data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('origin', origin);
      await prefs.setString('destination', destination);
      await prefs.setString('schedules', jsonEncode(schedules));

      if (kDebugMode) {
        print('WidgetService: Data saved to shared preferences');
        print('WidgetService: Origin: $origin');
        print('WidgetService: Destination: $destination');
        print('WidgetService: Schedules: ${jsonEncode(schedules)}');
      }

      // Notify widget to update
      await platform.invokeMethod('updateWidget', {
        'origin': origin,
        'destination': destination,
        'schedulesJson': jsonEncode(schedules),
      });
      if (kDebugMode) {
        print('WidgetService: updateWidget method invoked');
      }

    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error updating widget: ${e.message}');
      }
    }
  }
} 