import 'dart:developer';
import 'package:get/get.dart';
import '../../data/models/pet_profile.dart';
import '../../services/http_service.dart';
import '../../services/storage_service.dart';
import '../map/controllers/map_controller.dart';
import '../../routes/app_routes.dart';
import '../profile/controllers/profile_controller.dart';

class SearchController extends GetxController {
  // Search query
  final searchQuery = ''.obs;
  
  // Loading state
  final isLoadingPets = false.obs;
  
  // Map controller for bottom navigation
  late final MapController mapController;
  
  // Profile controller for follow state
  late final ProfileController profileController;
  
  // All pets data
  final RxList<PetModel> allPets = <PetModel>[].obs;
  final RxList<PetModel> filteredPets = <PetModel>[].obs;
  
  // Track follow progress for pet owners (loading state only)
  final Map<String, RxBool> followingInProgress = {};
  
  // Reactive trigger for profile changes
  final RxInt profileUpdateTrigger = 0.obs;
  
  // Dedicated reactive follow states
  final RxMap<String, bool> reactiveFollowStates = <String, bool>{}.obs;
  
  // Services
  final ApiClient _apiClient = ApiClient();
  
  @override
  void onInit() {
    super.onInit();
    mapController = Get.put(MapController());
    profileController = Get.find<ProfileController>();
    fetchAllPets();
    
    // Listen to search query changes
    ever(searchQuery, (_) => filterPets());
    
    // Listen to profile changes to update follow states
    ever(profileController.profile, (_) {
      // Update reactive follow states when profile changes
      updateReactiveFollowStates();
      profileUpdateTrigger.value++;
      log("Profile updated, refreshing follow states (trigger: ${profileUpdateTrigger.value})");
    });
  }
  
