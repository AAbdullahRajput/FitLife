import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> saveUserInfo({
    required String name,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String goal,
    required String equipment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'goal': goal,
      'equipment': equipment,
      'isSetup': true,
      'isLoggedIn': false,
    };
    await prefs.setString('fitlife_user', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fitlife_user');
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fitlife_user');
    if (raw == null) return false;
    final data = jsonDecode(raw);
    return data['isSetup'] == true;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fitlife_user');
    if (raw == null) return false;
    final data = jsonDecode(raw);
    return data['isLoggedIn'] == true;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fitlife_user');
    if (raw == null) return;
    final data = jsonDecode(raw);
    data['isLoggedIn'] = value;
    await prefs.setString('fitlife_user', jsonEncode(data));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fitlife_user');
  }
}