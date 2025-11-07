import 'dart:developer';
import 'package:get/get.dart';
import '../../data/models/pet_profile.dart';
import '../../services/custom_Api.dart';
import '../../services/http_service.dart';
import '../../services/storage_service.dart';
import '../map/controllers/map_controller.dart';
import '../../routes/app_routes.dart';

class SearchController extends GetxController {
  // Search query
  final searchQuery = ''.obs;
  
  // Loading state
  final isLoadingPets = false.obs;
  
  // Map controller for bottom navigation
  late final MapController mapController;
  
  // All pets data
  final RxList<PetModel> allPets = <PetModel>[].obs;
  final RxList<PetModel> filteredPets = <PetModel>[].obs;
  
  // Track follow state for pet owners
  final Map<String, RxBool> followStates = {};
  final Map<String, RxBool> followingInProgress = {};
  
  // Services
  final CustomApiService _customApiService = CustomApiService();
  final ApiClient _apiClient = ApiClient();
  
  @override
  void onInit() {
    super.onInit();
    
    // Initialize MapController for bottom navigation
    if (Get.isRegistered<MapController>()) {
      mapController = Get.find<MapController>();
    } else {
      mapController = Get.put(MapController());
    }
    
    // Fetch all pets when controller initializes
    fetchAllPets();
    
    // Listen to search query changes
    ever(searchQuery, (_) => filterPets());
  }
  
  Future<void> fetchAllPets() async {
    try {
      isLoadingPets.value = true;
      
      // Log JWT token for debugging
      final token = StorageService.getToken();
      log("JWT Token: $token");
      log("Fetching all pets from API endpoint: ${ApiEndPoints.nearbyPet}");
      
      final response = await _apiClient.get(ApiEndPoints.nearbyPet);
      log("AllPets response: $response");
      log("Response type: ${response.runtimeType}");
      log("Response keys: ${response is Map ? response.keys.toList() : 'Not a map'}");
      
      if (response != null) {
        List<PetModel> pets = [];
        
        // Handle different response structures
        if (response['pets'] is List) {
          log("Found petProfiles array with ${(response['pets'] as List).length} items");
          pets = (response['pets'] as List)
              .map((pet) => PetModel.fromJson(pet as Map<String, dynamic>))
              .toList();
        } else if (response['pets'] is Map) {
          // Single pet profile response
          log("Found single petProfile object");
          pets = [PetModel.fromJson(response['petProfile'] as Map<String, dynamic>)];
        } else if (response['data'] is List) {
          log("Found data array with ${(response['data'] as List).length} items");
          pets = (response['data'] as List)
              .map((pet) => PetModel.fromJson(pet as Map<String, dynamic>))
              .toList();
        } else if (response is List) {
          log("Response is a direct list with ${(response as List).length} items");
          pets = (response as List)
              .map((pet) => PetModel.fromJson(pet as Map<String, dynamic>))
              .toList();
        } else {
          log("Unknown response structure. Response: $response");
        }
        
        allPets.value = pets;
        filteredPets.value = pets;
        log("Successfully loaded ${pets.length} pets");
        
        // Initialize follow states for all pet owners
        initializeFollowStates(pets);
        
        // Debug: Log pet user IDs
        for (var pet in pets) {
          log("Pet: ${pet.name}, User ID: ${pet.user}, Has UserModel: ${pet.userModel != null}, Photos count: ${pet.photos?.length ?? 0}, First photo: ${(pet.photos?.isNotEmpty == true) ? pet.photos!.first : 'none'}");
        }
      } else {
        log("Failed to fetch pets: response is null");
      }
    } catch (e, stackTrace) {
      log("Error fetching all pets: $e");
      log("Stack trace: $stackTrace");
    } finally {
      isLoadingPets.value = false;
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
    log("Follow button tapped for userId: $userId");
    
    if (followingInProgress[userId]?.value == true) {
      log("Follow request already in progress for userId: $userId");
      return;
    }
    
    // Initialize follow state if it doesn't exist
    if (!followStates.containsKey(userId)) {
      followStates[userId] = false.obs;
      followingInProgress[userId] = false.obs;
    }
    
    try {
      followingInProgress[userId]!.value = true;
      
      // Call the dedicated service method
      final newFollowState = await _customApiService.toggleFollow(userId);
      followStates[userId]!.value = newFollowState;
      
      log("Follow toggle completed. New state: $newFollowState");
      log("Updated followStates[userId]!.value to: ${followStates[userId]!.value}");
      log("Current follow states map: ${followStates.map((k, v) => MapEntry(k, v.value))}");
    } catch (e) {
      log("Error in follow/unfollow: $e");
      // Revert to previous state on error
      final currentState = followStates[userId]!.value;
      followStates[userId]!.value = !currentState;
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

  // Initialize follow states for pet owners
  void initializeFollowStates(List<PetModel> pets) {
    for (var pet in pets) {
      if (pet.user != null && !followStates.containsKey(pet.user!)) {
        // Initialize with false (not following) by default
        // In a real app, you might fetch this from the API
        followStates[pet.user!] = false.obs;
        followingInProgress[pet.user!] = false.obs;
      }
    }
    log("Initialized follow states for ${followStates.length} users");
  }
  
  // Getters for the widget
  List<PetModel> get allPetsList => allPets.toList();
  List<PetModel> get filteredPetsList => filteredPets.toList();
  bool get isLoading => isLoadingPets.value;
  String get currentSearchQuery => searchQuery.value;
  
  // Make follow states reactive by adding a trigger
  Map<String, bool> get currentFollowStates {
    // Force reactivity by accessing each reactive value
    final reactiveMap = <String, bool>{};
    followStates.forEach((key, value) {
      reactiveMap[key] = value.value;
    });
    return reactiveMap;
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