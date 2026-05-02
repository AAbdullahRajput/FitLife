import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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

  // ── Upload image to Supabase and return public URL ────────────────────────
  static Future<String?> uploadProfilePhotoAndGetUrl(XFile picked) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? 'guest';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'profiles/profile_${userId}_$timestamp.jpg';

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await supabase.storage.from('fitlife-images').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
      } else {
        final file = File(picked.path);
        await supabase.storage.from('fitlife-images').upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
      }

      final publicUrl = supabase.storage
          .from('fitlife-images')
          .getPublicUrl(filePath);

      // Add cache-bust so image refreshes after re-upload
      return publicUrl;
    } catch (e) {
      // ignore: avoid_print
      print('Profile photo upload error: $e');
      return null;
    }
  }

  static Future<String?> uploadHomeBannerAndGetUrl(XFile picked) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? 'guest';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'banners/banner_${userId}_$timestamp.jpg';

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await supabase.storage.from('fitlife-images').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
      } else {
        final file = File(picked.path);
        await supabase.storage.from('fitlife-images').upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
      }

      final publicUrl = supabase.storage
          .from('fitlife-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Banner upload error: $e');
      return null;
    }
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

  // ── Save profile photo URL to Supabase profiles table ────────────────────
  static Future<void> saveProfilePhotoToSupabase(String url) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', userId);
    } catch (e) {
      print('Save avatar_url error: $e');
    }
  }

  // ── Get profile photo URL from Supabase profiles table ───────────────────
  static Future<String?> getProfilePhotoFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final res = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();
      return res['avatar_url'] as String?;
    } catch (e) {
      return null;
    }
  }
}