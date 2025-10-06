import 'dart:developer';

import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/utils/app_size.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ home/widget/floating_action_button.dart';
import '../../../widget/shimmer/lottie_animation.dart';
import '../../../widget/user_management/user_action_buttons.dart';
import '../../map/controllers/map_controller.dart';
import '../../user_management/controllers/user_management_controller.dart';
import '../controllers/chat_controller.dart';

class ChatListView extends GetView<ChatController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<MapController>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),

            // Search Bar
            _buildSearchBar(),

            // Chat List
            Expanded(
              child: _buildChatList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(controller: mapController),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: const Center(
        child: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF262626), // Instagram's primary text color
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA), // Instagram's background color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDBDBDB)), // Instagram's border color
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(
            color: Color(0xFF8E8E93), // Instagram's secondary text color
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF8E8E93), // Instagram's secondary text color
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF262626), // Instagram's primary text color
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Obx(() {
      log("📋 Chat list - Loading: ${controller.isLoading.value}");
      log("📋 Chat list - Conversations count: ${controller.conversations.length}");
      log("📋 Chat list - Filtered conversations count: ${controller.filteredConversations}");

      if (controller.isLoading.value) {
        log("📋 Chat list - Showing loading state");
        return _buildLoadingState();
      } else if (controller.filteredConversations.isEmpty) {
        log("📋 Chat list - Showing empty state");
        return _buildEmptyState();
      }

      log("📋 Chat list - Showing ${controller.filteredConversations.length} conversations");
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredConversations.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Colors.transparent,
        ),
        itemBuilder: (context, index) {
          final chat = controller.filteredConversations[index];
          log("📋 Chat list - Building tile for index $index: $chat");
          return _buildChatTile(chat);
        },
      );
    });
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Shimmer avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0), // Instagram's loading color
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shimmer name
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFF0F0F0), // Instagram's loading color
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shimmer message
                    Container(
                      height: 14,
                      width: 200,
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFF0F0F0), // Instagram's loading color
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomLottieAnimation(jsonPath: AppImages.emptyChat),
          const SizedBox(height: 24),
          Text(
            controller.searchController.text.isEmpty
                ? 'No messages yet'
                : 'No conversations found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF262626), // Instagram's primary text color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchController.text.isEmpty
                ? 'Start a conversation with your friends'
                : 'Try searching with a different name',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93), // Instagram's secondary text color
            ),
          ),
          if (controller.searchController.text.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // New message functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF0095F6), // Instagram's blue color
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Start a Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    // Debug: Print chat data to understand the structure
    log("💬 Chat tile data: $chat");

    // Handle different possible user data structures
    Map<String, dynamic> user = {};
    if (chat['user'] != null && chat['user'] is Map) {
      user = chat['user'] as Map<String, dynamic>;
      log("👤 User data from 'user' field: $user");
    } else if (chat['sender'] != null && chat['sender'] is Map) {
      user = chat['sender'] as Map<String, dynamic>;
      log("👤 User data from 'sender' field: $user");
    } else if (chat['receiver'] != null && chat['receiver'] is Map) {
      user = chat['receiver'] as Map<String, dynamic>;
      log("👤 User data from 'receiver' field: $user");
    }

    // If no user data found, try to get the other user (not current user)
    if (user.isEmpty) {
      final currentUserId = controller.profileController.userCurrentId.value;
      log("🔍 Current user ID: $currentUserId");

      if (chat['sender'] != null && chat['sender'] is Map) {
        final sender = chat['sender'] as Map<String, dynamic>;
        if (sender['_id']?.toString() != currentUserId) {
          user = sender;
          log("👤 Using sender as other user: $user");
        }
      }

      if (user.isEmpty && chat['receiver'] != null && chat['receiver'] is Map) {
        final receiver = chat['receiver'] as Map<String, dynamic>;
        if (receiver['_id']?.toString() != currentUserId) {
          user = receiver;
          log("👤 Using receiver as other user: $user");
        }
      }
    }

    // Debug: Check all possible profile picture fields
    log("🔍 Checking profile picture fields in user data:");
    log("🔍 profilePic: ${user['profilePic']}");
    log("🔍 profile_pic: ${user['profile_pic']}");
    log("🔍 profilePicture: ${user['profilePicture']}");
    log("🔍 profile_picture: ${user['profile_picture']}");
    log("🔍 profile_picture: ${user['profile_picture']}");

    // Also check if profilePic is in the main chat object
    log("🔍 Checking profile picture fields in main chat object:");
    log("🔍 chat['profilePic']: ${chat['profilePic']}");
    log("🔍 chat['profile_pic']: ${chat['profile_pic']}");
    log("🔍 chat['profilePicture']: ${chat['profilePicture']}");
    log("🔍 chat['profile_picture']: ${chat['profile_picture']}");

    final String name = user['name'] ?? 'Unknown';
    final String lastMessage = chat["lastMessage"] ?? chat['message'] ?? '';
    final DateTime? timestamp = DateTime.tryParse(chat['timestamp'] ?? '');
    final bool isOnline = user['isOnline'] ?? false;
    final bool hasUnreadMessages =
        chat['unreadCount'] != null && chat['unreadCount'] > 0;
    final int unreadCount = chat['unreadCount'] ?? 0;
    String formatLastMessage(String message) {
      const urlPattern = r'^(https?:\/\/[^\s]+)$';
      final isUrl =
          RegExp(urlPattern, caseSensitive: false).hasMatch(message.trim());

      if (isUrl) {
        return "Photo";
      }
      return message;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFF0F0F0)), // Instagram's subtle border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.onConversationTap(chat),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOnline ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildUserAvatar(user),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Chat content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnreadMessages
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: hasUnreadMessages
                                    ? Colors.black
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnreadMessages
                                  ? Colors.blue[600]
                                  : Colors.grey.shade600,
                              fontWeight: hasUnreadMessages
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatLastMessage(lastMessage),
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnreadMessages
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                                fontWeight: hasUnreadMessages
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnreadMessages) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          // User action buttons
                          FutureBuilder<bool>(
                            future: Get.find<UserManagementController>()
                                .isUserBlocked(user['_id'] ?? user['id'] ?? ''),
                            builder: (context, snapshot) {
                              final isBlocked = snapshot.data ?? false;
                              return UserActionButtons(
                                userId: user['_id'] ?? user['id'] ?? '',
                                userName: name,
                                isBlocked: isBlocked,
                                showBlockButton: true,
                                showReportButton: true,
                                onBlockChanged: () {
                                  // Refresh the chat list if needed
                                  controller.refreshConversations();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    // Debug: Print user data to see the structure
    log("🔍 User data for avatar: $user");

    // Try different possible field names for profile picture
    final profilePic = user['profilePic'] ??
        user['profile_pic'] ??
        user['profilePicture'] ??
        user['profile_picture'];
    final userName = user['name'] ?? user['username'] ?? 'User';

    log("🔍 Profile pic: $profilePic, User name: $userName");
    log("🔍 Profile pic type: ${profilePic.runtimeType}");
    log("🔍 Profile pic length: ${profilePic?.toString().length ?? 0}");

    if (profilePic != null &&
        profilePic.toString().isNotEmpty &&
        profilePic != 'null') {
      log("✅ Loading profile image: $profilePic");
      return ClipOval(
        child: Image.network(
          profilePic,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            log("❌ Error loading profile image: $error");
            log("❌ Stack trace: $stackTrace");
            return _buildInitialsAvatar(userName);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildInitialsAvatar(userName);
          },
        ),
      );
    } else {
      log("📝 Using initials avatar for user: $userName");
      return _buildInitialsAvatar(userName);
    }
  }

  Widget _buildInitialsAvatar(String userName) {
    final initials = getUserInitials(userName);
    final color = getAvatarColor(initials);

    return Container(
      color: color,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
