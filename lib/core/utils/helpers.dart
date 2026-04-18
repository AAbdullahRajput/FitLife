class Helpers {
  // BMI Calculator
  static double calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // BMI Category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  // Daily calories needed (Harris-Benedict formula)
  static double calculateDailyCalories({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goal,
  }) {
    double bmr;

    if (gender.toLowerCase() == 'male') {
      bmr = 88.362 + (13.397 * weightKg) +
            (4.799 * heightCm) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weightKg) +
            (3.098 * heightCm) - (4.330 * age);
    }

    // Moderate activity multiplier
    double tdee = bmr * 1.55;

    // Adjust for goal
    if (goal == 'Lose Weight') return tdee - 500;
    if (goal == 'Build Muscle') return tdee + 300;
    return tdee; // Stay Fit / maintain
  }

  // Greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Format date → "Monday, 18 April"
  static String formatDate(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  // Format duration in seconds → "1m 30s"
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Validate age
  static bool isValidAge(String value) {
    final age = int.tryParse(value);
    return age != null && age >= 10 && age <= 100;
  }

  // Validate weight
  static bool isValidWeight(String value) {
    final weight = double.tryParse(value);
    return weight != null && weight >= 20 && weight <= 300;
  }

  // Validate height
  static bool isValidHeight(String value) {
    final height = double.tryParse(value);
    return height != null && height >= 50 && height <= 250;
  }
}