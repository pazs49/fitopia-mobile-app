import 'dashboard_content_model.dart';

class MyProgram {
  final int? workoutId;
  final int? assignmentId;
  final String title;
  final String description;
  final String level;
  final String type;
  final String assignedDate;
  final String status;
  final bool completed;
  final bool canComplete;

  const MyProgram({
    required this.workoutId,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.level,
    required this.type,
    required this.assignedDate,
    required this.status,
    required this.completed,
    required this.canComplete,
  });

  factory MyProgram.fromJson(Map<String, dynamic> json) {
    final workout = json['workout'] is Map
        ? Map<String, dynamic>.from(json['workout'] as Map)
        : <String, dynamic>{};
    final assignedDate =
        json['assigned_date']?.toString().split('T').first ?? '';
    final today = DateTime.now().toIso8601String().split('T').first;
    final status = json['status']?.toString() ?? '';

    return MyProgram(
      workoutId: int.tryParse(workout['id']?.toString() ?? ''),
      assignmentId: int.tryParse(json['id']?.toString() ?? ''),
      title: workout['title']?.toString() ?? 'Rest day',
      description: workout['description']?.toString() ?? '',
      level: workout['level']?.toString() ?? '',
      type: workout['type']?.toString() ?? '',
      assignedDate: assignedDate,
      status: status,
      completed: status == 'completed' || json['completed_at'] != null,
      canComplete: assignedDate == today && workout['id'] != null,
    );
  }

  DashboardWorkout toDashboardWorkout() {
    return DashboardWorkout(
      workoutId: workoutId,
      assignmentId: assignmentId,
      title: title,
      description: description,
      level: level,
      type: type,
      completed: completed,
      canComplete: canComplete,
    );
  }
}
