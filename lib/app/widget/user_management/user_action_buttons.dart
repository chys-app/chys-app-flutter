import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/user_management/controllers/user_management_controller.dart';

class UserActionButtons extends StatelessWidget {
  final String userId;
  final String userName;
  final bool isBlocked;
  final bool showBlockButton;
  final bool showReportButton;
  final VoidCallback? onBlockChanged;

  const UserActionButtons({
    Key? key,
    required this.userId,
    required this.userName,
    this.isBlocked = false,
    this.showBlockButton = true,
    this.showReportButton = true,
    this.onBlockChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserManagementController>();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'block':
            if (isBlocked) {
              controller.showUnblockUserDialog(userId, userName);
            } else {
              controller.showBlockUserDialog(userId, userName);
            }
            // Call callback if provided
            onBlockChanged?.call();
            break;
          case 'report':
            controller.showReportUserDialog(userId, userName);
            break;
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        // Block/Unblock button
        if (showBlockButton) {
          items.add(
            PopupMenuItem<String>(
              value: 'block',
              child: Row(
                children: [
                  Icon(
                    isBlocked ? Icons.lock_open : Icons.block,
                    color: isBlocked ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBlocked ? 'Unblock' : 'Block',
                    style: TextStyle(
                      color: isBlocked ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Report button
        if (showReportButton) {
          items.add(
            PopupMenuItem<String>(
              value: 'report',
              child: const Row(
                children: [
                  Icon(
                    Icons.report,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}

class UserActionSheet extends StatelessWidget {
  final String userId;
  final String userName;
  final bool isBlocked;
  final bool showBlockButton;
  final bool showReportButton;
  final VoidCallback? onBlockChanged;

  const UserActionSheet({
    Key? key,
    required this.userId,
    required this.userName,
    this.isBlocked = false,
    this.showBlockButton = true,
    this.showReportButton = true,
    this.onBlockChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserManagementController>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.person, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Actions for $userName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Action buttons
          if (showBlockButton) ...[
            ListTile(
              leading: Icon(
                isBlocked ? Icons.lock_open : Icons.block,
                color: isBlocked ? Colors.green : Colors.red,
              ),
              title: Text(
                isBlocked ? 'Unblock User' : 'Block User',
                style: TextStyle(
                  color: isBlocked ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                isBlocked 
                  ? 'Allow posts and interactions from this user'
                  : 'Hide posts and prevent interactions with this user',
              ),
              onTap: () {
                Get.back();
                if (isBlocked) {
                  controller.showUnblockUserDialog(userId, userName);
                } else {
                  controller.showBlockUserDialog(userId, userName);
                }
                onBlockChanged?.call();
              },
            ),
            const Divider(),
          ],
          
          if (showReportButton) ...[
            ListTile(
              leading: const Icon(
                Icons.report,
                color: Colors.orange,
              ),
              title: const Text(
                'Report User',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Report inappropriate behavior or content',
              ),
              onTap: () {
                Get.back();
                controller.showReportUserDialog(userId, userName);
              },
            ),
            const Divider(),
          ],
          
          // Cancel button
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.grey),
            title: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }

  /// Show the action sheet
  static void show({
    required String userId,
    required String userName,
    bool isBlocked = false,
    bool showBlockButton = true,
    bool showReportButton = true,
    VoidCallback? onBlockChanged,
  }) {
    Get.bottomSheet(
      UserActionSheet(
        userId: userId,
        userName: userName,
        isBlocked: isBlocked,
        showBlockButton: showBlockButton,
        showReportButton: showReportButton,
        onBlockChanged: onBlockChanged,
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }
} 