  Future<void> fetchAllPets() async {
    try {
      log("🚀 Starting fetchAllPets...");
      isLoadingPets.value = true;
      
      // Log JWT token for debugging
      final token = StorageService.getToken();
      log("token here : $token");
      
      log("📡 Making API call to: ${ApiEndPoints.nearbyPet}");
      log("📡 Using _apiClient: ${_apiClient.runtimeType}");
      
      // Add timeout to prevent hanging
      final response = await _apiClient.get(ApiEndPoints.nearbyPet)
          .timeout(Duration(seconds: 10), onTimeout: () {
        log("⏰ API call timed out after 10 seconds");
        return null;
      });
      
      log("📡 API call completed, response: $response");
      log("Fetch all pets response: $response");
      log("Response keys: ${response is Map ? response.keys.toList() : 'Not a map'}");
      log("Response type: ${response.runtimeType}");
      
      if (response != null) {
        log("✅ Response is not null, proceeding with pet parsing");
        List<PetModel> pets = [];
        
        // Handle different response structures
        if (response['pets'] is List) {
          final petsList = response['pets'] as List;
          log("Found petProfiles array with ${petsList.length} items");
          if (petsList.isNotEmpty) {
            log("First pet item: ${petsList.first}");
            try {
              pets = petsList
                  .map((pet) => PetModel.fromJson(pet as Map<String, dynamic>))
                  .toList();
              log("Successfully parsed ${pets.length} pets");
            } catch (e) {
              log("❌ Error parsing pets: $e");
            }
          } else {
            log("Pets array is empty");
          }
        } else if (response['pets'] is Map) {
          log("Found petProfiles object: ${response['pets']}");
          try {
            pets = [PetModel.fromJson(response['pets'] as Map<String, dynamic>)];
          } catch (e) {
            log("❌ Error parsing single pet: $e");
          }
        } else {
          log("❌ Unknown response structure. Response: $response");
          log("Looking for 'pets' key: ${response.containsKey('pets')}");
          if (response.containsKey('pets')) {
            log("'pets' value: ${response['pets']} (type: ${response['pets'].runtimeType})");
          }
        }
        
        // Filter out current user's own pets
        final currentUserId = profileController.userCurrentId.value;
        log("DEBUG: Current user ID from profileController: '$currentUserId'");
        log("DEBUG: Current user ID isEmpty: ${currentUserId.isEmpty}");
        
        // Re-enable proper filtering now that we've confirmed the logic works
        List<PetModel> filteredPets;
        if (currentUserId.isEmpty) {
          // If we don't have current user ID, show all pets for now
          log("WARNING: No current user ID available, showing all pets");
          filteredPets = pets;
        } else {
          // Filter out current user's own pets
          filteredPets = pets.where((pet) {
            final shouldExclude = pet.user == currentUserId;
            if (shouldExclude) {
              log("DEBUG: Filtering out pet ${pet.name} (user: ${pet.user}) - belongs to current user");
            }
            return !shouldExclude;
          }).toList();
        }
        
        // Debug: Show pet user IDs before filtering
        for (var pet in pets) {
          log("DEBUG: Pet ${pet.name} (user: ${pet.user} - type: ${pet.user.runtimeType}) - belongs to current user: ${pet.user == currentUserId}");
          log("DEBUG: Pet ${pet.name} userModel: ${pet.userModel?.name} (${pet.userModel?.id})");
        }
        
        log("Total pets fetched: ${pets.length}");
        log("Current user ID: '$currentUserId'");
        log("Pets after filtering out current user's pets: ${filteredPets.length}");
        
        allPets.assignAll(filteredPets);
        this.filteredPets.assignAll(filteredPets);
        log("Successfully loaded ${filteredPets.length} pets");
        
        // Initialize follow states for all pet owners
        initializeFollowStates(filteredPets);
        
        // Debug: Log pet user IDs and follow states
        for (var pet in filteredPets) {
          final isFollowing = profileController.isCurrentUserFollowing(pet.user ?? '');
          log("Pet: ${pet.name}, User ID: ${pet.user}, Has UserModel: ${pet.userModel != null}, Photos count: ${pet.photos?.length ?? 0}, First photo: ${(pet.photos?.isNotEmpty == true) ? pet.photos!.first : 'none'}, Is Following: $isFollowing");
        }
      } else {
        log("❌ Failed to fetch pets: response is null");
      }
    } catch (e, stackTrace) {
      log("❌ ERROR fetching all pets: $e");
      log("❌ Stack trace: $stackTrace");
      log("❌ Error type: ${e.runtimeType}");
    } finally {
      isLoadingPets.value = false;
      log("🏁 fetchAllPets completed, isLoadingPets set to false");
    }
  }
  
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
  
  void clearSearch() {
    searchQuery.value = '';
    filterPets();
  }
  
