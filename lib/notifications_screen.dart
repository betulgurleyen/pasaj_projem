import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      if (mounted)
        setState(() {
          _notifications = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_bag;
      case 'order_placed':
        return Icons.check_circle;
      case 'order_processing':
        return Icons.hourglass_top;
      case 'order_shipped':
        return Icons.local_shipping;
      case 'order_delivered':
        return Icons.done_all;
      case 'order_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'new_order':
        return Colors.blue;
      case 'order_placed':
        return Colors.green;
      case 'order_processing':
        return Colors.orange;
      case 'order_shipped':
        return AppStyles.accentPeach;
      case 'order_delivered':
        return AppStyles.primaryGreen;
      case 'order_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: () async {
                await ApiService.markAllNotificationsRead();
                _loadNotifications();
              },
              child: const Text(
                'Tümünü Okundu Yap',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz bildirim yok.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  final isRead = notif['is_read'] == true;
                  final type = notif['type']?.toString();

                  return Card(
                    color: isRead
                        ? Colors.white
                        : AppStyles.accentPeach.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isRead
                          ? BorderSide.none
                          : BorderSide(
                              color: AppStyles.accentPeach.withOpacity(0.3),
                            ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColor(type).withOpacity(0.15),
                        child: Icon(
                          _getIcon(type),
                          color: _getColor(type),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notif['title']?.toString() ?? '',
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif['body']?.toString() ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(notif['created_at']?.toString() ?? ''),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppStyles.accentPeach,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () async {
                        if (!isRead) {
                          await ApiService.markNotificationRead(notif['id']);
                          _loadNotifications();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
