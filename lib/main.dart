// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/supabase_constants.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/user_info_screen.dart';
import 'screens/onboarding/goal_selection_screen.dart';
import 'screens/onboarding/equipment_selection_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/workout/exercise_detail_screen.dart';
import 'screens/workout/workout_screen.dart';
import 'screens/meals/meals_screen.dart';
import 'screens/meals/meal_detail_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const FitLifeApp(),
    ),
  );
}

class FitLifeApp extends StatelessWidget {
  const FitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider so MaterialApp rebuilds on accent OR dark/light change.
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accent = themeProvider.accentColor;

    return MaterialApp(
      title: 'FitLife',
      debugShowCheckedModeBanner: false,
      // Pass the current accent into both themes so Material widgets
      // (Switch, Slider, ProgressIndicator, etc.) all inherit it.
      theme: AppTheme.lightTheme(accent: accent),
      darkTheme: AppTheme.darkTheme(accent: accent),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        // ── Core ──
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),

        // ── Auth ──
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // ── Onboarding ──
        '/onboarding': (context) => const OnboardingScreen(),
        '/user-info': (context) => const UserInfoScreen(),
        '/goal-selection': (context) => const GoalSelectionScreen(),
        '/equipment-selection': (context) => const EquipmentSelectionScreen(),

        // ── Workout ──
        '/workout': (context) => WorkoutScreen(userTier: 'guest'),
        '/exercise-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null) return const HomeScreen();
          return ExerciseDetailScreen(
            exercise: args as Map<String, dynamic>,
            userTier: 'guest',
          );
        },

        // ── Meals / Diet ──
        '/diet': (context) => MealsScreen(userTier: 'guest'),
        '/meal-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null) return const HomeScreen();
          return MealDetailScreen(
            meal: args as Map<String, dynamic>,
            userTier: 'guest',
          );
        },

        // ── Other tabs ──
        '/progress': (context) => const ProgressScreen(),
        '/profile': (context) => const ProfileScreen(),
        // '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}