  void filterPets() {
    if (searchQuery.value.isEmpty) {
      filteredPets.value = allPets;
    } else {
      final lowerQuery = searchQuery.value.toLowerCase();
      filteredPets.value = allPets.where((pet) {
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
    log('Filtered ${filteredPets.length} pets from ${allPets.length} total pets');
  }
  
  Future<void> handleFollowToggle(String userId) async {
    log("Follow toggle requested for userId: $userId");
    
    if (followingInProgress[userId]?.value == true) {
      log("Follow request already in progress for userId: $userId");
      return;
    }
    
    // Initialize follow state if it doesn't exist
    if (!followingInProgress.containsKey(userId)) {
      followingInProgress[userId] = false.obs;
    }
    
    try {
      followingInProgress[userId]!.value = true;
      
      // Log profile state before toggle
      final profileBefore = profileController.profile.value;
      final followingBefore = profileBefore?.following ?? [];
      final wasFollowing = profileController.isCurrentUserFollowing(userId);
      log("Before toggle - wasFollowing: $wasFollowing for user: $userId");
      log("Before toggle - following count: ${followingBefore.length}, following list: $followingBefore");
      
      // Use ProfileController's followUnfollow method
      await profileController.followUnfollow(userId);
      log("Follow/unfollow completed for user: $userId");
      
      // Log profile state after toggle
      final profileAfter = profileController.profile.value;
      final followingAfter = profileAfter?.following ?? [];
      final isFollowing = profileController.isCurrentUserFollowing(userId);
      log("After toggle - isFollowing: $isFollowing for user: $userId");
      log("After toggle - following count: ${followingAfter.length}, following list: $followingAfter");
      
      // Don't manually trigger - let ProfileController's profile update handle the reactive states
      log("Waiting for ProfileController to update profile naturally...");
      
    } catch (e) {
      log("Error in follow/unfollow: $e");
    } finally {
      followingInProgress[userId]!.value = false;
    }
  }
  
  void navigateToPetProfile(String petId) {
    Get.toNamed(AppRoutes.petProfile, arguments: petId);
  }
  
  Future<void> refreshPets() async {
    await fetchAllPets();
  }

  // Initialize follow states for all pet owners (now handled by ProfileController)
  void initializeFollowStates(List<PetModel> pets) {
    // This method is kept for compatibility but no longer needed
    // Follow states are now managed by ProfileController
    updateReactiveFollowStates();
    log("Follow states now managed by ProfileController");
  }
  
  // Update reactive follow states based on current profile
  void updateReactiveFollowStates() {
    final followingList = profileController.profile.value?.following ?? [];
    final newStates = <String, bool>{};
    
    for (var pet in allPets) {
      if (pet.user != null) {
        newStates[pet.user!] = followingList.contains(pet.user!);
      }
    }
    
    reactiveFollowStates.assignAll(newStates);
    log("Updated reactive follow states: $newStates");
  }
  
  // Getters for reactive UI
  List<PetModel> get allPetsList => allPets;
  List<PetModel> get filteredPetsList => filteredPets;
  String get currentSearchQuery => searchQuery.value;
  bool get isLoading => isLoadingPets.value;
  
  // Check if current user is following a pet owner
  Map<String, bool> get currentFollowStates {
    // Return the reactive map directly for maximum reactivity
    final trigger = profileUpdateTrigger.value; // Access for reactivity
    log("currentFollowStates called - trigger: $trigger, reactive states: ${reactiveFollowStates}");
    return Map<String, bool>.from(reactiveFollowStates);
  }
  
  // Force UI refresh method
  void refreshFollowStates() {
    profileUpdateTrigger.value++;
    log("Manual follow states refresh - trigger: ${profileUpdateTrigger.value}");
  }
  
  // Debug method to check current follow states
  void debugFollowStates() {
    final profile = profileController.profile.value;
    final followingList = profile?.following ?? [];
    final reactiveStates = reactiveFollowStates;
    final currentUserId = profileController.userCurrentId.value;
    
    log("=== DEBUG FOLLOW STATES ===");
    log("Current user ID: $currentUserId");
    log("Profile exists: ${profile != null}");
    log("Following list: $followingList");
    log("Following count: ${followingList.length}");
    log("Reactive states: $reactiveStates");
    log("Trigger value: ${profileUpdateTrigger.value}");
    
    for (var pet in allPets) {
      if (pet.user != null) {
        final isFollowing = followingList.contains(pet.user!);
        final reactiveState = reactiveStates[pet.user!] ?? false;
        final isCurrentUserPet = pet.user == currentUserId;
        log("Pet ${pet.name} (user: ${pet.user}): following=$isFollowing, reactive=$reactiveState, isCurrentUserPet=$isCurrentUserPet");
      }
    }
    log("=== END DEBUG ===");
  }
  
  Map<String, bool> get currentFollowingInProgress {
    // Force reactivity by accessing each reactive value
    final reactiveMap = <String, bool>{};
    followingInProgress.forEach((key, value) {
      reactiveMap[key] = value.value;
    });
    return reactiveMap;
  }
  
  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}