import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/notifications_controller.dart';
import '../../../core/const/app_text.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: AppText(
          text: 'Notifications',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.blue),
            onPressed: () => controller.markAllAsRead(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                AppText(
                  text: 'No notifications yet',
                  fontSize: 16,
                  color: Colors.grey[600]!,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshNotifications();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationTile(notification);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    return Dismissible(
      key: Key(notification['id'].toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) =>
          controller.deleteNotification(notification['id']),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification['type']).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: _getNotificationColor(notification['type']),
            size: 28,
          ),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight:
                notification['read'] ? FontWeight.normal : FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'],
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification['time'],
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => controller.onNotificationTap(notification),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'PODCAST_INVITE':
        return AppColors.purple;
      case 'MESSAGE':
        return AppColors.blue;
      case 'LIKE':
        return Colors.pinkAccent;
      case 'COMMENT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'PODCAST_INVITE':
        return Icons.mic;
      case 'MESSAGE':
        return Icons.chat_bubble_outline;
      case 'LIKE':
        return Icons.favorite_border;
      case 'COMMENT':
        return Icons.comment_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}
