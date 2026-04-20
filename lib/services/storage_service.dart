import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class StorageService {
  static void saveUserInfo({
    required String name,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String goal,
    required String equipment,
  }) {
    final data = {
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'goal': goal,
      'equipment': equipment,
      'isSetup': true,
    };
    html.window.localStorage['fitlife_user'] = jsonEncode(data);
  }

  static Map<String, dynamic>? getUserInfo() {
    final raw = html.window.localStorage['fitlife_user'];
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static bool isSetupDone() {
    final raw = html.window.localStorage['fitlife_user'];
    if (raw == null) return false;
    final data = jsonDecode(raw);
    return data['isSetup'] == true;
  }

  static bool isLoggedIn() {
    final raw = html.window.localStorage['fitlife_user'];
    if (raw == null) return false;
    final data = jsonDecode(raw);
    return data['isLoggedIn'] == true;
  }

  static void setLoggedIn(bool value) {
    final raw = html.window.localStorage['fitlife_user'];
    if (raw == null) return;
    final data = jsonDecode(raw);
    data['isLoggedIn'] = value;
    html.window.localStorage['fitlife_user'] = jsonEncode(data);
  }

  static void clearAll() {
    html.window.localStorage.remove('fitlife_user');
  }
}