import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:chys/app/services/date_time_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/chat_controller.dart';

class ChatDetailView extends GetView<ChatController> {
  const ChatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> chatUser = Get.arguments;
    log("Chat user is $chatUser");
    log("🔍 Chat user profile pic: ${chatUser['profilePic']}");

    controller.receiverId.value = chatUser['id'];
    
    // Debug: Check current user ID at initialization
    log("🔍 Chat Detail View - Current user ID: ${controller.profileController.userCurrentId.value}");
    log("🔍 Chat Detail View - Receiver ID: ${controller.receiverId.value}");
    
    // Always ensure current user ID is loaded
    log("🔄 Ensuring current user ID is loaded...");
    controller.ensureCurrentUserIdLoaded();
    log("🔍 After loading - Current user ID: ${controller.profileController.userCurrentId.value}");
    
    controller.loadChat();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Instagram's light background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4), // shadow position
              ),
            ],
          ),
          child: SafeArea(
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0, // keep AppBar itself flat
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF262626)), // Instagram's primary text color
                onPressed: () => Get.back(),
              ),
              title: Row(
                children: [
                  _buildUserAvatar(chatUser),
                  SizedBox(width: AppSize.h2),
                  Text(
                    chatUser['name'],
                    style: const TextStyle(
                      color: Color(0xFF262626), // Instagram's primary text color
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isChatLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Container(
            color: const Color(0xFFFAFAFA), // Instagram's light background
            child: Column(
              children: [
                Expanded(
                  child: controller.messages.isEmpty
                      ? const Center(child: Text("No messages yet"))
                      : ListView.builder(
                          controller: controller.scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 20),
                          itemCount: controller.messages.length,
                          itemBuilder: (context, index) {
                            final message = controller.messages[index];
                            
                            // Debug: Print message data to understand the structure
                            log("📨 Message $index: $message");
                            log("👤 Current user ID: ${controller.profileController.userCurrentId.value}");
                            
                            // Use the pre-processed senderId field (added by loadChat method)
                            String? senderId = message['senderId']?.toString();
                            log("📤 Message senderId: $senderId");
                            
                            // Fallback to nested structure if senderId is not available
                            if (senderId == null || senderId == 'null') {
                              if (message['sender'] != null && message['sender'] is Map) {
                                senderId = message['sender']['_id']?.toString();
                                log("📤 Message sender from nested structure: $senderId");
                              }
                            }
                            
                            log("📤 Final sender ID: $senderId");
                            log("📤 Sender ID type: ${senderId.runtimeType}");
                            
                            // More detailed comparison
                            final currentUserId = controller.profileController.userCurrentId.value.toString();
                            log("📤 Sender ID (string): '$senderId'");
                            log("👤 Current user ID (string): '$currentUserId'");
                            log("📤 Length comparison: ${senderId?.length ?? 0} vs ${currentUserId.length}");
                            
                            final isMe = senderId == currentUserId;
                            log("✅ Is message from me: $isMe");
                            log("✅ Direct comparison: '$senderId' == '$currentUserId' = ${senderId == currentUserId}");
                            
                            // Get the appropriate user data for avatar
                            Map<String, dynamic>? messageUser;
                            if (isMe) {
                              // For sent messages, use sender data
                              if (message['sender'] != null && message['sender'] is Map) {
                                messageUser = message['sender'] as Map<String, dynamic>;
                              }
                            } else {
                              // For received messages, use receiver data
                              if (message['receiver'] != null && message['receiver'] is Map) {
                                messageUser = message['receiver'] as Map<String, dynamic>;
                              }
                            }
                            
                            // Process media data for display
                            Map<String, dynamic>? mediaData;
                            if (message['media'] is Map<String, dynamic>) {
                              mediaData = message['media'] as Map<String, dynamic>;
                              log("📨 Media is Map: $mediaData");
                            } else if (message['media'] is String && (message['media'] as String).isNotEmpty) {
                              mediaData = {'url': message['media'] as String, 'type': 'image'};
                              log("📨 Media is String, converted to Map: $mediaData");
                            } else {
                              log("📨 No media data found");
                            }

                            // Normalize and clean text (treat zero-width and whitespace as empty)
                            final rawText = (message['message'] ?? '').toString();
                            var cleanedText = rawText.replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '').trim();

                            // If no media and text itself is a URL, treat as image media
                            if (mediaData == null && _isLikelyUrl(cleanedText)) {
                              log("🖼️ Message text is a URL, rendering as image: $cleanedText");
                              mediaData = {'url': cleanedText, 'type': 'image'};
                              cleanedText = '';
                            }

                            final hasText = cleanedText.isNotEmpty;

                            // If no text and no media, do not render a bubble
                            if (!hasText && mediaData == null) {
                              log("🧹 Skipping empty bubble (no text, no media)");
                              return const SizedBox.shrink();
                            }
                            
                            return _buildMessage(
                              cleanedText,
                              DateTimeService.formatTime(message['timestamp']),
                              isMe: isMe,
                              chatUser: messageUser ?? chatUser,
                              media: mediaData,
                            );
                          },
                        ),
                ),
                // ✅ Always show message input at bottom
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Typing indicator (can be expanded later)
                      const SizedBox(height: 4),
                      // Message input row
                      Row(
                        children: [
                          // Media upload button
                          Obx(() => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: controller.isUploadingMedia.value
                                      ? const Color(0xFFF0F0F0) // Instagram's loading color
                                      : const Color(0xFFFAFAFA), // Instagram's light background
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: controller.isUploadingMedia.value
                                          ? const Color(0xFFDBDBDB) // Instagram's border color
                                          : const Color(0xFFEFEFEF), // Instagram's light border
                                      width: 1),
                                ),
                                child: controller.isUploadingMedia.value
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.blue),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.attach_file,
                                          color: Color(0xFF8E8E93), // Instagram's secondary text color
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            controller.pickAndUploadMedia(),
                                        iconSize: 20,
                                        splashRadius: 24,
                                      ),
                              )),
                          const SizedBox(width: 8),
                          // Message input field
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA), // Instagram's light background
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: const Color(0xFFEFEFEF)), // Instagram's light border
                              ),
                              child: TextField(
                                controller: controller.messageController,
                                decoration: const InputDecoration(
                                  hintText: "Type a message...",
                                  hintStyle: TextStyle(
                                    color: Color(0xFF8E8E93), // Instagram's secondary text color
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF262626), // Instagram's primary text color
                                ),
                                onSubmitted: (text) {
                                  if (text.trim().isNotEmpty) {
                                    controller.sendPrivateMessage(controller
                                            .profileController
                                            .userCurrentId
                                            .value);
                                  }
                                },
                                textInputAction: TextInputAction.send,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Send button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: controller.messageController.text
                                      .trim()
                                      .isNotEmpty
                                  ? const Color(0xFF0095F6) // Instagram's blue
                                  : const Color(0xFFF0F0F0), // Instagram's disabled color
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.send,
                                color: controller.messageController.text
                                        .trim()
                                        .isNotEmpty
                                    ? Colors.white
                                    : const Color(0xFF8E8E93), // Instagram's secondary text color
                                size: 20,
                              ),
                              onPressed: () {
                                log("🚀 Send button pressed");
                                final msg = controller.messageController.text.trim();
                                log("📝 Message to send: '$msg'");
                                log("👤 Current user ID when sending: '${controller.profileController.userCurrentId.value}'");
                                log("👤 Current user ID type: ${controller.profileController.userCurrentId.value.runtimeType}");
                                
                                if (controller.profileController.userCurrentId.value.isEmpty) {
                                  log("❌ ERROR: Current user ID is empty!");
                                } else {
                                  controller.sendPrivateMessage(
                                    controller.profileController.userCurrentId.value,
                                  );
                                }
                              },
                              iconSize: 20,
                              splashRadius: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }

  Widget _buildMessage(String text, String time,
      {required bool isMe, Map<String, dynamic>? chatUser, Map<String, dynamic>? media}) {
    // Treat zero-width whitespace as empty
    final cleanedText = text.replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '').trim();
    final isImage = media != null && (media['type'] == 'image' || (media['url']?.toString().toLowerCase().contains('image') ?? false));

    return Padding(
      padding: EdgeInsets.only(
        bottom: 18,
        left: isMe ? 40 : 0,
        right: isMe ? 0 : 40,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildMessageAvatar(chatUser),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: isImage
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isImage
                  ? null
                  : BoxDecoration(
                      color: isMe
                          ? const Color(0xFF0095F6)
                          : const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isMe ? 0.08 : 0.12),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: isMe
                          ? null
                          : Border.all(
                              color: const Color(0xFFEFEFEF), width: 1),
                    ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Media content
                  if (media != null) ...[
                    _buildMediaContent(media),
                  ],
                  // Text content - only show if there's actual text
                  if (cleanedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      cleanedText,
                      style: TextStyle(
                        color: isImage
                            ? const Color(0xFF262626)
                            : isMe
                                ? Colors.white
                                : const Color(0xFF262626),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: isImage ? Colors.black : Colors.transparent,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMediaContent(Map<String, dynamic> media) {
    final mediaType = media['type'] as String? ?? 'image';
    final mediaUrl = media['url'] as String? ?? '';

    if (mediaUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (mediaType.toLowerCase()) {
      case 'image':
        return GestureDetector(
          onTap: () => _showFullScreenImage(mediaUrl),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 200,
                  color: const Color(0xFFF8F8F8), // Instagram's placeholder color
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 200,
                  color: const Color(0xFFF8F8F8), // Instagram's placeholder color
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          ),
        );

      case 'video':
        return GestureDetector(
          onTap: () => _showFullScreenVideo(mediaUrl),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 150,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[800],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[800],
                      child: const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file, size: 20),
              SizedBox(width: 8),
              Text(
                'Media',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Full screen image
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 50),
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showFullScreenVideo(String videoUrl) {
    // For now, just show a placeholder. You can integrate a video player here
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Video Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Video URL: $videoUrl',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    // Debug: Print user data to see the structure
    log("🔍 User data for avatar in chat detail: $user");
    
    // Try different possible field names for profile picture
    final profilePic = user['profilePic'] ?? user['profile_pic'] ?? user['profilePicture'] ?? user['profile_picture'];
    final userName = user['name'] ?? user['username'] ?? 'User';
    
    log("🔍 Profile pic: $profilePic, User name: $userName");
    log("🔍 Profile pic type: ${profilePic.runtimeType}");
    
    if (profilePic != null && profilePic.toString().isNotEmpty && profilePic != 'null') {
      log("✅ Loading profile image in chat detail: $profilePic");
      return ClipOval(
        child: Image.network(
          profilePic,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            log("❌ Error loading profile image in chat detail: $error");
            return _buildInitialsAvatar(userName, 20);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildInitialsAvatar(userName, 20);
          },
        ),
      );
    } else {
      log("📝 Using initials avatar for user in chat detail: $userName");
      return _buildInitialsAvatar(userName, 20);
    }
  }

  Widget _buildMessageAvatar(Map<String, dynamic>? user) {
    if (user == null) {
      return _buildInitialsAvatar('User', 16);
    }
    
    // Debug: Print user data to see the structure
    log("🔍 User data for message avatar: $user");
    
    // Try different possible field names for profile picture
    final profilePic = user['profilePic'] ?? user['profile_pic'] ?? user['profilePicture'] ?? user['profile_picture'];
    final userName = user['name'] ?? user['username'] ?? 'User';
    
    log("🔍 Message avatar - Profile pic: $profilePic, User name: $userName");
    log("🔍 Message avatar - Profile pic type: ${profilePic.runtimeType}");
    
    if (profilePic != null && profilePic.toString().isNotEmpty && profilePic != 'null') {
      log("✅ Loading message avatar: $profilePic");
      return ClipOval(
        child: Image.network(
          profilePic,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            log("❌ Error loading message avatar: $error");
            return _buildInitialsAvatar(userName, 16);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildInitialsAvatar(userName, 16);
          },
        ),
      );
    } else {
      log("📝 Using initials avatar for message: $userName");
      return _buildInitialsAvatar(userName, 16);
    }
  }

  Widget _buildInitialsAvatar(String userName, double radius) {
    final initials = getUserInitials(userName);
    final color = getAvatarColor(initials);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _isLikelyUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    // Basic URL detector for http/https
    final regex = RegExp(r'^(https?:\/\/)[^\s]+$');
    return regex.hasMatch(v);
  }
}
