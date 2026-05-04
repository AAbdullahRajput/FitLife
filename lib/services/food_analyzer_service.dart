import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class FoodAnalyzerService {
  // ── Change this IP when running on real device ──────────────────────────
  // Android emulator   → 10.0.2.2
  // iOS simulator      → localhost or 127.0.0.1
  // Real Android phone → your PC's local IP (e.g. 192.168.1.5)
  // Web (same machine) → localhost
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://192.168.0.103:8000';
    return 'http://localhost:8000'; // iOS simulator
  }

  /// Analyze a food image using AI.
  /// [imageFile]  — pass on mobile (File from image_picker)
  /// [imageBytes] — pass on web (Uint8List from image_picker web)
  /// [fileName]   — original file name (e.g. "photo.jpg")
  /// [goal]       — user's fitness goal string
  static Future<Map<String, dynamic>?> analyzeFood({
    File? imageFile,
    List<int>? imageBytes,
    required String fileName,
    required String goal,
  }) async {
    if (imageFile == null && imageBytes == null) return null;

    try {
      final uri = Uri.parse('$_baseUrl/analyze-food');
      final request = http.MultipartRequest('POST', uri);

      // Add goal as form field
      request.fields['goal'] = goal;

      // Add image file
      if (imageFile != null && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: fileName,
        ));
      } else if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ));
      }

      // 60 second timeout for AI processing
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timed out. Server may be slow.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded as Map<String, dynamic>;
      }

      // Parse error message from server
      try {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Server error ${response.statusCode}');
      } catch (_) {
        throw Exception('Server error ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
          'Cannot connect to server. Make sure your Python server is running.');
    } catch (e) {
      rethrow;
    }
  }

  /// Check if the Python server is running
  static Future<bool> isServerRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}