import 'dart:developer';
import 'dart:io';

import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/controllers/loading_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/chat_services.dart';
import '../../../services/short_message_utils.dart';
import '../../../services/storage_service.dart';

class ChatController extends GetxController {
  //
  final searchController = TextEditingController();
  final messageController = TextEditingController();
  late final ProfileController profileController;
  final SocketService _socketService = Get.put(SocketService());
  final isLoading = false.obs;
  final RxBool isChatLoading = false.obs;
  final RxBool isUploadingMedia = false.obs;
  final conversations = <Map<String, dynamic>>[].obs;
  final filteredConversations = <Map<String, dynamic>>[].obs;
  final messages = <Map<String, dynamic>>[].obs;
  RxString receiverId = "".obs;
  final scrollController = ScrollController();
  RxString imagePath = "".obs;
  // Track which conversation is currently open to control unread counts
  final RxString activeChatUserId = ''.obs;

  Map<String, dynamic>? _normalizeMedia(dynamic media) {
    if (media == null) return null;
    if (media is Map<String, dynamic>) {
      final dynamicUrl = media['url'] ??
          media['secure_url'] ??
          media['fileUrl'] ??
          media['path'] ??
          media['location'];
      if (dynamicUrl == null || dynamicUrl.toString().isEmpty) return null;
      final type =
          (media['type'] ?? _inferMediaType(dynamicUrl.toString())).toString();
      return {
        'url': dynamicUrl.toString(),
        'type': type,
        'public_id': media['public_id'],
      };
    }
    if (media is String) {
      if (media.isEmpty) return null;
      return {
        'url': media,
        'type': _inferMediaType(media),
      };
    }
    if (media is List) {
      if (media.isEmpty) return null;
      final first = media.first;
      return _normalizeMedia(first);
    }
    return null;
  }

