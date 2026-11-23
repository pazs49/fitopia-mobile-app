class DashboardWorkout {
  final int? workoutId;
  final int? assignmentId;
  final String title;
  final String description;
  final String level;
  final String type;
  final bool completed;
  final bool canComplete;

  const DashboardWorkout({
    required this.workoutId,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.level,
    required this.type,
    required this.completed,
    this.canComplete = true,
  });

  factory DashboardWorkout.fromJson(Map<String, dynamic> json) {
    return DashboardWorkout(
      workoutId: int.tryParse(
          json['id']?.toString() ?? json['workout_id']?.toString() ?? ''),
      assignmentId: int.tryParse(json['assignment_id']?.toString() ?? ''),
      title: _string(json['title'], "Today's Workout"),
      description: _string(json['description'], ''),
      level: _string(json['level'] ?? json['level_title'], ''),
      type: _string(json['type'] ?? json['workout_type_title'], ''),
      completed: json['assignment_status'] == 'completed' ||
          json['status'] == 'completed' ||
          json['completed_at'] != null,
      canComplete: json['can_complete'] as bool? ?? true,
    );
  }
}

class DashboardMeal {
  final int id;
  final int? assignmentId;
  final String title;
  final String description;
  final String category;
  final String duration;
  final String? assignedDate;
  final bool logged;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const DashboardMeal({
    required this.id,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.assignedDate,
    required this.logged,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory DashboardMeal.fromJson(Map<String, dynamic> json) {
    return DashboardMeal(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      assignmentId: int.tryParse(json['assignment_id']?.toString() ?? ''),
      title: _string(json['title'], 'Meal'),
      description: _string(json['description'], ''),
      category: _string(
        json['meal_category'] ?? json['category'] ?? json['categorydiet_title'],
        'Meal',
      ),
      duration: _string(json['total_time'], ''),
      assignedDate: _dateString(json['assign_date']),
      logged: json['is_eaten'] == true ||
          json['is_eaten'] == 1 ||
          json['is_logged'] == true ||
          json['is_logged'] == 1,
      calories: _number(json['calories']),
      protein: _number(json['protein']),
      carbs: _number(json['carbs']),
      fat: _number(json['fat']),
    );
  }

  String get trackingKey =>
      '${assignmentId ?? '$id:${category.toLowerCase()}'}';
}

String _string(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _dateString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text.split('T').first;
}
