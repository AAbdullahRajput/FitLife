import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web/web_meals.dart';
import 'mobile/mobile_meals.dart';

class MealsScreen extends StatelessWidget {
  final String userTier; // 'guest', 'free', 'premium'

  const MealsScreen({super.key, required this.userTier});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return WebMeals(userTier: userTier);
    return MobileMeals(userTier: userTier);
  }
}