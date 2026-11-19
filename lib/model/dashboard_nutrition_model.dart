class DashboardCalories {
  final double dailyAverage;
  final double goal;
  final double remaining;

  const DashboardCalories({
    required this.dailyAverage,
    required this.goal,
    required this.remaining,
  });

  factory DashboardCalories.fromJson(Map<String, dynamic> json) {
    return DashboardCalories(
      dailyAverage: _number(json['daily_average']),
      goal: _number(json['goal']),
      remaining: _number(json['remaining']),
    );
  }
}

class DashboardMacro {
  final String name;
  final double amount;
  final double goal;
  final double remaining;

  const DashboardMacro({
    required this.name,
    required this.amount,
    required this.goal,
    required this.remaining,
  });

  factory DashboardMacro.fromJson(Map<String, dynamic> json) {
    return DashboardMacro(
      name: json['name'] is String ? json['name'] as String : '',
      amount: _number(json['avg'] ?? json['taken']),
      goal: _number(json['goal']),
      remaining: _number(json['left']),
    );
  }
}

class DashboardWeeklyCalories {
  final List<double> values;
  final List<String> labels;

  const DashboardWeeklyCalories({
    required this.values,
    required this.labels,
  });

  factory DashboardWeeklyCalories.fromJson(Map<String, dynamic> json) {
    final rawIntake = json['intake_by_day'];
    final entries = <DateTime, double>{};

    if (rawIntake is Map) {
      for (final entry in rawIntake.entries) {
        final date = DateTime.tryParse(entry.key.toString());
        if (date == null || entry.value is! Map) {
          continue;
        }

        final categories = Map<dynamic, dynamic>.from(entry.value as Map);
        final total = categories.values.fold<double>(
          0,
          (sum, value) => sum + _number(value),
        );
        entries[DateTime(date.year, date.month, date.day)] = total;
      }
    }

    final today = DateTime.now();
    final sunday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday % 7),
    );
    final dates = List<DateTime>.generate(
      7,
      (index) => sunday.add(Duration(days: index)),
    );
    final values = dates.map((date) => entries[date] ?? 0).toList();
    final labels = dates.map(_weekdayLabel).toList();

    return DashboardWeeklyCalories(values: values, labels: labels);
  }
}

String _weekdayLabel(DateTime date) {
  const labels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  return labels[date.weekday % 7];
}

double _number(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
