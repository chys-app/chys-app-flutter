import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../adored_posts/controller/controller.dart';
import '../../widget/common/post_grid_widget.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../routes/app_routes.dart';
import '../map/controllers/map_controller.dart';
import '../ home/widget/floating_action_button.dart';
import '../../data/models/post.dart';
import '../../services/custom_Api.dart';
import '../../services/http_service.dart';
import '../../data/models/own_profile.dart';
import 'dart:developer';

class SearchView extends StatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AddoredPostsController _postsController;
  late final MapController mapController;
  final FocusNode _searchFocusNode = FocusNode();
  final CustomApiService _customApiService = CustomApiService();
  final ApiClient _apiClient = ApiClient();
  
  // Track follow state for each creator
  final Map<String, RxBool> _followStates = {};
  final Map<String, bool> _followingInProgress = {};
  
  // All users data
  final RxList<OwnProfileModel> _allUsers = <OwnProfileModel>[].obs;
  final RxList<OwnProfileModel> _filteredUsers = <OwnProfileModel>[].obs;
  final RxBool _isLoadingUsers = false.obs;
  
  // Constants
  static const Color _primaryColor = Color(0xFF0095F6);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _textPrimary = Color(0xFF262626);
  static const Color _textSecondary = Color(0xFF8E8E8E);
  static const Color _borderColor = Color(0xFFDBDBDB);

  @override
  void initState() {
    super.initState();
    
    // Initialize MapController for bottom navigation
    if (Get.isRegistered<MapController>()) {
      mapController = Get.find<MapController>();
    } else {
      mapController = Get.put(MapController());
    }
    
    if (Get.isRegistered<AddoredPostsController>(tag: 'search')) {
      _postsController = Get.find<AddoredPostsController>(tag: 'search');
    } else {
      _postsController = Get.put(AddoredPostsController(), tag: 'search');
    }
    
    // Fetch all users for search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllUsers();
    });
  }
  
  Future<void> _fetchAllUsers() async {
    try {
      _isLoadingUsers.value = true;
      log("🔄 Fetching all users from API...");
      
      final response = await _apiClient.get(ApiEndPoints.allUsers);
      log("📋 AllUsers response: $response");
      
      if (response != null) {
        List<OwnProfileModel> users = [];
        
        // Handle different response structures
        if (response['users'] is List) {
          users = (response['users'] as List)
              .map((user) => OwnProfileModel.fromMap(user as Map<String, dynamic>))
              .toList();
        } else if (response['data'] is List) {
          users = (response['data'] as List)
              .map((user) => OwnProfileModel.fromMap(user as Map<String, dynamic>))
              .toList();
        } else if (response is List) {
          users = (response as List)
              .map((user) => OwnProfileModel.fromMap(user as Map<String, dynamic>))
              .toList();
        }
        
        _allUsers.value = users;
        _filteredUsers.value = users;
        log("✅ Successfully loaded ${users.length} users");
      } else {
        log("❌ Failed to fetch users: response is null");
      }
    } catch (e) {
      log("❌ Error fetching all users: $e");
    } finally {
      _isLoadingUsers.value = false;
    }
  }
  
  void _filterUsers(String query) {
    if (query.isEmpty) {
      _filteredUsers.value = _allUsers;
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredUsers.value = _allUsers.where((user) {
        final nameLower = user.name.toLowerCase();
        final bioLower = (user.bio ?? '').toLowerCase();
        final emailLower = user.email.toLowerCase();
        return nameLower.contains(lowerQuery) ||
               bioLower.contains(lowerQuery) ||
               emailLower.contains(lowerQuery);
      }).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(controller: mapController),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: _textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _filterUsers(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (_isLoadingUsers.value && _allUsers.isEmpty) {
        return _buildLoadingState();
      }

      if (_filteredUsers.isEmpty) {
        return _buildEmptyState();
      }

      return _buildUsersList();
    });
  }

  Widget _buildUsersList() {
    return Obx(() {
      if (_filteredUsers.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredUsers.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: _borderColor,
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserListItem(user);
        },
      );
    });
  }

  Widget _buildUserListItem(OwnProfileModel user) {
    // Initialize follow state if not already tracked
    if (!_followStates.containsKey(user.id)) {
      _followStates[user.id] = user.isFollowing.obs;
    }
    
    return InkWell(
      onTap: () {
        // Navigate to user's profile
        Get.toNamed(AppRoutes.otherUserProfile, arguments: user.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildUserAvatar(user),
            const SizedBox(width: 12),
            // Name and bio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.bio?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.bio!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Follow button
            _buildFollowButtonForUser(user),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(OwnProfileModel user) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _borderColor,
          width: 0.5,
        ),
      ),
      child: ClipOval(
        child: (user.profilePic?.isNotEmpty == true)
            ? Image.network(
                user.profilePic!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar(user.name);
                },
              )
            : _buildInitialsAvatar(user.name),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = _getInitials(name);
    return Container(
      color: _primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildFollowButtonForUser(OwnProfileModel user) {
    return Obx(() {
      final isFollowing = _followStates[user.id]?.value ?? user.isFollowing;
      final isInProgress = _followingInProgress[user.id] ?? false;
      
      return GestureDetector(
        onTap: isInProgress ? null : () => _handleFollowToggleForUser(user),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.transparent : _primaryColor,
            border: isFollowing ? Border.all(color: _borderColor) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: isInProgress
              ? SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFollowing ? _textSecondary : Colors.white,
                    ),
                  ),
                )
              : Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFollowing ? _textPrimary : Colors.white,
                  ),
                ),
        ),
      );
    });
  }
  
  Future<void> _handleFollowToggleForUser(OwnProfileModel user) async {
    if (_followingInProgress[user.id] == true) {
      return;
    }
    
    try {
      setState(() {
        _followingInProgress[user.id] = true;
      });
      
      // Store current state for rollback
      final wasFollowing = _followStates[user.id]?.value ?? user.isFollowing;
      
      // Optimistically update UI
      _followStates[user.id]?.value = !wasFollowing;
      
      // Call the follow-toggle endpoint
      final endpoint = "users/follow-toggle/${user.id}";
      log("Calling follow-toggle endpoint: $endpoint");
      final response = await _customApiService.postRequest(endpoint, {});
      
      log("Follow-toggle response: $response");
      
      // Update with actual response if available
      if (response != null && response['isFollowing'] != null) {
        _followStates[user.id]?.value = response['isFollowing'] as bool;
      }
    } catch (e) {
      log("Error in follow/unfollow: $e");
      // Revert optimistic update on error
      final currentState = _followStates[user.id]?.value ?? false;
      _followStates[user.id]?.value = !currentState;
    } finally {
      setState(() {
        _followingInProgress[user.id] = false;
      });
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: _textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No results found' : 'No users yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching 
                ? 'Try searching for something else'
                : 'Users will appear here when they join',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}