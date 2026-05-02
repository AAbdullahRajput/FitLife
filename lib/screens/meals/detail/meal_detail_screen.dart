import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web/web_meal_detail.dart';
import 'mobile/mobile_meal_detail.dart';
 
class MealDetailScreen extends StatelessWidget {
  final Map<String, dynamic> meal;
  final String userTier;
 
  const MealDetailScreen({
    super.key,
    required this.meal,
    required this.userTier,
  });
 
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return WebMealDetail(meal: meal, userTier: userTier);
    return MobileMealDetail(meal: meal, userTier: userTier);
  }
}