  String _inferMediaType(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.contains('image')) {
      return 'image';
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.contains('video')) {
      return 'video';
    }
    return 'image';
  }

  // Helpers to manage active chat and unread counts
  void setActiveChat(String userId) {
    activeChatUserId.value = userId;
    markConversationAsRead(userId);
  }

  void clearActiveChat() {
    activeChatUserId.value = '';
  }

  void markConversationAsRead(String userId) {
    final int idx = conversations.indexWhere((c) {
      final other = c['user'] ?? c['sender'] ?? c['receiver'] ?? {};
      return (other['_id']?.toString() ?? '') == userId;
    });
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(conversations[idx]);
      updated['unreadCount'] = 0;
      conversations[idx] = updated;
    }
    // Also reflect in filtered list
    final int fIdx = filteredConversations.indexWhere((c) {
      final other = c['user'] ?? c['sender'] ?? c['receiver'] ?? {};
      return (other['_id']?.toString() ?? '') == userId;
    });
    if (fIdx != -1) {
      final updated = Map<String, dynamic>.from(filteredConversations[fIdx]);
      updated['unreadCount'] = 0;
      filteredConversations[fIdx] = updated;
    }
  }

  void _updateConversationPreview(
      {required String partnerUserId,
      required String lastMessage,
      required DateTime timestamp,
      required bool incrementUnread}) {
    int idx = conversations.indexWhere((c) {
      final other = c['user'] ?? c['sender'] ?? c['receiver'] ?? {};
      return (other['_id']?.toString() ?? '') == partnerUserId;
    });
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(conversations[idx]);
      updated['lastMessage'] = lastMessage;
      updated['timestamp'] = timestamp.toIso8601String();
      if (incrementUnread) {
        final current = (updated['unreadCount'] ?? 0) as int;
        updated['unreadCount'] = current + 1;
      }
      conversations[idx] = updated;
    }
    int fIdx = filteredConversations.indexWhere((c) {
      final other = c['user'] ?? c['sender'] ?? c['receiver'] ?? {};
      return (other['_id']?.toString() ?? '') == partnerUserId;
    });
    if (fIdx != -1) {
      final updated = Map<String, dynamic>.from(filteredConversations[fIdx]);
      updated['lastMessage'] = lastMessage;
      updated['timestamp'] = timestamp.toIso8601String();
      if (incrementUnread) {
        final current = (updated['unreadCount'] ?? 0) as int;
        updated['unreadCount'] = current + 1;
      }
      filteredConversations[fIdx] = updated;
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Initialize ProfileController with retry logic
    _initializeProfileController();
    
    // Delay other initializations to ensure ProfileController is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      ensureCurrentUserIdLoaded();
      _loadConversations();
    });
    
    _socketService.initSocket();
    _socketService.listenToPrivateMessages(_onPrivateMessageReceived);

    messageController.addListener(() {
      update();
    });

    Future.delayed(const Duration(seconds: 3), () {
      log("🔍 Testing socket connection...");
      log("🔍 Socket connected: ${_socketService.socket.connected}");
      log("🔍 Socket ID: ${_socketService.socket.id}");
    });
  }
  
  void _initializeProfileController() {
    try {
      profileController = Get.find<ProfileController>();
      log("✅ ProfileController found and initialized");
    } catch (e) {
      log("⚠️ ProfileController not found, creating new instance");
      try {
        profileController = Get.put(ProfileController());
        log("✅ ProfileController created and initialized");
      } catch (e2) {
        log("❌ Failed to create ProfileController: $e2");
        // Create a fallback instance
        profileController = ProfileController();
      }
    }
  }

  Future<void> ensureCurrentUserIdLoaded() async {
    try {
      log("🔄 Ensuring current user ID is loaded...");
      log("🔄 Current user ID before: '${profileController.userCurrentId.value}'");

      // Always reload from storage to ensure we have the correct ID
      final userData = await _loadCurrentUserFromStorage();
      if (userData != null && userData['_id'] != null) {
        final newUserId = userData['_id'].toString();
        profileController.userCurrentId.value = newUserId;
        log("✅ Current user ID loaded in chat controller: '${profileController.userCurrentId.value}'");
        log("✅ User data from storage: $userData");
      } else {
        log("❌ No user data found in storage");
      }
    } catch (e) {
      log("❌ Error loading current user ID in chat controller: $e");
    }
  }

  Future<Map<String, dynamic>?> _loadCurrentUserFromStorage() async {
    try {
      return StorageService.getUser();
    } catch (e) {
      log("❌ Error loading user from storage: $e");
      return null;
    }
  }

  Future<void> pickAndUploadMedia() async {
    try {
      // Show media picker options
      final ImageSource? source = await _showMediaPickerOptions();
      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      XFile? media;

      if (source == ImageSource.camera) {
        media = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          preferredCameraDevice: CameraDevice.rear,
        );
      } else {
        media = await picker.pickMedia(
          imageQuality: 80,
          requestFullMetadata: false,
        );
      }

      if (media != null) {
        await _uploadMedia(File(media.path));
      }
    } catch (e) {
      log("Error picking media: $e");
      ShortMessageUtils.showError('Failed to pick media');
    }
  }

  Future<ImageSource?> _showMediaPickerOptions() async {
    return await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.blue),
                title: const Text('Camera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.blue),
                title: const Text('Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _uploadMedia(File mediaFile) async {
    try {
      isUploadingMedia.value = true;
      Get.find<LoadingController>().show();

      final response = await ApiClient().postFormData(
          ApiEndPoints.uploadMedia, {"file": mediaFile},
          requestMethod: "POST");

      if (response != null && response['url'] != null) {
        final mediaData = {
          'url': response['url'],
          'type': response['type'] ?? 'image',
          'public_id': response['public_id'],
        };

        // Create message data with proper structure
        final messageText = messageController.text.trim();
        final finalMessage = messageText.isEmpty ? "" : messageText;

        final messageData = {
          'senderId': profileController.userCurrentId.value,
          'receiverId': receiverId.value,
          'message': finalMessage,
          'media': mediaData,
          'timestamp': DateTime.now().toIso8601String(),
        };

        if (!_socketService.socket.connected) {
          log("⚠️ Socket not connected, attempting to reconnect...");
          await _socketService.initSocket();
          await Future.delayed(const Duration(seconds: 2));
        }


        _socketService.sendMediaMessage(
            receiverId.value, finalMessage, mediaData);


        messages.add(messageData);

        // Update conversations preview (no unread increment for own send)
        final preview = finalMessage.isNotEmpty
            ? finalMessage
            : (mediaData['type'] == 'image' ? 'Photo' : 'Media');
        _updateConversationPreview(
          partnerUserId: receiverId.value,
          lastMessage: preview,
          timestamp: DateTime.now(),
          incrementUnread: false,
        );

        final hasText = messageController.text.trim().isNotEmpty;
        messageController.clear();
        scrollToBottom();

        await ShortMessageUtils.showSuccess(hasText
            ? 'Media and message sent successfully!'
            : 'Media sent successfully!');
      } else {
        log("❌ Invalid upload response: $response");
        throw Exception('Invalid upload response');
      }
    } catch (e) {
      log("❌ Error uploading media: $e");
      log("❌ Stack trace: ${StackTrace.current}");
      await ShortMessageUtils.showError('Failed to upload media');
    } finally {
      isUploadingMedia.value = false;
      Get.find<LoadingController>().hide();
    }
  }

  // Removed HTTP fallback - no endpoints available
  // Server persistence is handled by socket only

  Future<void> uploadImage() async {
    try {
      final response = await ApiClient()
          .postFormData(ApiEndPoints.uploadMedia, {"file": imagePath.value});
      String url = response["url"];
    } catch (e) {
      log("Error is $e");
    }
  }

  /// Public method to refresh conversations
  Future<void> refreshConversations() async {
    await _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      isLoading.value = true;
      log("🔄 Starting to load conversations...");

      // Ensure current user ID is loaded before processing conversations
      if (profileController.userCurrentId.value.isEmpty) {
        log("⚠️ Current user ID is empty, loading from storage...");
        await ensureCurrentUserIdLoaded();
        log("✅ Current user ID after loading: ${profileController.userCurrentId.value}");
      }

      log("🔄 Making API call to /chat/get/users...");
      final response = await ApiClient().get("/chat/get/users");
      log("📋 Chat API Response: $response");
      log("📋 Chat API Response type: ${response.runtimeType}");

      // Check for server errors in the response
      if (response is Map && response.containsKey('error')) {
        final errorMessage = response['error']?.toString() ?? '';
        final message = response['message']?.toString() ?? '';
        log("❌ Server error detected: $errorMessage");
        log("❌ Server message: $message");

        // Handle specific server errors
        if (errorMessage.contains('lastMessage') ||
            message.contains('lastMessage')) {
          log("⚠️ Server has 'lastMessage' error, using fallback data");
          // Use fallback data directly
          // final dummyConversations = _createDummyConversations();
          // conversations.assignAll(dummyConversations);
          // filteredConversations.value = conversations;
          // log("📋 Loaded ${dummyConversations.length} fallback conversations");
          return;
        }

        // For other server errors, try alternative endpoints
        log("⚠️ Server error, trying alternative endpoints...");
        await _tryAlternativeEndpointsDirect();
        return;
      }

      if (response == null) {
        log("❌ API response is null");
        return;
      }

      // Check if response is a Map with data field
      dynamic dataToProcess = response;
      if (response is Map && response.containsKey('data')) {
        dataToProcess = response['data'];
        log("📋 Using 'data' field from response: $dataToProcess");
      } else if (response is Map && response.containsKey('users')) {
        dataToProcess = response['users'];
        log("📋 Using 'users' field from response: $dataToProcess");
      } else if (response is Map && response.containsKey('conversations')) {
        dataToProcess = response['conversations'];
        log("📋 Using 'conversations' field from response: $dataToProcess");
      }

      // Try alternative endpoints if the first one doesn't work
      if (dataToProcess == null ||
          (dataToProcess is Map && dataToProcess.isEmpty) ||
          (dataToProcess is List && dataToProcess.isEmpty)) {
        log("⚠️ First endpoint returned empty, trying alternative endpoints...");

        try {
          final altResponse1 = await ApiClient().get("/chat/users");
          log("📋 Alternative endpoint 1 response: $altResponse1");
          if (altResponse1 != null &&
              altResponse1 is List &&
              altResponse1.isNotEmpty) {
            log("✅ Alternative endpoint 1 worked, using this data");
            dataToProcess = altResponse1;
          }
        } catch (e) {
          log("❌ Alternative endpoint 1 failed: $e");
        }

        if (dataToProcess == response) {
          try {
            final altResponse2 = await ApiClient().get("/users/chat");
            log("📋 Alternative endpoint 2 response: $altResponse2");
            if (altResponse2 != null &&
                altResponse2 is List &&
                altResponse2.isNotEmpty) {
              log("✅ Alternative endpoint 2 worked, using this data");
              dataToProcess = altResponse2;
            }
          } catch (e) {
            log("❌ Alternative endpoint 2 failed: $e");
          }
        }
      }

      log("📋 Data to process: $dataToProcess");
      log("📋 Data type: ${dataToProcess.runtimeType}");

      // Debug: Print each conversation to see the structure
      if (dataToProcess is List) {
        for (int i = 0; i < dataToProcess.length; i++) {
          final conversation = dataToProcess[i];
          log("💬 Conversation $i: $conversation");

          // Check for different user data structures
          if (conversation['user'] != null) {
            log("👤 User data in conversation $i: ${conversation['user']}");
          }
          if (conversation['sender'] != null) {
            log("👤 Sender data in conversation $i: ${conversation['sender']}");
          }
          if (conversation['receiver'] != null) {
            log("👤 Receiver data in conversation $i: ${conversation['receiver']}");
          }

          // Check for profile picture fields
          final user = conversation['user'] ??
              conversation['sender'] ??
              conversation['receiver'];
          if (user != null && user is Map) {
            final profilePic = user['profilePic'] ??
                user['profile_pic'] ??
                user['profilePicture'] ??
                user['profile_picture'];
            log("🖼️ Profile pic in conversation $i: $profilePic");
          }
        }
      }

      // Process the response to create conversation summaries
      final processedConversations = _processConversations(dataToProcess);
      log("📋 Processed conversations: $processedConversations");

      // If no conversations found, try to create from all users
      if (processedConversations.isEmpty &&
          dataToProcess is List &&
          dataToProcess.isNotEmpty) {
        log("⚠️ No conversations found, trying to create from all users...");
        final fallbackConversations =
            _createFallbackConversations(dataToProcess);
        conversations.assignAll(fallbackConversations);
        log("📋 Fallback conversations: ${fallbackConversations.length}");
      } else {
        conversations.assignAll(processedConversations);
      }

      filteredConversations.value = conversations;
      log("✅ Loaded ${conversations.length} conversations");
      log("✅ Filtered conversations: ${filteredConversations.length}");

      // Debug: Print each conversation
      for (int i = 0; i < conversations.length; i++) {
        log("📋 Conversation $i: ${conversations[i]}");
      }

      // If still no conversations, create some dummy data for testing
      if (conversations.isEmpty) {
        // log("⚠️ No conversations found, creating dummy data for testing...");
        // final dummyConversations = _createDummyConversations();
        // conversations.assignAll(dummyConversations);
        // filteredConversations.value = conversations;
        // log("📋 Created ${dummyConversations.length} dummy conversations");
      }
    } catch (e) {
      log("❌ Error loading conversations: $e");
      // On any error, use fallback data
      // final dummyConversations = _createDummyConversations();
      // conversations.assignAll(dummyConversations);
      // filteredConversations.value = conversations;
   //   log("📋 Loaded ${dummyConversations.length} fallback conversations");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _tryAlternativeEndpointsDirect() async {
    log("🔄 Trying alternative chat endpoints...");

    final endpoints = [
      "/chat/users",
      "/users/chat",
      "/chat/conversations",
      "/api/chat/users"
    ];

    for (final endpoint in endpoints) {
      try {
        log("🔄 Trying endpoint: $endpoint");
        final response = await ApiClient().get(endpoint);

        if (response != null && response is List && response.isNotEmpty) {
          log("✅ Alternative endpoint $endpoint worked");
          final processedConversations = _processConversations(response);
          if (processedConversations.isNotEmpty) {
            conversations.assignAll(processedConversations);
            filteredConversations.value = conversations;
            log("📋 Loaded ${conversations.length} conversations from $endpoint");
            return;
          }
        }
      } catch (e) {
        log("❌ Alternative endpoint $endpoint failed: $e");
      }
    }

    // If all alternative endpoints fail, use fallback data
    // log("⚠️ All alternative endpoints failed, using fallback data");
    // final dummyConversations = _createDummyConversations();
    // conversations.assignAll(dummyConversations);
    // filteredConversations.value = conversations;
    // log("📋 Loaded ${dummyConversations.length} fallback conversations");
  }

  void _useFallbackData() {
    // log("🔄 Using fallback data for conversations");
    // final dummyConversations = _createDummyConversations();
    // conversations.assignAll(dummyConversations);
    // filteredConversations.value = conversations;
    // log("📋 Loaded ${dummyConversations.length} fallback conversations");
  }

  Future<void> _tryAlternativeEndpoints() async {
    log("🔄 Trying alternative chat endpoints...");

    final endpoints = [
      "/chat/users",
      "/users/chat",
      "/chat/conversations",
      "/api/chat/users"
    ];

    for (final endpoint in endpoints) {
      try {
        log("🔄 Trying endpoint: $endpoint");
        final response = await ApiClient().get(endpoint);

        if (response != null && response is List && response.isNotEmpty) {
          log("✅ Alternative endpoint $endpoint worked");
          final processedConversations = _processConversations(response);
          if (processedConversations.isNotEmpty) {
            conversations.assignAll(processedConversations);
            filteredConversations.value = conversations;
            log("📋 Loaded ${conversations.length} conversations from $endpoint");
            return;
          }
        }
      } catch (e) {
        log("❌ Alternative endpoint $endpoint failed: $e");
      }
    }

    // // If all alternative endpoints fail, use fallback data
    // log("⚠️ All alternative endpoints failed, using fallback data");
    // final dummyConversations = _createDummyConversations();
    // conversations.assignAll(dummyConversations);
    // filteredConversations.value = conversations;
    // log("📋 Loaded ${dummyConversations.length} fallback conversations");
  }

  List<Map<String, dynamic>> _processConversations(dynamic response) {
    if (response is! List) {
      log("❌ Response is not a list: ${response.runtimeType}");
      return [];
    }

    log("🔄 Processing ${response.length} messages into conversations");
    final Map<String, Map<String, dynamic>> conversationMap = {};
    final currentUserId = profileController.userCurrentId.value;
    log("🔄 Current user ID: $currentUserId");

    // Handle empty response
    if (response.isEmpty) {
      log("⚠️ Response is empty, returning empty conversations");
      return [];
    }

    for (int i = 0; i < response.length; i++) {
      final message = response[i];
      if (message is! Map<String, dynamic>) {
        log("⚠️ Message $i is not a Map: ${message.runtimeType}");
        continue;
      }

      // Skip messages with missing required fields
      if (message['sender'] == null && message['receiver'] == null) {
        log("⚠️ Message $i has no sender or receiver, skipping");
        continue;
      }

      log("🔄 Processing message $i: $message");

      // Get the other user (not current user)
      Map<String, dynamic>? otherUser;
      String? conversationId;

      if (message['sender'] != null && message['sender'] is Map) {
        final sender = message['sender'] as Map<String, dynamic>;
        final senderId = sender['_id']?.toString();
        log("🔄 Sender ID: $senderId");

        if (senderId != null && senderId != currentUserId) {
          otherUser = sender;
          conversationId = senderId;
          log("🔄 Using sender as other user: $senderId");
        }
      }

      if (otherUser == null &&
          message['receiver'] != null &&
          message['receiver'] is Map) {
        final receiver = message['receiver'] as Map<String, dynamic>;
        final receiverId = receiver['_id']?.toString();
        log("🔄 Receiver ID: $receiverId");

        if (receiverId != null && receiverId != currentUserId) {
          otherUser = receiver;
          conversationId = receiverId;
          log("🔄 Using receiver as other user: $receiverId");
        }
      }

      if (otherUser != null && conversationId != null) {
        log("🔄 Creating/updating conversation for user: $conversationId");
        try {
          // Create or update conversation
          if (!conversationMap.containsKey(conversationId)) {
            conversationMap[conversationId] = {
              'user': otherUser,
              'lastMessage': message['message']?.toString() ?? '',
              'timestamp':
                  message['timestamp']?.toString() ?? DateTime.now().toString(),
              'unreadCount': 0, // You might want to calculate this
            };
            log("🔄 Created new conversation for: $conversationId");
          } else {
            // Update with latest message
            final conversation = conversationMap[conversationId]!;
            final currentTimestamp =
                DateTime.tryParse(conversation['timestamp'] ?? '') ??
                    DateTime.now();
            final messageTimestamp =
                DateTime.tryParse(message['timestamp']?.toString() ?? '') ??
                    DateTime.now();

            if (messageTimestamp.isAfter(currentTimestamp)) {
              conversation['lastMessage'] =
                  message['message']?.toString() ?? '';
              conversation['timestamp'] =
                  message['timestamp']?.toString() ?? DateTime.now().toString();
              log("🔄 Updated conversation for: $conversationId");
            }
          }
        } catch (e) {
          log("❌ Error processing conversation for user $conversationId: $e");
        }
      } else {
        log("⚠️ Could not determine other user for message $i");
      }
    }

    log("🔄 Processed ${conversationMap.length} conversations");
    log("🔄 Conversation IDs: ${conversationMap.keys.toList()}");
    return conversationMap.values.toList();
  }

  List<Map<String, dynamic>> _createFallbackConversations(List response) {
    log("🔄 Creating fallback conversations from ${response.length} items");
    final List<Map<String, dynamic>> fallbackConversations = [];
    final currentUserId = profileController.userCurrentId.value;

    for (int i = 0; i < response.length; i++) {
      final item = response[i];
      if (item is! Map<String, dynamic>) continue;

      log("🔄 Processing fallback item $i: $item");

      // Try to extract user data from different possible structures
      Map<String, dynamic>? userData;

      if (item['user'] != null && item['user'] is Map) {
        userData = item['user'] as Map<String, dynamic>;
        log("🔄 Found user data in 'user' field");
      } else if (item['sender'] != null && item['sender'] is Map) {
        userData = item['sender'] as Map<String, dynamic>;
        log("🔄 Found user data in 'sender' field");
      } else if (item['receiver'] != null && item['receiver'] is Map) {
        userData = item['receiver'] as Map<String, dynamic>;
        log("🔄 Found user data in 'receiver' field");
      }

      if (userData != null) {
        final userId = userData['_id']?.toString();
        if (userId != null && userId != currentUserId) {
          log("🔄 Creating fallback conversation for user: $userId");
          fallbackConversations.add({
            'user': userData,
            'lastMessage': item['lastMessage'] ?? 'No messages yet',
            'timestamp': item['timestamp'] ?? DateTime.now().toString(),
            'unreadCount': 0,
          });
        }
      }
    }

    log("🔄 Created ${fallbackConversations.length} fallback conversations");
    return fallbackConversations;
  }



  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> loadChat() async {
    try {
      isChatLoading.value = true;
      final response = await ApiClient().get("/chat/${receiverId.value}");
      log("📋 Chat API Response: $response");

      // Process messages to ensure proper structure
      final processedMessages =
          List<Map<String, dynamic>>.from(response).map((msg) {
        log("📨 Processing message: $msg");

        // Handle nested sender structure - add senderId for easier processing
        if (msg['sender'] != null && msg['sender'] is Map) {
          final sender = msg['sender'] as Map<String, dynamic>;
          msg['senderId'] = sender['_id']?.toString();
          log("📨 Added senderId from nested structure: ${msg['senderId']}");
        }

        // Handle nested receiver structure - add receiverId for easier processing
        if (msg['receiver'] != null && msg['receiver'] is Map) {
          final receiver = msg['receiver'] as Map<String, dynamic>;
          msg['receiverId'] = receiver['_id']?.toString();
          log("📨 Added receiverId from nested structure: ${msg['receiverId']}");
        }

        // Ensure timestamp is properly formatted
        if (msg['timestamp'] != null) {
          try {
            if (msg['timestamp'] is String) {
              msg['timestamp'] = DateTime.parse(msg['timestamp']);
            } else if (msg['timestamp'] is int) {
              msg['timestamp'] =
                  DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int);
            }
          } catch (e) {
            log("⚠️ Error parsing timestamp: $e");
            msg['timestamp'] = DateTime.now();
          }
        }

        // Normalize media into a consistent structure, supporting alternate keys
        Map<String, dynamic>? normalizedMedia;
        if (msg.containsKey('media')) {
          normalizedMedia = _normalizeMedia(msg['media']);
        }
        if (normalizedMedia == null) {
          final altMediaValue = msg['mediaUrl'] ??
              msg['media_url'] ??
              msg['attachment'] ??
              msg['file'] ??
              msg['image'] ??
              msg['photo'] ??
              msg['attachments'];
          normalizedMedia = _normalizeMedia(altMediaValue);
        }
        msg['media'] = normalizedMedia;

        log("📨 Processed message: $msg");
        return msg;
      }).toList();

      messages.assignAll(processedMessages);
      scrollToBottom();
      log("✅ Chat loaded with ${messages.length} messages");

      // Debug: Check each message's sender
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        final senderId = message['senderId']?.toString() ?? 'null';
        final currentUserId = profileController.userCurrentId.value.toString();
        final isFromMe = senderId == currentUserId;
        log("📨 Message $i - Sender: '$senderId', Current: '$currentUserId', IsFromMe: $isFromMe");
      }
    } catch (e) {
      log("❌ Error loading chat: $e");
      ShortMessageUtils.showError('Failed to load chat messages');
    } finally {
      isChatLoading.value = false;
    }
  }

  void _onPrivateMessageReceived(Map<String, dynamic> data) {
    log("📥 Private message listener received: $data");

    String? senderId = data["senderId"]?.toString();
    String? receiverIdData = data["receiverId"]?.toString();
    if ((senderId == null || senderId == 'null') &&
        data['sender'] is Map<String, dynamic>) {
      senderId = (data['sender']['_id'] ?? '').toString();
    }
    if ((receiverIdData == null || receiverIdData == 'null') &&
        data['receiver'] is Map<String, dynamic>) {
      receiverIdData = (data['receiver']['_id'] ?? '').toString();
    }

    final messageText = data["message"] ?? '';
    final dynamic incomingMedia = data["media"] ??
        data['mediaUrl'] ??
        data['media_url'] ??
        data['attachment'] ??
        data['file'] ??
        data['image'] ??
        data['photo'] ??
        data['attachments'];
    final media = _normalizeMedia(incomingMedia);
    final timestamp =
        DateTime.tryParse(data["timestamp"] ?? '') ?? DateTime.now();

         log("📥 Processing message - Sender: $senderId, Receiver: $receiverIdData");
     log("📥 Message text: $messageText");
     log("📥 Media data: $media");
     final currentUserId = profileController.userCurrentId.value;

    if (senderId != null && senderId == currentUserId) {
      log("ℹ️ Skipping echo of our own message from socket");
      return;
    }

    final isDuplicate = messages.any((msg) {
      final msgTimestamp = msg['timestamp'] is String
          ? DateTime.tryParse(msg['timestamp'])
          : msg['timestamp'] as DateTime?;

      return msg['senderId']?.toString() == senderId &&
          msg['receiverId']?.toString() == receiverIdData &&
          msg['message'] == messageText &&
          msgTimestamp != null &&
          timestamp.difference(msgTimestamp).inSeconds.abs() < 5;
    });

    if (!isDuplicate) {
      final newMessage = {
        'senderId': senderId,
        'receiverId': receiverIdData,
        'message': messageText,
        'timestamp': timestamp,
        if (media != null) 'media': media,
      };

      messages.add(newMessage);
      log("🆕 Message added to messages: ${messages.last}");
      log("✅ Total messages after adding: ${messages.length}");

      // Update conversation preview and unread count when receiving
      final preview = (messageText?.toString().trim().isNotEmpty == true)
          ? messageText.toString()
          : (media != null
              ? (media['type'] == 'image' ? 'Photo' : 'Media')
              : '');
      final increment = activeChatUserId.value != (senderId ?? '');
      _updateConversationPreview(
        partnerUserId: senderId ?? '',
        lastMessage: preview,
        timestamp: timestamp,
        incrementUnread: increment,
      );
      if (!increment) {
        // If the chat is open with this user, mark as read
        markConversationAsRead(senderId ?? '');
      }

      scrollToBottom();
    } else {
      log("⚠️ Duplicate message ignored");
    }
  }

  void sendPrivateMessage(String senderId) {
    log("📤 Sending message with senderId: $senderId");
    log("📤 Current user ID from profile controller: ${profileController.userCurrentId.value}");
    log("📤 Receiver ID: ${receiverId.value}");

    if (messageController.text.trim().isEmpty) return;

    final text = messageController.text.trim();
    final newMessage = {
      'senderId': senderId,
      'receiverId': receiverId.value,
      'message': text,
      'timestamp': DateTime.now(),
    };

    messages.add(newMessage);
    messageController.clear();
    log("✅ Message added to list: ${messages.last}");
    log("✅ Total messages: ${messages.length}");
    _socketService.sendPrivateMessage(receiverId.value, text);
    scrollToBottom();

    // Update conversations preview for our own send (no unread increment)
    _updateConversationPreview(
      partnerUserId: receiverId.value,
      lastMessage: text,
      timestamp: DateTime.now(),
      incrementUnread: false,
    );
  }

  void sendMediaMessageOnly(String senderId, Map<String, dynamic> mediaData) {
    messages.add({
      'senderId': senderId,
      'receiverId': receiverId.value,
      'message': '',
      'media': mediaData,
      'timestamp': DateTime.now(),
    });

    _socketService.sendMediaMessage(receiverId.value, '', mediaData);
    scrollToBottom();
  }

  void onSearchChanged(String query) {
    if (query.isEmpty) {
      filteredConversations.value = conversations;
      return;
    }

    filteredConversations.value = conversations
        .where((conversation) =>
            conversation['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            conversation['lastMessage']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
  }

  void onSearchTap() {
    // Implement advanced search functionality
  }

  void onNewChat() {
    Get.toNamed(AppRoutes.newChat);
  }

  void onConversationTap(Map<String, dynamic> conversation) {
    log("🎯 Conversation tapped: $conversation");

    // Handle different possible user data structures
    Map<String, dynamic>? user;
    if (conversation['user'] != null && conversation['user'] is Map) {
      user = conversation['user'] as Map<String, dynamic>;
      log("👤 Using user data from 'user' field");
    } else if (conversation['sender'] != null &&
        conversation['sender'] is Map) {
      user = conversation['sender'] as Map<String, dynamic>;
      log("👤 Using user data from 'sender' field");
    } else if (conversation['receiver'] != null &&
        conversation['receiver'] is Map) {
      user = conversation['receiver'] as Map<String, dynamic>;
      log("👤 Using user data from 'receiver' field");
    }

    if (user != null) {
      log("👤 User data for navigation: $user");
      log("👤 User profile pic for navigation: ${user['profilePic']}");
      Get.toNamed(
        AppRoutes.chatDetail,
        arguments: {
          "id": user["_id"],
          "name": user["name"],
          "profilePic": user["profilePic"], // Include profile picture
        },
      );
    } else {
      log("❌ No user data found in conversation");
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    messageController.dispose();
    _socketService.removePrivateMessagesListener();
    super.onClose();
  }
}
