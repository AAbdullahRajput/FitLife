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

  // ── Profile Photo ─────────────────────────────────────────────────────────
  static Future<void> saveProfilePhoto(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo', path);
  }

  static Future<String?> getProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_photo');
  }

  // ── Home Banner Image ─────────────────────────────────────────────────────
  static Future<void> saveHomeBanner(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_banner', path);
  }

  static Future<String?> getHomeBanner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('home_banner');
  }

  // ── Update Single Profile Field ───────────────────────────────────────────
  static Future<void> updateUserField(String field, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fitlife_user');
    if (raw == null) return;
    final data = jsonDecode(raw);
    data[field] = value;
    await prefs.setString('fitlife_user', jsonEncode(data));
  }
}