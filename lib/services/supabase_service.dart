import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ── Auth ──────────────────────────────────
  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<String> getUserTier() async {
    if (!isLoggedIn) return 'guest';
    try {
      final res = await _client
          .from('profiles')
          .select('tier')
          .eq('id', currentUser!.id)
          .single();
      return res['tier'] ?? 'free';
    } catch (_) {
      return 'free';
    }
  }

  static List<String> getAllowedTiers(String tier) {
    if (tier == 'premium') return ['guest', 'free', 'premium'];
    if (tier == 'free') return ['guest', 'free'];
    return ['guest'];
  }

  // ── Profile ───────────────────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    if (!isLoggedIn) return null;
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveProfile({
    required String fullName,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String goal,
    required String equipment,
  }) async {
    if (!isLoggedIn) return false;
    try {
      await _client.from('profiles').upsert({
        'id': currentUser!.id,
        'full_name': fullName,
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'goal': goal,
        'equipment': equipment,
        'tier': 'free',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Exercises ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getExercises({
    String? muscle,
    String? difficulty,
    String tier = 'guest',
  }) async {
    try {
      final allowed = getAllowedTiers(tier);
      var query = _client
          .from('exercises')
          .select()
          .inFilter('tier_required', allowed);

      if (muscle != null) query = query.eq('muscle', muscle);
      if (difficulty != null) query = query.eq('difficulty', difficulty);

      final res = await query.order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getExerciseVariations(
    int exerciseId, {
    String tier = 'guest',
  }) async {
    try {
      final allowed = getAllowedTiers(tier);
      final res = await _client
          .from('exercise_variations')
          .select()
          .eq('exercise_id', exerciseId)
          .inFilter('tier_required', allowed)
          .order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ── Meals ─────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMeals({
    String? type,
    String tier = 'guest',
  }) async {
    try {
      final allowed = getAllowedTiers(tier);
      var query = _client
          .from('meals')
          .select()
          .inFilter('tier_required', allowed);

      if (type != null) query = query.eq('type', type);

      final res = await query.order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMealDetail(int mealId) async {
    try {
      final res = await _client
          .from('meal_details')
          .select()
          .eq('meal_id', mealId)
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  // ── Log workout completed ─────────────────
  static Future<void> logWorkout(int exerciseId) async {
    if (!isLoggedIn) return;
    try {
      await _client.from('user_workouts').insert({
        'user_id': currentUser!.id,
        'exercise_id': exerciseId,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Log meal eaten ─────────────────────────
  static Future<void> logMeal(int mealId) async {
    if (!isLoggedIn) return;
    try {
      await _client.from('user_meals').insert({
        'user_id': currentUser!.id,
        'meal_id': mealId,
        'eaten_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Sign out ──────────────────────────────
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}