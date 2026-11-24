class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? image;
  final String createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.image,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: (data['subject'] ?? data['title'] ?? 'Fitopia').toString(),
      message: (data['message'] ?? data['body'] ?? '').toString(),
      type: data['type']?.toString() ?? '',
      image: json['image']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      isRead: json['read_at'] != null,
    );
  }
}
