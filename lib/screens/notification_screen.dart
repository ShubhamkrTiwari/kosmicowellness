import 'package:flutter/material.dart';
import '../managers/notification_manager.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    notificationManager.fetchFromApi();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ListenableBuilder(
            listenable: notificationManager,
            builder: (context, _) {
              if (notificationManager.notifications.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => notificationManager.clearAll(),
                child: Text(
                  'Clear All',
                  style: TextStyle(color: colorScheme.secondary),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: notificationManager,
        builder: (context, _) {
          final notifications = notificationManager.notifications;

          if (notificationManager.isLoading && notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => notificationManager.fetchFromApi(),
              child: Stack(
                children: [
                  ListView(),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 80, color: colorScheme.primary.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text('No notifications yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Pull down to refresh', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notificationManager.fetchFromApi(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final bool isUnread = item['isRead'] == 'false';

                return Dismissible(
                  key: Key(item['id']!),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    notificationManager.removeNotification(item['id']!);
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (isUnread) {
                        notificationManager.markAsRead(item['id']!);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUnread ? Colors.white : colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isUnread
                              ? colorScheme.primary.withOpacity(0.2)
                              : colorScheme.primary.withOpacity(0.05),
                          width: isUnread ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item['icon'] ?? '🔔',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item['title'] ?? 'Notification',
                                        style: TextStyle(
                                          fontWeight:
                                              isUnread ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 16,
                                          color: colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isUnread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['time'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
