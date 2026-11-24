class ProfileSummary {
  final String activeDays;
  final int? goalId;
  final int? dietaryRequirementsId;
  final int? activityId;
  final int? genderId;
  final int? femaleSpecificPlan;
  final int? age;
  final int? height;
  final String? weekGoals;
  final double initialWeight;
  final double currentWeight;
  final double goalWeight;
  final double progressValue;
  final String progressType;

  const ProfileSummary({
    required this.activeDays,
    this.goalId,
    this.dietaryRequirementsId,
    this.activityId,
    this.genderId,
    this.femaleSpecificPlan,
    this.age,
    this.height,
    this.weekGoals,
    required this.initialWeight,
    required this.currentWeight,
    required this.goalWeight,
    required this.progressValue,
    required this.progressType,
  });

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      activeDays: json['active_days']?.toString() ?? '0 Day',
      goalId: _int(json['goal_id']),
      dietaryRequirementsId: _int(json['dietary_requirements_id']),
      activityId: _int(json['user_active_id']),
      genderId: _genderId(json['gender']),
      femaleSpecificPlan: _int(json['female_specific_plan']),
      age: _int(json['age']),
      height: _int(json['height']),
      weekGoals: json['weekgoals']?.toString(),
      initialWeight: _number(json['initial_weight']),
      currentWeight: _number(json['current_weight']),
      goalWeight: _number(json['goal_weight']),
      progressValue: _number(json['value']),
      progressType: json['type']?.toString() ?? 'No change',
    );
  }

  String get progressUnit {
    switch (progressType.toLowerCase()) {
      case 'weight lost':
        return 'Kgs lost';
      case 'weight gain':
        return 'Kgs gained';
      default:
        return 'No change';
    }
  }
}

int? _int(dynamic value) => int.tryParse(value?.toString() ?? '');

int? _genderId(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  switch (value?.toString().toLowerCase()) {
    case 'm':
      return 1;
    case 'f':
      return 2;
    default:
      return null;
  }
}

double _number(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
