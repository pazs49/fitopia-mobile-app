class WorkoutDetail {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String level;
  final String type;
  final String duration;
  final List<String> equipment;
  final List<WorkoutExercise> exercises;

  const WorkoutDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.level,
    required this.type,
    required this.duration,
    required this.equipment,
    required this.exercises,
  });

  factory WorkoutDetail.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return WorkoutDetail(
      id: _int(json['id'] ?? json['workout_id']),
      title: _text(json['title'], 'Workout'),
      description: _text(json['description'] ?? json['Workout_desc'], ''),
      imageUrl: _text(json['workout_image'] ?? json['image'], ''),
      level: _text(json['level_title'] ?? json['level'], ''),
      type: _text(json['workout_type_title'] ?? json['type'], ''),
      duration: _text(json['total_duration'] ?? json['duration'], ''),
      equipment: _strings(json['equipments'] ?? json['equipment']),
      exercises: rawExercises is List
          ? rawExercises
              .whereType<Map>()
              .map((item) =>
                  WorkoutExercise.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const <WorkoutExercise>[],
    );
  }
}

class WorkoutExercise {
  final int? id;
  final String title;
  final String imageUrl;
  final String duration;
  final String sets;
  final String reps;
  final String equipment;

  const WorkoutExercise({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.sets,
    required this.reps,
    required this.equipment,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'];
    return WorkoutExercise(
      id: int.tryParse(json['id']?.toString() ?? ''),
      title: _text(json['title'] ?? json['exercise_title'], 'Exercise'),
      imageUrl: _text(json['exercise_image'] ?? json['image'], ''),
      duration: _text(json['duration'], ''),
      sets: _setValue(rawSets, 'sets'),
      reps: _setValue(rawSets, 'reps'),
      equipment: _text(json['equipment'] ?? json['equipment_title'], ''),
    );
  }
}

String _text(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

List<String> _strings(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item is Map ? item['title'] : item)
        .map((item) => _text(item))
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = _text(value);
  return text.isEmpty ? const [] : [text];
}

String _setValue(dynamic value, String key) {
  if (value is Map) {
    final item = value[key] ?? value[key == 'sets' ? 'set' : 'rep'];
    return _text(item);
  }
  if (value is List && value.isNotEmpty && value.first is Map) {
    final values = value
        .whereType<Map>()
        .map((item) => _text(item[key] ?? item[key == 'sets' ? 'set' : 'rep']))
        .where((item) => item.isNotEmpty)
        .toSet();
    return values.join(', ');
  }
  return '';
}
