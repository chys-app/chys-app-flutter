import 'package:get/get.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:chys/app/services/date_time_service.dart';

class NotificationsController extends GetxController {
  final isLoading = false.obs;
  final notifications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      isLoading.value = true;
      final api = ApiClient();
      final response = await api.get('/users/notifications');
      // API returns: { success, count, notifications: [ ... ] }
      if (response != null && response['success'] == true && response['notifications'] != null) {
        notifications.value = (response['notifications'] as List)
            .map<Map<String, dynamic>>((n) => {
                  'id': n['_id'],
                  'type': n['type']?.toString().toUpperCase() ?? '',
                  'title': n['title'] ?? '',
                  'message': n['message'] ?? '',
                  'time': _formatNotificationTime(n['createdAt']),
                  'read': n['read'] ?? false, // fallback if API adds this
                  'raw': n, // keep original for advanced use
                })
            .toList();
      } else {
        notifications.value = [];
      }
    } catch (e) {
      print('Error loading notifications: $e');
      notifications.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  String _formatNotificationTime(dynamic isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString.toString();
    }
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      notification['read'] = true;
    }
    notifications.refresh();
  }

  void deleteNotification(dynamic id) {
    notifications.removeWhere((notification) => notification['id'] == id);
  }

  void onNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    final index = notifications.indexWhere((n) => n['id'] == notification['id']);
    if (index != -1) {
      notifications[index]['read'] = true;
      notifications.refresh();
    }
    // Handle notification tap based on type
    switch (notification['type']) {
      case 'PODCAST_INVITE':
        // TODO: Navigate to podcast invite details
        break;
      case 'MESSAGE':
        // TODO: Navigate to chat
        break;
      case 'LIKE':
        // TODO: Navigate to liked post
        break;
      case 'COMMENT':
        // TODO: Navigate to comment details
        break;
      default:
        // Handle other types
        break;
    }
  }

  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }
} 