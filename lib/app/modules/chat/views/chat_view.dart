import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chys/app/core/utils/app_size.dart';

import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
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
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEFEFEF), width: 0.5), // Instagram's light border
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
        color: const Color(0xFFFAFAFA), // Instagram's light background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)), // Instagram's light border
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(
            color: Color(0xFFA8A8A8), // Instagram's lighter secondary text color
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFA8A8A8), // Instagram's lighter secondary text color
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      if (controller.isLoading.value) {
        return _buildLoadingState();
      } else if (controller.filteredConversations.isEmpty) {
        return _buildEmptyState();
      }
      
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredConversations.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Colors.transparent,
        ),
        itemBuilder: (context, index) {
          final conversation = controller.filteredConversations[index];
          return _buildConversationTile(conversation);
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
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F8F8), // Instagram's lighter loading color
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
                        color: const Color(0xFFF8F8F8), // Instagram's lighter loading color
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shimmer message
                    Container(
                      height: 14,
                      width: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8), // Instagram's lighter loading color
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
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: const Color(0xFF8E8E93), // Instagram's secondary text color
          ),
          const SizedBox(height: 24),
          Text(
            controller.searchController.text.isEmpty 
                ? 'No conversations yet'
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
              color: Color(0xFFA8A8A8), // Instagram's lighter secondary text color
            ),
          ),
          if (controller.searchController.text.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // New conversation functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095F6), // Instagram's blue color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Start a Conversation',
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

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final user = conversation['user'] ?? {};
    final String name = user['name'] ?? 'Unknown';
    final String lastMessage = conversation['lastMessage'] ?? '';
    final DateTime? timestamp = DateTime.tryParse(conversation['timestamp'] ?? '');
    final bool isOnline = user['isOnline'] ?? false;
    final bool hasUnreadMessages = conversation['unreadCount'] != null && conversation['unreadCount'] > 0;
    final int unreadCount = conversation['unreadCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF8F8F8)), // Instagram's very light border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.onConversationTap(conversation),
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
                          color: isOnline ? const Color(0xFF00C851) : const Color(0xFFEFEFEF), // Instagram's online indicator color
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
                            color: const Color(0xFF00C851), // Instagram's online indicator color
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Conversation content
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
                                fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w500,
                                color: hasUnreadMessages ? const Color(0xFF262626) : const Color(0xFF262626), // Instagram's primary text color
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnreadMessages ? const Color(0xFF0095F6) : const Color(0xFFA8A8A8), // Instagram's blue and lighter secondary text colors
                              fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnreadMessages ? const Color(0xFF262626) : const Color(0xFFA8A8A8), // Instagram's primary and lighter secondary text colors
                                fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnreadMessages) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0095F6), // Instagram's blue color
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
    final profilePic = user['profilePic'];
    final userName = user['name'] ?? 'User';
    
    if (profilePic != null && profilePic.toString().isNotEmpty && profilePic != 'null') {
      return Image.network(
        profilePic,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar(userName);
        },
      );
    } else {
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
