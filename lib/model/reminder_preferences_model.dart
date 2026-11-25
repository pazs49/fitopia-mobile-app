class ReminderPreferences {
  final String breakfastTime;
  final String lunchTime;
  final String snackTime;
  final String dinnerTime;
  final String workoutTime;
  final bool breakfastEnabled;
  final bool lunchEnabled;
  final bool snackEnabled;
  final bool dinnerEnabled;
  final bool workoutEnabled;

  const ReminderPreferences({
    required this.breakfastTime,
    required this.lunchTime,
    required this.snackTime,
    required this.dinnerTime,
    required this.workoutTime,
    required this.breakfastEnabled,
    required this.lunchEnabled,
    required this.snackEnabled,
    required this.dinnerEnabled,
    required this.workoutEnabled,
  });

  factory ReminderPreferences.fromJson(Map<String, dynamic> json) {
    return ReminderPreferences(
      breakfastTime: _time(json['breakfast_time'], '09:00'),
      lunchTime: _time(json['lunch_time'], '12:00'),
      snackTime: _time(json['snack_time'], '15:00'),
      dinnerTime: _time(json['dinner_time'], '19:00'),
      workoutTime: _time(json['workout_time'], '08:00'),
      breakfastEnabled: _boolean(json['breakfast_enabled']),
      lunchEnabled: _boolean(json['lunch_enabled']),
      snackEnabled: _boolean(json['snack_enabled']),
      dinnerEnabled: _boolean(json['dinner_enabled']),
      workoutEnabled: _boolean(json['workout_enabled']),
    );
  }

  ReminderPreferences copyWith({
    String? breakfastTime,
    String? lunchTime,
    String? snackTime,
    String? dinnerTime,
    String? workoutTime,
    bool? breakfastEnabled,
    bool? lunchEnabled,
    bool? snackEnabled,
    bool? dinnerEnabled,
    bool? workoutEnabled,
  }) {
    return ReminderPreferences(
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      snackTime: snackTime ?? this.snackTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      workoutTime: workoutTime ?? this.workoutTime,
      breakfastEnabled: breakfastEnabled ?? this.breakfastEnabled,
      lunchEnabled: lunchEnabled ?? this.lunchEnabled,
      snackEnabled: snackEnabled ?? this.snackEnabled,
      dinnerEnabled: dinnerEnabled ?? this.dinnerEnabled,
      workoutEnabled: workoutEnabled ?? this.workoutEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breakfast_time': breakfastTime,
      'lunch_time': lunchTime,
      'snack_time': snackTime,
      'dinner_time': dinnerTime,
      'workout_time': workoutTime,
      'breakfast_enabled': breakfastEnabled,
      'lunch_enabled': lunchEnabled,
      'snack_enabled': snackEnabled,
      'dinner_enabled': dinnerEnabled,
      'workout_enabled': workoutEnabled,
    };
  }

  static String _time(dynamic value, String fallback) {
    final time = value?.toString();
    if (time == null || time.isEmpty) return fallback;
    return time.length > 5 ? time.substring(0, 5) : time;
  }

  static bool _boolean(dynamic value) {
    return value == true || value == 1 || value == '1';
  }
}
