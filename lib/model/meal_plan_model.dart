class MealPlanProfile {
  final String? goal;
  final String? dietaryPreference;
  final double? calorieGoal;
  final double? proteinGoal;
  final double? carbsGoal;
  final double? fatGoal;

  const MealPlanProfile({
    this.goal,
    this.dietaryPreference,
    this.calorieGoal,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
  });

  factory MealPlanProfile.fromJson(Map<String, dynamic> json) {
    return MealPlanProfile(
      goal: _nullableString(json['goal']),
      dietaryPreference: _nullableString(json['dietary_preference']),
      calorieGoal: _number(json['calorie_goal']),
      proteinGoal: _number(json['protein_goal']),
      carbsGoal: _number(json['carbs_goal']),
      fatGoal: _number(json['fat_goal']),
    );
  }
}

class MealPlanEntry {
  final int assignmentId;
  final int id;
  final String date;
  final String category;
  final String title;
  final String description;
  final String ingredients;
  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  final String servings;
  final String totalTime;
  final String dietaryCategory;
  final bool eaten;

  const MealPlanEntry({
    required this.assignmentId,
    required this.id,
    required this.date,
    required this.category,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servings,
    required this.totalTime,
    required this.dietaryCategory,
    required this.eaten,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) {
    final meal = json['meal'] is Map
        ? Map<String, dynamic>.from(json['meal'] as Map)
        : <String, dynamic>{};
    return MealPlanEntry(
      assignmentId: _integer(json['assignment_id']),
      id: _integer(meal['id']),
      date: _string(json['date']),
      category: _string(json['category'], fallback: 'meal'),
      title: _string(meal['title'], fallback: 'Meal'),
      description: _string(meal['description']),
      ingredients: _string(meal['ingredients']),
      calories: _string(meal['calories'], fallback: '0'),
      protein: _string(meal['protein'], fallback: '0'),
      carbs: _string(meal['carbs'], fallback: '0'),
      fat: _string(meal['fat'], fallback: '0'),
      servings: _string(meal['servings'], fallback: '1'),
      totalTime: _string(meal['total_time']),
      dietaryCategory: _string(meal['dietary_category'], fallback: 'General'),
      eaten: json['is_eaten'] == true || json['is_eaten'] == 1,
    );
  }

  MealPlanEntry withEaten(bool value) {
    return MealPlanEntry(
      assignmentId: assignmentId,
      id: id,
      date: date,
      category: category,
      title: title,
      description: description,
      ingredients: ingredients,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      servings: servings,
      totalTime: totalTime,
      dietaryCategory: dietaryCategory,
      eaten: value,
    );
  }
}

class MealPlanDay {
  final String date;
  final String dayName;
  final List<MealPlanEntry> meals;
  final double plannedCalories;
  final double eatenCalories;
  final int eatenMeals;

  const MealPlanDay({
    required this.date,
    required this.dayName,
    required this.meals,
    required this.plannedCalories,
    required this.eatenCalories,
    required this.eatenMeals,
  });

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'];
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};
    return MealPlanDay(
      date: _string(json['date']),
      dayName: _string(json['day_name'], fallback: 'Day'),
      meals: rawMeals is List
          ? rawMeals
              .whereType<Map>()
              .map((item) =>
                  MealPlanEntry.fromJson(Map<String, dynamic>.from(item)))
              .where((meal) => meal.id > 0)
              .toList()
          : const [],
      plannedCalories: _number(summary['planned_calories']) ?? 0,
      eatenCalories: _number(summary['eaten_calories']) ?? 0,
      eatenMeals: _integer(summary['eaten_meals']),
    );
  }

  MealPlanDay withMeals(List<MealPlanEntry> updatedMeals) {
    return MealPlanDay(
      date: date,
      dayName: dayName,
      meals: updatedMeals,
      plannedCalories: updatedMeals.fold(
        0,
        (sum, meal) => sum + _nutritionNumber(meal.calories),
      ),
      eatenCalories: updatedMeals
          .where((meal) => meal.eaten)
          .fold(0, (sum, meal) => sum + _nutritionNumber(meal.calories)),
      eatenMeals: updatedMeals.where((meal) => meal.eaten).length,
    );
  }
}

class MealPlan {
  final MealPlanProfile profile;
  final List<MealPlanDay> days;

  const MealPlan({required this.profile, required this.days});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    return MealPlan(
      profile: MealPlanProfile.fromJson(
        json['profile'] is Map
            ? Map<String, dynamic>.from(json['profile'] as Map)
            : const {},
      ),
      days: rawDays is List
          ? rawDays
              .whereType<Map>()
              .map((item) =>
                  MealPlanDay.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

int _integer(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

double? _number(dynamic value) {
  if (value == null) return null;
  return double.tryParse(
    value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
  );
}

double _nutritionNumber(String value) =>
    double.tryParse(value.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
