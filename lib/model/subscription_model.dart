class SubscriptionModel {
  final int id;
  final String name;
  final int duration;
  final String durationUnit;
  final double price;
  final String description;
  final double yearlyPrice;

  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.duration,
    required this.durationUnit,
    required this.price,
    required this.description,
    required this.yearlyPrice,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final price = _toDouble(json['price']);
    return SubscriptionModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Package',
      duration: _toInt(json['duration']),
      durationUnit: json['duration_unit']?.toString() ?? '',
      price: price,
      description: json['description']?.toString() ?? '',
      yearlyPrice: _toDouble(json['yearly_price'], fallback: price * 12),
    );
  }

  String get title1 => 'USD \$${price.toStringAsFixed(2)} / $durationUnit';

  String get title2 => 'Yearly: USD \$${yearlyPrice.toStringAsFixed(2)}';

  String get subtitle {
    if (description.isNotEmpty) {
      return description;
    }
    return '$duration $durationUnit';
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
