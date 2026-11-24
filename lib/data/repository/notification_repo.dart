import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/notification_model.dart';

class NotificationRepo {
  final ApiClient apiClient;

  NotificationRepo({required this.apiClient});

  Future<NotificationPage> getNotifications({int page = 1}) async {
    final response = await apiClient.postAuthenticatedData(
      'api/notification-list',
      {'page': page, 'limit': 30},
    );
    final rawItems = response['notification_data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) =>
                AppNotification.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <AppNotification>[];
    return NotificationPage(
      items: items,
      unreadCount: int.tryParse(
            response['all_unread_count']?.toString() ?? '',
          ) ??
          0,
    );
  }

  Future<void> markAllAsRead() async {
    await apiClient.postAuthenticatedData(
      'api/notification-list',
      {'type': 'markas_read'},
    );
  }
}

class NotificationPage {
  final List<AppNotification> items;
  final int unreadCount;

  const NotificationPage({
    required this.items,
    required this.unreadCount,
  });
}
