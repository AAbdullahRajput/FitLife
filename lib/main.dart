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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'FitLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/user-info': (context) => const UserInfoScreen(),
        '/goal-selection': (context) => const GoalSelectionScreen(),
        '/equipment-selection': (context) => const EquipmentSelectionScreen(),
        '/home': (context) => const HomeScreen(),
        '/exercise-detail': (context) => ExerciseDetailScreen(
              exercise: ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>,
              userTier: 'guest',
            ),
      },
    );
  }
}