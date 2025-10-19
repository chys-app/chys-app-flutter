import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/data/models/pet_profile.dart';
import 'package:chys/app/services/api_service.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:chys/app/services/pet_ownership_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../routes/app_routes.dart';
import '../../../services/storage_service.dart';
import '../../profile/controllers/profile_controller.dart';

class MapController extends GetxController {
  GoogleMapController? mapController;
  final currentLocation = const LatLng(29.9986, 73.2536).obs;
  final markers = <Marker>{}.obs;
  final isLoading = false.obs;
  var petList = <PetModel>[].obs;
  var allPetList = <PetModel>[].obs;
  var isDataLoading = false.obs;
  var isPetLoading = false.obs;
  RxString selectedFeature = ''.obs;
  final RxBool isBusinessUser = false.obs;
  RxInt currentIndex = 0.obs;
  Timer? autoSlideTimer;
  bool _isMapInitialized = false;
  RxBool showAllActions = false.obs;
  
  void startAutoSlide(int maxIndex) {
    autoSlideTimer?.cancel();
    autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      currentIndex.value = (currentIndex.value + 1) % maxIndex;
    });
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  Future<void> _getCurrentLocation() async {
    try {
      log("📍 Getting current location...");
      await Future.delayed(const Duration(seconds: 5));
      log("📍 Requesting location permission...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        currentLocation.value = LatLng(position.latitude, position.longitude);
        log("📍 Current location obtained: ${currentLocation.value}");
        if (_isMapInitialized) {
          centerOnCurrentLocation();
        }
      } else {
        log("❌ Location permission denied");
        Get.snackbar(
          'Permission Denied',
          'Location access is required to use the map.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log("❌ Error getting location: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    _determineUserType();
    _getCurrentLocation();
  }

  @override
  void onReady() {
    super.onReady();
    // Fetch all pets after the view is ready
    fetchAllPets();
    
    // Focus on current location after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      centerOnCurrentLocation();
    });
  }

  void onMapCreated(GoogleMapController controller) {
    try {
      if (_isMapInitialized) {
        log("⚠️ Map already initialized. Skipping onMapCreated.");
        return;
      }

      log("✅ Map created");

      mapController = controller;
      _isMapInitialized = true;

      if (currentLocation.value.latitude != 0.0) {
        centerOnCurrentLocation();
      }
    } catch (e) {
      log("❌ Error in onMapCreated: $e");
    }
  }

  Future<void> fetchPetProfile({String? petId}) async {
    try {
      isDataLoading.value = true;

      // Build URL conditionally
      String url = petId == null || petId.isEmpty
          ? ApiEndPoints.petProfile
          : "${ApiEndPoints.petProfile}/$petId";

      log("Fetching pet profile from: $url");

      final response = await ApiClient().get(url);

      // Check if we got a 500 error response
      if (response == null) {
        log("❌ API returned null response - likely 500 error");
        await _fetchPetFromUserProfiles(petId);
        return;
      }

      // Debug: Log the raw response structure
      log("🔍 Raw API Response: $response");
      if (response != null && response.containsKey('pet')) {
        log("🔍 Pet data structure: ${response['pet']}");
        if (response['pet'] != null && response['pet'] is Map) {
          final petData = response['pet'] as Map;
          log("🔍 Pet address: ${petData['address']}");
          log("🔍 Pet photos: ${petData['photos']}");
          log("🔍 Pet personalityTraits: ${petData['personalityTraits']}");
          log("🔍 Pet allergies: ${petData['allergies']}");
        }
      }

      // Check if response is valid
      if (response == null) {
        log("❌ Response is null");
        petList.value = [];
        return;
      }

      // Check if response has error
      if (response.containsKey('error') || response.containsKey('message')) {
        log("❌ API Error: ${response['message'] ?? response['error']}");

        // Check if it's the specific "includes" error
        final errorMessage = response['message'] ?? response['error'] ?? '';
        if (errorMessage.toString().contains('includes')) {
          log("🔧 Detected 'includes' error - likely address object issue");

          // Try to fetch from user's pet profiles instead
          await _fetchPetFromUserProfiles(petId);
          return;
        }

        petList.value = [];
        return;
      }

      // Check if pet data exists
      if (!response.containsKey('pet') || response['pet'] == null) {
        log("❌ No pet data in response: $response");

        // Try alternative response structure (direct pet object)
        if (response.containsKey('_id') || response.containsKey('name')) {
          log("🔄 Trying direct pet object structure");
          try {
            final pet = PetModel.fromJson(response);
            petList.value = [pet];
            log("✅ Pet profile loaded successfully (direct structure): ${pet.name}");
            return;
          } catch (e) {
            log("❌ Failed to parse direct pet object: $e");
          }
        }

        petList.value = [];
        return;
      }

      try {
        final pet = PetModel.fromJson(response["pet"]);
        petList.value = [pet];
        log("✅ Pet profile loaded successfully: ${pet.name}");
      } catch (parseError) {
        log("❌ Error parsing pet data: $parseError");
        log("❌ Pet data: ${response['pet']}");
        petList.value = [];

        Get.snackbar(
          'Error',
          'Invalid pet data received. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    } catch (e) {
      log("❌ Error fetching pet profile: $e");
      petList.value = [];

      // Show user-friendly error message
      Get.snackbar(
        'Error',
        'Failed to load pet profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isDataLoading.value = false;
    }
  }

  /// Fallback method to fetch pet from user's pet profiles when direct API fails
  Future<void> _fetchPetFromUserProfiles(String? petId) async {
    try {
      log("🔄 Attempting to fetch pet from user profiles as fallback");

      // Get user profile which contains petProfiles array
      final profileController = Get.find<ProfileController>();
      await profileController.fetchProfilee();

      // Get pet profiles from the API response
      final response = await ApiClient().get(ApiEndPoints.editProfile);
      final petProfiles = response["petProfiles"];

      if (petProfiles is List && petProfiles.isNotEmpty) {
        // Find the specific pet by ID
        PetModel? targetPet;
        for (var petData in petProfiles) {
          if (petData['_id'] == petId) {
            targetPet = PetModel.fromJson(petData);
            break;
          }
        }

        // If specific pet not found, use the first one
        if (targetPet == null && petProfiles.isNotEmpty) {
          targetPet = PetModel.fromJson(petProfiles[0]);
        }

        if (targetPet != null) {
          petList.value = [targetPet];
          log("✅ Pet profile loaded from user profiles: ${targetPet.name}");

          Get.snackbar(
            'Info',
            'Pet profile loaded successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            duration: const Duration(seconds: 2),
          );
          return;
        }
      }

      log("❌ Pet not found in user profiles");
      petList.value = [];
    } catch (e) {
      log("❌ Error fetching pet from user profiles: $e");
      petList.value = [];
    }
  }

  Future<void> fetchAllPets() async {
    if (isPetLoading.value) return; // Prevent multiple simultaneous calls

    // Check if user is authenticated before making API call
    final apiService = ApiService();
    if (!apiService.isAuthenticated()) {
      log("⚠️ User not authenticated, skipping fetchAllPets");
      isPetLoading.value = false;
      return;
    }

    isPetLoading.value = true;
    log("Fetching all pets");
    try {
      // Fetch all pets from the pet-profile endpoint
      final response = await ApiClient().get(ApiEndPoints.nearbyPet);

      if (response != null && response['pets'] != null) {
        final petsJson = response['pets'] as List;
        log("All pets json is $petsJson");

        final List<PetModel> allPets =
            petsJson.map((petJson) => PetModel.fromJson(petJson)).toList();

        allPetList.value = allPets;
        _loadPetMarkers();
        log("✅ Loaded ${allPets.length} pets on map");
      } else if (response != null && response is List) {
        // If response is directly a list of pets
        final List<PetModel> allPets =
            response.map((petJson) => PetModel.fromJson(petJson)).toList();

        allPetList.value = allPets;
        _loadPetMarkers();
        log("✅ Loaded ${allPets.length} pets on map (direct list)");
      } else {
        log("❌ No pets found in response: $response");
        allPetList.value = [];
      }
    } catch (e) {
      log("❌ Error fetching all pets: $e");
      allPetList.value = [];

      // Show user-friendly error message
      Get.snackbar(
        'Error',
        'Failed to load pets. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isPetLoading.value = false;
    }
  }

  RxBool hideOtherImage = true.obs;

  void selectFeature(String feature) {
    if (selectedFeature.value == feature) {
      // Toggle showAllActions when tapping the selected icon
      showAllActions.value = !showAllActions.value;
    } else {
      selectedFeature.value = feature;
      showAllActions.value = false; // Hide others, show only selected
    }
    log("Feature is $feature");
    switch (feature) {
      case 'chat':
        onChatTap();
        break;
      case 'map':
        onAddPetTap();
        break;
      case 'user':
        onProfileTap();
        break;
      case 'add':
        onAddPostTap();
        break;
      case 'podcast':
        onPetsTap();
        break;
      case 'business':
        onBusinessHomeTap();
        break;
      case 'marketplace':
        onMarketplaceTap();
        break;
    }
  }

  Future<void> _loadPetMarkers() async {
    markers.clear();
    Set<String> usedLocations = {};

    log("Length is ${allPetList.length}");

    for (final pet in allPetList) {
      final location = pet.userModel?.location?.coordinates;
      final petName = pet.name ?? 'Unknown';
      final profileUrl = pet.profilePic ?? '';
      final petId = pet.id ?? '';
      final petType = pet.petType ?? 'Pet';
      final breed = pet.breed ?? '';
      
      log("Pet name is $petName and petId is $petId and location length is ${location?.length}");
      if (location != null && location.length == 2) {
        double lng = location[0];
        double lat = location[1];

        // Offset step to avoid overlapping markers
        const double offsetStep = 0.0009;
        String locKey = '$lat:$lng';
        int offsetIndex = 1;

        while (usedLocations.contains(locKey)) {
          lat += offsetStep * offsetIndex;
          lng += offsetStep * offsetIndex;
          locKey = '$lat:$lng';
          offsetIndex++;
        }

        usedLocations.add(locKey);

        // Create enhanced marker with story indicator and status
        final Uint8List markerIcon = await _createEnhancedMarkerIcon(
          profileUrl, 
          petName, 
          petType,
          hasStory: _hasPetStory(pet), // Check if pet has recent activity
          isOnline: _isPetOnline(pet), // Check if pet owner is online
        );

        final Marker marker = Marker(
          markerId: MarkerId(petId.isNotEmpty ? petId : UniqueKey().toString()),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.fromBytes(markerIcon),
          infoWindow: InfoWindow(
            title: petName,
            snippet: "$petType • $breed",
          ),
          onTap: () {
            log("Pet name is $petName");
            _showPetPreview(pet);
          },
        );

        markers.add(marker);
      }
    }
    log("Markers length is ${markers.length}");
  }

  /// Create enhanced marker icon with story indicator and status
  Future<Uint8List> _createEnhancedMarkerIcon(
    String profileUrl, 
    String petName, 
    String petType, {
    bool hasStory = false,
    bool isOnline = false,
  }) async {
    const int size = 120;
    const double markerSize = 120.0;
    
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint();

    // Background circle with gradient
    final Rect rect = Rect.fromLTWH(0, 0, markerSize, markerSize);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0095F6),
        const Color(0xFF00C851),
      ],
    );
    
    paint.shader = gradient.createShader(rect);
    canvas.drawCircle(Offset(markerSize/2, markerSize/2), markerSize/2, paint);

    // Profile image circle
    try {
      final Uint8List profileBytes = await _getBytesFromNetworkImage(profileUrl, size: 100);
      final ui.Codec codec = await ui.instantiateImageCodec(profileBytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image profileImage = fi.image;

      // Create circular profile image
      final ui.PictureRecorder profileRecorder = ui.PictureRecorder();
      final Canvas profileCanvas = Canvas(profileRecorder);
      final Paint profilePaint = Paint();
      
      final double profileRadius = 45;
      final Rect profileRect = Rect.fromLTWH(0, 0, profileRadius * 2, profileRadius * 2);
      
      // Draw profile image in circle
      profileCanvas.drawCircle(Offset(profileRadius, profileRadius), profileRadius, profilePaint);
      profilePaint.blendMode = BlendMode.srcIn;
      profileCanvas.drawImageRect(
        profileImage,
        Rect.fromLTWH(0, 0, profileImage.width.toDouble(), profileImage.height.toDouble()),
        profileRect,
        profilePaint,
      );

      final ui.Image circularProfile = await profileRecorder.endRecording().toImage(
        (profileRadius * 2).toInt(), 
        (profileRadius * 2).toInt()
      );
      
      // Draw profile on main canvas
      canvas.drawImage(
        circularProfile, 
        Offset((markerSize - profileRadius * 2) / 2, (markerSize - profileRadius * 2) / 2), 
        Paint()
      );
    } catch (e) {
      // Fallback to initials if image fails
      _drawInitialsAvatar(canvas, petName, markerSize);
    }

    // Story indicator (colored ring)
    if (hasStory) {
      paint.shader = null;
      paint.color = const Color(0xFFFF6B35);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 4;
      canvas.drawCircle(Offset(markerSize/2, markerSize/2), markerSize/2 - 2, paint);
    }

    // Online status indicator
    if (isOnline) {
      paint.color = const Color(0xFF00C851);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(markerSize - 15, 15), 8, paint);
      
      // White border
      paint.color = Colors.white;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      canvas.drawCircle(Offset(markerSize - 15, 15), 8, paint);
    }

    final ui.Image enhancedMarker = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await enhancedMarker.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Draw initials avatar as fallback
  void _drawInitialsAvatar(Canvas canvas, String petName, double size) {
    final Paint paint = Paint();
    paint.color = const Color(0xFFE0E0E0);
    canvas.drawCircle(Offset(size/2, size/2), size/2 - 10, paint);
    
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: _getPetInitials(petName),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      )
    );
  }

  /// Get pet initials
  String _getPetInitials(String petName) {
    if (petName.isEmpty) return "P";
    final words = petName.split(' ');
    if (words.length >= 2) {
      return "${words[0][0]}${words[1][0]}".toUpperCase();
    }
    return petName[0].toUpperCase();
  }

  /// Check if pet has recent activity (story)
  bool _hasPetStory(PetModel pet) {
    // Simulate story availability based on recent activity
    // In real app, this would check for recent posts, updates, etc.
    return DateTime.now().millisecondsSinceEpoch % 3 == 0; // 33% chance
  }

  /// Check if pet owner is online
  bool _isPetOnline(PetModel pet) {
    // Simulate online status
    // In real app, this would check user's last activity
    return DateTime.now().millisecondsSinceEpoch % 4 == 0; // 25% chance
  }

  /// Calculate pet age from date of birth
  String _calculatePetAge(DateTime dateOfBirth) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateOfBirth);
      final years = difference.inDays ~/ 365;
      
      if (years == 0) {
        final months = difference.inDays ~/ 30;
        if (months == 0) {
          return "${difference.inDays} days old";
        }
        return "$months months old";
      }
      
      return "$years years old";
    } catch (e) {
      return "Unknown age";
    }
  }

  Future<Uint8List> _getBytesFromNetworkImage(String imageUrl,
      {int size = 150}) async {
    try {
      if (imageUrl.isEmpty) {
        log("⚠️ Empty imageUrl, using fallback.");
        return await _getBytesFromAssetImage(AppImages.profile, size);
      }

      final http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        log("⚠️ Failed to fetch network image, using fallback for $imageUrl");
        return await _getBytesFromAssetImage(AppImages.profile, size);
      }

      return await _convertToCircularBytes(response.bodyBytes, size);
    } catch (e) {
      log('❌ Error loading network image: $e');
      return await _getBytesFromAssetImage('assets/images/fallback.png', size);
    }
  }

  Future<Uint8List> _getBytesFromAssetImage(String path, int size) async {
    final ByteData byteData = await rootBundle.load(path);
    return await _convertToCircularBytes(byteData.buffer.asUint8List(), size);
  }

  Future<Uint8List> _convertToCircularBytes(
      Uint8List imageData, int size) async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageData,
      targetWidth: size,
      targetHeight: size,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint();

    final double radius = size / 2;
    final Rect rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

    canvas.drawCircle(Offset(radius, radius), radius, paint);
    paint.blendMode = BlendMode.srcIn;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      paint,
    );

    final ui.Image circularImage =
        await recorder.endRecording().toImage(size, size);
    final ByteData? byteData =
        await circularImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void centerOnCurrentLocation() {
    if (mapController != null && _isMapInitialized) {
      log("📍 Centering map on current location: ${currentLocation.value}");
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, 12), // Better zoom level
      );
    } else {
      log("⚠️ Cannot center map - controller not ready");
    }
  }


  // Action button handlers
  void onSettingsTap() => Get.toNamed(AppRoutes.settings);
  void onNotificationsTap() => Get.toNamed(AppRoutes.notifications);
  void onAddPetTap() => Get.toNamed(AppRoutes.map);
  void onProfileTap() => Get.toNamed(AppRoutes.home);
  void onBusinessHomeTap() => Get.toNamed(AppRoutes.businessHome);
  void onPetsTap() {
    final petService = PetOwnershipService.instance;
    if (petService.canCreatePodcasts) {
      Get.toNamed(AppRoutes.allPodcast);
    } else {
     // petService.showPodcastRestriction();
    }
  }

  void onAddPostTap() {
    final petService = PetOwnershipService.instance;
    if (petService.canCreatePosts) {
      Get.toNamed(AppRoutes.addPost);
    } else {
     // petService.showPostRestriction();
    }
  }

  void onChatTap() => Get.toNamed(AppRoutes.chat);

  void onMarketplaceTap() => Get.toNamed(AppRoutes.marketplace);

  void _determineUserType() {
    final user = StorageService.getUser();
    final role = user != null ? user['role']?.toString().toLowerCase() : null;
    isBusinessUser.value = role == 'biz-user';
  }

  /// Refresh all pets data
  Future<void> refreshPets() async {
    log("🔄 Refreshing pets data...");
    await fetchAllPets();
  }

  /// Show enhanced pet preview modal
  void _showPetPreview(PetModel pet) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Enhanced handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            // Enhanced pet header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8FAFC),
                    Colors.white,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Enhanced pet profile image with story ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _hasPetStory(pet) ? const Color(0xFFFF6B35) : Colors.grey.shade300,
                        width: _hasPetStory(pet) ? 4 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: pet.profilePic?.isNotEmpty == true 
                          ? NetworkImage(pet.profilePic!)
                          : null,
                      child: pet.profilePic?.isEmpty == true 
                          ? Text(
                              _getPetInitials(pet.name ?? ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Enhanced pet info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pet.name ?? 'Unknown Pet',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_isPetOnline(pet)) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C851),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C851).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${pet.petType ?? 'Pet'} • ${pet.breed ?? 'Unknown Breed'}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (pet.dateOfBirth != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.cake, color: Colors.grey.shade600, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _calculatePetAge(pet.dateOfBirth!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Enhanced action buttons
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            Get.back();
                            Get.toNamed(AppRoutes.homeDetail, arguments: pet.id);
                          },
                          icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            Get.back();
                            // Navigate to chat with pet owner
                            if (pet.userModel?.id != null) {
                              Get.toNamed(AppRoutes.chatDetail, arguments: {
                                "id": pet.userModel!.id,
                                "name": pet.userModel!.name,
                              });
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Enhanced pet photos carousel
            if (pet.photos != null && pet.photos!.isNotEmpty) ...[
              Container(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: pet.photos!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          pet.photos![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.grey.shade200, Colors.grey.shade300],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Enhanced pet details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced personality traits
                    if (pet.personalityTraits != null && pet.personalityTraits!.isNotEmpty) ...[
                      const Text(
                        "Personality",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: pet.personalityTraits!.map((trait) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            trait,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Enhanced location info
                    if (pet.userModel?.location != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Location",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Location available",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Enhanced owner info
                    if (pet.userModel != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: AppColors.blue,
                              child: Text(
                                _getPetInitials(pet.userModel!.name ?? ''),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Owner",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pet.userModel!.name ?? 'Unknown Owner',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "Pet Parent",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Enhanced action buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.toNamed(AppRoutes.homeDetail, arguments: pet.id);
                        },
                        icon: const Icon(Icons.visibility, color: Colors.white),
                        label: const Text(
                          "View Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          if (pet.userModel?.id != null) {
                            Get.toNamed(AppRoutes.chatDetail, arguments: {
                              "id": pet.userModel!.id,
                              "name": pet.userModel!.name,
                            });
                          }
                        },
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          "Message",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  void onClose() {
    try {
      _isMapInitialized = false;
      if (mapController != null) {
        mapController!.dispose();
        mapController = null;
      }
      autoSlideTimer?.cancel();
      super.onClose();
    } catch (e) {
      log("Error in onClose: $e");
    }
  }
}
