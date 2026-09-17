import 'package:flutter/material.dart';
import '../managers/notification_manager.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final notificationManager = NotificationManager();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    notificationManager.fetchFromApi(isInitial: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!notificationManager.isLoading && !notificationManager.isFetchingMore && notificationManager.hasMore) {
        notificationManager.fetchFromApi(isInitial: false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                        Text('No notifications yet',
                            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Text('Pull down to refresh', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notificationManager.fetchFromApi(isInitial: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length + (notificationManager.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  return notificationManager.isFetchingMore 
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
                }
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
                            child: (item['senderImage'] != null && item['senderImage']!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item['senderImage']!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Text(
                                        item['icon'] ?? '👥',
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  )
                                : Text(
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
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                if (item['type'] == 'friend_request' || (item['type'] ?? '').contains('friend')) ...[
                                  const SizedBox(height: 10),
                                  if (item['status'] == 'accepted')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 14),
                                          SizedBox(width: 4),
                                          Text('Accepted', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            final success = await notificationManager.acceptFriendRequest(item['id']!);
                                            if (context.mounted && success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Friend request accepted!'), backgroundColor: Colors.green),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () async {
                                            await notificationManager.rejectFriendRequest(item['id']!);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Friend request declined.')),
                                              );
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: colorScheme.onSurfaceVariant,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Decline', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  item['time'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
