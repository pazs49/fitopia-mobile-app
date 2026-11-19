class DashboardWorkout {
  final String title;
  final String description;
  final String level;
  final String type;

  const DashboardWorkout({
    required this.title,
    required this.description,
    required this.level,
    required this.type,
  });

  factory DashboardWorkout.fromJson(Map<String, dynamic> json) {
    return DashboardWorkout(
      title: _string(json['title'], "Today's Workout"),
      description: _string(json['description'], ''),
      level: _string(json['level'] ?? json['level_title'], ''),
      type: _string(json['type'] ?? json['workout_type_title'], ''),
    );
  }
}

class DashboardMeal {
  final int id;
  final String title;
  final String description;
  final String category;
  final String duration;
  final String? assignedDate;
  final bool logged;

  const DashboardMeal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.assignedDate,
    required this.logged,
  });

  factory DashboardMeal.fromJson(Map<String, dynamic> json) {
    return DashboardMeal(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: _string(json['title'], 'Meal'),
      description: _string(json['description'], ''),
      category: _string(json['categorydiet_title'], 'Meal'),
      duration: _string(json['total_time'], ''),
      assignedDate: _dateString(json['assign_date']),
      logged: json['is_logged'] == true || json['is_logged'] == 1,
    );
  }
}

String _string(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _dateString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text.split('T').first;
}
