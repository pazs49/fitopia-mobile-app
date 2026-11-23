class AnalyticsPoint {
  final String date;
  final String label;
  final double? value;

  const AnalyticsPoint({
    required this.date,
    required this.label,
    required this.value,
  });

  factory AnalyticsPoint.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'];
    return AnalyticsPoint(
      date: json['date']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: rawValue is num
          ? rawValue.toDouble()
          : double.tryParse(rawValue?.toString() ?? ''),
    );
  }
}

class AnalyticsPhoto {
  final int id;
  final String imageUrl;
  final DateTime? capturedAt;

  const AnalyticsPhoto({
    required this.id,
    required this.imageUrl,
    required this.capturedAt,
  });

  factory AnalyticsPhoto.fromJson(Map<String, dynamic> json) {
    return AnalyticsPhoto(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      capturedAt: DateTime.tryParse(json['captured_at']?.toString() ?? ''),
    );
  }
}

class AnalyticsData {
  final String metric;
  final String unit;
  final int periodDays;
  final List<AnalyticsPoint> points;
  final List<AnalyticsPhoto> progressPhotos;

  const AnalyticsData({
    required this.metric,
    required this.unit,
    required this.periodDays,
    required this.points,
    required this.progressPhotos,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final rawPhotos = json['progress_photos'];

    return AnalyticsData(
      metric: json['metric']?.toString() ?? 'weight',
      unit: json['unit']?.toString() ?? '',
      periodDays: int.tryParse(json['period_days']?.toString() ?? '') ?? 7,
      points: rawPoints is List
          ? rawPoints
              .whereType<Map>()
              .map((point) =>
                  AnalyticsPoint.fromJson(Map<String, dynamic>.from(point)))
              .toList()
          : const <AnalyticsPoint>[],
      progressPhotos: rawPhotos is List
          ? rawPhotos
              .whereType<Map>()
              .map((photo) =>
                  AnalyticsPhoto.fromJson(Map<String, dynamic>.from(photo)))
              .toList()
          : const <AnalyticsPhoto>[],
    );
  }
}
