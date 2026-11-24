import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/notification_repo.dart';
import 'package:fitopia/model/notification_model.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final NotificationRepo _repo = NotificationRepo(apiClient: ApiClient());
  late Future<NotificationPage> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<NotificationPage> _loadNotifications() async {
    final page = await _repo.getNotifications();
    if (page.unreadCount > 0) {
      await _repo.markAllAsRead();
    }
    return page;
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = _loadNotifications();
    });
    await _notificationsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<NotificationPage>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Could not load notifications.';
            return _MessageState(
              message: message,
              action: _refresh,
              actionLabel: 'Retry',
            );
          }
          final items = snapshot.data?.items ?? <AppNotification>[];
          if (items.isEmpty) {
            return const _MessageState(message: 'You have no notifications.');
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _NotificationTile(
                notification: items[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            notification.type == 'push_notification'
                ? Icons.campaign_outlined
                : Icons.notifications_none,
          ),
        ),
        title: Text(notification.title),
        subtitle: Text(notification.message),
        isThreeLine: true,
        trailing: Text(
          notification.createdAt,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  const _MessageState({
    required this.message,
    this.action,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (action != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: action, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
