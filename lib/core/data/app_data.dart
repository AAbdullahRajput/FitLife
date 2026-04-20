import 'package:flutter/material.dart';

class AppData {
  static List<Map<String, dynamic>> getTodayWorkouts() => [
    {
      'name': 'Bench Press',
      'sets': 4,
      'reps': 10,
      'rest': '60s',
      'muscle': 'Chest',
      'emoji': '🏋️',
      'color': const Color(0xFF2979FF),
      'done': false,
      'difficulty': 'beginner',
    },
    {
      'name': 'Pull Ups',
      'sets': 3,
      'reps': 12,
      'rest': '60s',
      'muscle': 'Back',
      'emoji': '💪',
      'color': const Color(0xFF00C853),
      'done': false,
      'difficulty': 'intermediate',
    },
    {
      'name': 'Shoulder Press',
      'sets': 3,
      'reps': 10,
      'rest': '45s',
      'muscle': 'Shoulders',
      'emoji': '⚡',
      'color': const Color(0xFFFF6D00),
      'done': false,
      'difficulty': 'beginner',
    },
  ];

  static List<Map<String, dynamic>> getTodayMeals() => [
    {
      'meal': 'Breakfast',
      'time': '8:00 AM',
      'items': 'Oats + Eggs + Milk',
      'calories': 450,
      'protein': 28,
      'carbs': 52,
      'fat': 12,
      'emoji': '🥣',
      'color': const Color(0xFFFFD600),
      'goal': 'Muscle Gain',
      'prepTime': '10 min',
    },
    {
      'meal': 'Lunch',
      'time': '1:00 PM',
      'items': 'Chicken Rice + Salad',
      'calories': 650,
      'protein': 45,
      'carbs': 70,
      'fat': 15,
      'emoji': '🍗',
      'color': const Color(0xFF00C853),
      'goal': 'Muscle Gain',
      'prepTime': '20 min',
    },
    {
      'meal': 'Snack',
      'time': '4:00 PM',
      'items': 'Banana + Protein Shake',
      'calories': 280,
      'protein': 25,
      'carbs': 35,
      'fat': 4,
      'emoji': '🍌',
      'color': const Color(0xFFFF6D00),
      'goal': 'Energy Boost',
      'prepTime': '5 min',
    },
    {
      'meal': 'Dinner',
      'time': '8:00 PM',
      'items': 'Fish + Vegetables + Rice',
      'calories': 520,
      'protein': 38,
      'carbs': 48,
      'fat': 14,
      'emoji': '🐟',
      'color': const Color(0xFF2979FF),
      'goal': 'Recovery',
      'prepTime': '25 min',
    },
  ];

  static const String userName = 'Abdullah';
  static const double userWeight = 75.0;
  static const double userHeight = 175.0;
  static const int userAge = 24;
  static const String userGoal = 'Build Muscle';
}