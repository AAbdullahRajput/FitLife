import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────────
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

  // ── Profile ───────────────────────────────────────────────────────────────────
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
        'name': fullName,
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

  static Future<bool> updateProfileField(String field, dynamic value) async {
    if (!isLoggedIn) return false;
    try {
      await _client
          .from('profiles')
          .update({field: value})
          .eq('id', currentUser!.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Exercises ─────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getExercises({
    String? muscle,
    String? difficulty,
    String tier = 'guest',
  }) async {
    try {
      final allowed = getAllowedTiers(tier);
      var query = _client
          .from('exercises')
          .select('id, name, muscle, category, difficulty, tier_required, created_at')
          .inFilter('tier_required', allowed);

      if (muscle != null && muscle != 'All') query = query.eq('muscle', muscle);
      if (difficulty != null) query = query.ilike('difficulty', difficulty);

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
      // Load all variations for the exercise regardless of tier
      // (locked ones are shown blurred — UI handles the gate)
      final res = await _client
          .from('exercise_variations')
          .select(
            'id, exercise_id, name, description, steps, sets, reps, rest_seconds, tier_required, created_at',
          )
          .eq('exercise_id', exerciseId)
          .order('tier_required'); // guest → free → premium order
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ── Meals ─────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMeals({
    String? type,
    String tier = 'guest',
  }) async {
    try {
      final allowed = getAllowedTiers(tier);
      var query = _client
          .from('meals')
          .select('id, name, type, calories, protein, carbs, fat, tier_required, created_at')
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
          .select(
            'id, meal_id, ingredients, recipe, prep_time_minutes, tier_required, created_at',
          )
          .eq('meal_id', mealId)
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  // ── Log workout ───────────────────────────────────────────────────────────────
  static Future<bool> logWorkout(int exerciseId) async {
    if (!isLoggedIn) return false;
    try {
      final today = _todayString();
      await _client.from('user_workouts').insert({
        'user_id': currentUser!.id,
        'exercise_id': exerciseId,
        'date': today,
        'completed': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserWorkouts({DateTime? date}) async {
    if (!isLoggedIn) return [];
    try {
      var query = _client
          .from('user_workouts')
          .select(
            'id, user_id, exercise_id, date, completed, created_at, exercises(name, muscle, difficulty)',
          )
          .eq('user_id', currentUser!.id);

      if (date != null) query = query.eq('date', _dateString(date));

      final res = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> markWorkoutCompleted(int workoutId) async {
    try {
      await _client
          .from('user_workouts')
          .update({'completed': true})
          .eq('id', workoutId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Log meal ──────────────────────────────────────────────────────────────────
  static Future<bool> logMeal(int mealId) async {
    if (!isLoggedIn) return false;
    try {
      final today = _todayString();
      await _client.from('user_meals').insert({
        'user_id': currentUser!.id,
        'meal_id': mealId,
        'date': today,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserMeals({DateTime? date}) async {
    if (!isLoggedIn) return [];
    try {
      var query = _client
          .from('user_meals')
          .select(
            'id, user_id, meal_id, date, created_at, meals(name, type, calories, protein, carbs, fat)',
          )
          .eq('user_id', currentUser!.id);

      if (date != null) query = query.eq('date', _dateString(date));

      final res = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────────
  static Future<Map<String, int>> getWeeklyStats() async {
    if (!isLoggedIn) return {'workouts': 0, 'meals': 0};
    try {
      final weekAgo = _dateString(DateTime.now().subtract(const Duration(days: 7)));

      final workoutsRes = await _client
          .from('user_workouts')
          .select('id')
          .eq('user_id', currentUser!.id)
          .gte('date', weekAgo);

      final mealsRes = await _client
          .from('user_meals')
          .select('id')
          .eq('user_id', currentUser!.id)
          .gte('date', weekAgo);

      return {
        'workouts': (workoutsRes as List).length,
        'meals': (mealsRes as List).length,
      };
    } catch (_) {
      return {'workouts': 0, 'meals': 0};
    }
  }

  static Future<Map<String, int>> getTodayStats() async {
    if (!isLoggedIn) return {'workouts': 0, 'meals': 0};
    try {
      final today = _todayString();

      final workoutsRes = await _client
          .from('user_workouts')
          .select('id')
          .eq('user_id', currentUser!.id)
          .eq('date', today);

      final mealsRes = await _client
          .from('user_meals')
          .select('id')
          .eq('user_id', currentUser!.id)
          .eq('date', today);

      return {
        'workouts': (workoutsRes as List).length,
        'meals': (mealsRes as List).length,
      };
    } catch (_) {
      return {'workouts': 0, 'meals': 0};
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Private helpers ───────────────────────────────────────────────────────────
  static String _todayString() => _dateString(DateTime.now());

  static String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}