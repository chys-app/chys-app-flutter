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
import '../../services/storage_service.dart';
import '../../data/models/own_profile.dart';
import '../../data/models/pet_profile.dart';
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
  
  // All pets data
  final RxList<PetModel> _allPets = <PetModel>[].obs;
  final RxList<PetModel> _filteredPets = <PetModel>[].obs;
  final RxBool _isLoadingPets = false.obs;
  
  // Track follow state for pet owners
  final Map<String, RxBool> _followStates = {};
  final Map<String, bool> _followingInProgress = {};
  
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
    
    // Fetch all pets for search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllPets();
    });
  }
  
  Future<void> _fetchAllPets() async {
    try {
      _isLoadingPets.value = true;
      
      // Log JWT token for debugging
      final token = StorageService.getToken();
      log("� JWT Token: $token");
      log("�🔄 Fetching all pets from API endpoint: ${ApiEndPoints.nearbyPet}");
      
      final response = await _apiClient.get(ApiEndPoints.nearbyPet);
      log("📋 AllPets response: $response");
      log("📋 Response type: ${response.runtimeType}");
      log("📋 Response keys: ${response is Map ? response.keys.toList() : 'Not a map'}");
      
      if (response != null) {
        List<PetModel> pets = [];
        
        // Handle different response structures
        if (response['pets'] is List) {
          log("🐾 Found petProfiles array with ${(response['pets'] as List).length} items");
          pets = (response['pets'] as List)
              .map((pet) => PetModel.fromJson(pet as Map<String, dynamic>))
              .toList();
        } else if (response['pets'] is Map) {
          // Single pet profile response
          log("🐾 Found single petProfile object");
          pets = [PetModel.fromJson(response['petProfile'] as Map<String, dynamic>)];
        } else if (response['data'] is List) {
          log("🐾 Found data array with ${(response['data'] as List).length} items");
          pets = (response['data'] as List)
              .map((pet) => PetModel.fromJson(pet as Map<String, dynamic>))
              .toList();
        } else if (response is List) {
          log("🐾 Response is a direct list with ${(response as List).length} items");
          pets = (response as List)
              .map((pet) => PetModel.fromJson(pet as Map<String, dynamic>))
              .toList();
        } else {
          log("⚠️ Unknown response structure. Response: $response");
        }
        
        _allPets.value = pets;
        _filteredPets.value = pets;
        log("✅ Successfully loaded ${pets.length} pets");
        
        // Debug: Log pet user IDs
        for (var pet in pets) {
          log("🐾 Pet: ${pet.name}, User ID: ${pet.user}, Has UserModel: ${pet.userModel != null}");
        }
      } else {
        log("❌ Failed to fetch pets: response is null");
      }
    } catch (e, stackTrace) {
      log("❌ Error fetching all pets: $e");
      log("❌ Stack trace: $stackTrace");
    } finally {
      _isLoadingPets.value = false;
    }
  }
  
  void _filterPets(String query) {
    if (query.isEmpty) {
      _filteredPets.value = _allPets;
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredPets.value = _allPets.where((pet) {
        final nameLower = (pet.name ?? '').toLowerCase();
        final breedLower = (pet.breed ?? '').toLowerCase();
        final bioLower = (pet.bio ?? '').toLowerCase();
        final petTypeLower = (pet.petType ?? '').toLowerCase();
        return nameLower.contains(lowerQuery) ||
               breedLower.contains(lowerQuery) ||
               bioLower.contains(lowerQuery) ||
               petTypeLower.contains(lowerQuery);
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
                  _filterPets(value);
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
      if (_isLoadingPets.value && _allPets.isEmpty) {
        return _buildLoadingState();
      }

      if (_filteredPets.isEmpty) {
        return _buildEmptyState();
      }

      return _buildPetsGrid();
    });
  }

  Widget _buildPetsGrid() {
    return Obx(() {
      if (_filteredPets.isEmpty) {
        return _buildEmptyState();
      }

      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 3;

      return StaggeredGridView.countBuilder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        padding: EdgeInsets.zero,
        itemCount: _filteredPets.length,
        itemBuilder: (context, index) {
          final pet = _filteredPets[index];
          return _buildPetGridItem(pet);
        },
        staggeredTileBuilder: (index) {
          return const StaggeredTile.count(1, 1.0);
        },
      );
    });
  }

  Widget _buildPetGridItem(PetModel pet) {
    return GestureDetector(
      onTap: () {
        // Navigate to pet profile
        Get.toNamed(AppRoutes.petProfile, arguments: pet.id);
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Pet image
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: (pet.profilePic?.isNotEmpty == true)
                  ? Image.network(
                      pet.profilePic!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPetPlaceholder(pet),
                    )
                  : _buildPetPlaceholder(pet),
            ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pet.name ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pet.breed?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        pet.breed!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Follow button in top right
            if (pet.user != null)
              Positioned(
                top: 8,
                right: 8,
                child: _buildFollowButton(pet),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetPlaceholder(PetModel pet) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pet.petType?.toLowerCase() == 'dog'
                  ? Icons.pets
                  : pet.petType?.toLowerCase() == 'cat'
                      ? Icons.pets
                      : Icons.pets,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              pet.name ?? 'Unknown',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(PetModel pet) {
    final userId = pet.user;
    log("🔵 Building follow button for pet: ${pet.name}, userId: $userId");
    
    if (userId == null) {
      log("⚠️ No userId for pet: ${pet.name}");
      return const SizedBox.shrink();
    }
    
    // Initialize follow state if not already tracked (default to false)
    if (!_followStates.containsKey(userId)) {
      _followStates[userId] = false.obs;
    }
    
    return Obx(() {
      final isFollowing = _followStates[userId]?.value ?? false;
      final isInProgress = _followingInProgress[userId] ?? false;
      
      return GestureDetector(
        onTap: isInProgress ? null : () => _handleFollowToggle(pet),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white.withOpacity(0.9) : _primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isInProgress
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFollowing ? _textPrimary : Colors.white,
                    ),
                  ),
                )
              : Icon(
                  isFollowing ? Icons.check : Icons.person_add,
                  size: 16,
                  color: isFollowing ? _textPrimary : Colors.white,
                ),
        ),
      );
    });
  }
  
  Future<void> _handleFollowToggle(PetModel pet) async {
    final userId = pet.user;
    log("🔄 Follow button tapped for pet: ${pet.name}, userId: $userId");
    
    if (userId == null) {
      log("❌ Cannot follow: userId is null");
      return;
    }
    
    if (_followingInProgress[userId] == true) {
      log("⚠️ Follow request already in progress for userId: $userId");
      return;
    }
    
    try {
      setState(() {
        _followingInProgress[userId] = true;
      });
      
      // Store current state for rollback
      final wasFollowing = _followStates[userId]?.value ?? false;
      
      // Optimistically update UI
      _followStates[userId]?.value = !wasFollowing;
      
      // Call the follow-toggle endpoint
      final endpoint = "users/follow-toggle/$userId";
      log("📞 Calling follow-toggle endpoint: $endpoint");
      log("📤 Request data: {}");
      
      final response = await _customApiService.postRequest(endpoint, {});
      
      log("📥 Follow-toggle response: $response");
      log("📥 Response type: ${response.runtimeType}");
      
      // Update with actual response if available
      if (response != null && response['isFollowing'] != null) {
        _followStates[userId]?.value = response['isFollowing'] as bool;
      }
    } catch (e) {
      log("Error in follow/unfollow: $e");
      // Revert optimistic update on error
      final currentState = _followStates[userId]?.value ?? false;
      _followStates[userId]?.value = !currentState;
    } finally {
      setState(() {
        _followingInProgress[userId] = false;
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
            isSearching ? 'No pets found' : 'No pets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching 
                ? 'Try searching for a different pet name or breed'
                : 'Pet profiles will appear here',
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