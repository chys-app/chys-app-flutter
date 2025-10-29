import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_places_autocomplete_widgets/model/place.dart';

import '../../../core/controllers/loading_controller.dart';
import '../../../data/models/pet_profile.dart';
import '../../../services/api_service.dart';
import '../../../services/short_message_utils.dart';
import '../../profile/controllers/profile_controller.dart';

class PetEditController extends GetxController {
  // Pet data
  final petData = Rxn<PetModel>();
  final isEditMode = true.obs;

  // API Service
  final _apiService = ApiService();

  // Image picker
  final _imagePicker = ImagePicker();
  final petPhoto = Rxn<File>();
  final photos = <File>[].obs;
  final networkImageUrl = Rxn<String>();
  final removedNetworkImages = <String>[].obs; // Track removed network images

  // Upload progress
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;
  final uploadStatus = ''.obs;
  final totalFiles = 0.obs;
  final uploadedFiles = 0.obs;

  // Form controllers
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final bioController = TextEditingController();
  final dobController = TextEditingController();
  final weightController = TextEditingController();
  final marksController = TextEditingController();
  final microchipController = TextEditingController(); // Deprecated: for single entry
  final microchipControllers = <TextEditingController>[].obs; // New: for multiple entries
  final tagIdController = TextEditingController();
  final vetNameController = TextEditingController();
  final vetContactController = TextEditingController();
  final personalityController = TextEditingController();
  final allergiesController = TextEditingController();
  final specialNeedsController = TextEditingController();
  final feedingController = TextEditingController();
  final routineController = TextEditingController();
  final ownerContactController = TextEditingController();
  final petColorController = TextEditingController();

  // Address controllers
  final streetController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();
  final zipCodeController = TextEditingController();

  // Observable variables
  final selectedPetType = ''.obs;
  final selectedSex = ''.obs;
  final selectedSize = ''.obs;
  final selectedHexColor = ''.obs;
  final weightInLbs = ''.obs; // derived display for weight
  final vaccinationStatus = 'Yes'.obs;
  final hasPet = true.obs;

  // Address fields
  final selectedState = ''.obs;
  final selectedCountry = ''.obs;
  final selectedCity = ''.obs;

  // Options
  final sexOptions = ['Male', 'Female'];
  final sizeOptions = ['Small', 'Medium', 'Large'];
  final vaccinationOptions = ['Yes', 'No'];
  final petTypeOptions = ['Dog', 'Cat', 'Other'];

  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPetData();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh pet data to ensure images are loaded
    _refreshPetData();
  }

  Future<void> _refreshPetData() async {
    try {
      final profileController = Get.find<ProfileController>();

      // Fetch fresh data from server first
      await profileController.fetchProfilee();

      final currentPet = profileController.userPet.value;

      if (currentPet != null) {
        petData.value = currentPet;

        // Update form fields with new data
        _populateFormWithPetData(currentPet);

        // Update network image URL with the latest profile pic
        if (currentPet.profilePic != null &&
            currentPet.profilePic!.isNotEmpty) {
          networkImageUrl.value = currentPet.profilePic;
          log("Refreshed pet data - Profile image URL: ${currentPet.profilePic}");
        } else {
          networkImageUrl.value = null;
        }

        // Clear any local changes that have been saved
        petPhoto.value = null;
        photos.clear();
        removedNetworkImages.clear();

        log("Pet data refreshed successfully from server: ${currentPet.name}");
      }
    } catch (e) {
      log("Error refreshing pet data: $e");
    }
  }

  void _loadPetData() {
    try {
      isLoading.value = true;
      final profileController = Get.find<ProfileController>();
      final currentPet = profileController.userPet.value;

      if (currentPet != null) {
        petData.value = currentPet;
        _populateFormWithPetData(currentPet);
        log("Pet data loaded successfully: ${currentPet.name}");
      } else {
        ShortMessageUtils.showError('No pet data found');
        Get.back();
      }
    } catch (e) {
      log("Error loading pet data: $e");
      ShortMessageUtils.showError('Failed to load pet data');
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  String _capitalizeFirst(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _populateFormWithPetData(PetModel pet) {
    try {
      // Basic info
      nameController.text = pet.name ?? '';
      breedController.text = pet.breed ?? '';
      bioController.text = pet.bio ?? '';
      petColorController.text = pet.color ?? '';

      // Date of birth
      if (pet.dateOfBirth != null) {
        dobController.text = DateFormat('yyyy-MM-dd').format(pet.dateOfBirth!);
      }

      // Physical attributes
      weightController.text = pet.weight?.toString() ?? '';
      // Initialize lbs display
      if (pet.weight != null) {
        final lbs = (pet.weight!.toDouble() * 2.2046226218);
        weightInLbs.value = lbs.toStringAsFixed(2) + ' lbs';
      } else {
        weightInLbs.value = '';
      }
      marksController.text = pet.marks ?? '';
      selectedSize.value = _capitalizeFirst(pet.size);
      selectedSex.value = _capitalizeFirst(pet.sex);
      selectedPetType.value = _capitalizeFirst(pet.petType);

      // Identification
      microchipController.text = pet.microchipNumber ?? '';
      
      // Initialize multiple microchip controllers
      microchipControllers.clear();
      if (pet.microchipNumbers != null && pet.microchipNumbers!.isNotEmpty) {
        // Use new microchipNumbers array if available
        for (var number in pet.microchipNumbers!) {
          final controller = TextEditingController(text: number);
          microchipControllers.add(controller);
        }
      } else if (pet.microchipNumber != null && pet.microchipNumber!.isNotEmpty) {
        // Fallback to single microchipNumber for backward compatibility
        final controller = TextEditingController(text: pet.microchipNumber);
        microchipControllers.add(controller);
      } else {
        // No microchip data, add one empty field
        microchipControllers.add(TextEditingController());
      }
      
      tagIdController.text = pet.tagId ?? '';

      // Veterinary info
      vetNameController.text = pet.vetName ?? '';
      vetContactController.text = pet.vetContactNumber ?? '';
      vaccinationStatus.value = pet.vaccinationStatus == true ? 'Yes' : 'No';

      // Behavioral info
      personalityController.text = pet.personalityTraits?.join(', ') ?? '';
      allergiesController.text = pet.allergies?.join(', ') ?? '';
      specialNeedsController.text = pet.specialNeeds ?? '';
      feedingController.text = pet.feedingInstructions ?? '';
      routineController.text = pet.dailyRoutine ?? '';

      // Contact info
      ownerContactController.text = pet.ownerContactNumber ?? '';

      // Address
      selectedState.value = pet.address?.state ?? '';
      selectedCountry.value = pet.address?.country ?? '';
      selectedCity.value = pet.address?.city ?? '';

      // Populate address controllers
      // Use pet's address data if available
      stateController.text = pet.address?.state ?? '';
      countryController.text = pet.address?.country ?? '';
      cityController.text = pet.address?.city ?? '';
      // Use pet's zip code from address object
      zipCodeController.text = pet.address?.zipCode ?? '';
      // Use pet's street from address object
      streetController.text = pet.address?.street ?? '';

      log("Pet address object - State: ${pet.address?.state}, Country: ${pet.address?.country}, City: ${pet.address?.city}, Zip: ${pet.address?.zipCode}, Street: ${pet.address?.street}");
      log("Address controllers populated - State: ${stateController.text}, Country: ${countryController.text}, City: ${cityController.text}, Zip: ${zipCodeController.text}, Street: ${streetController.text}");

      // Fallback: if pet address is completely empty, use user's profile address
      final profileCtrl = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : null;
      if ((stateController.text.isEmpty &&
              countryController.text.isEmpty &&
              cityController.text.isEmpty &&
              zipCodeController.text.isEmpty) &&
          profileCtrl?.profile.value != null) {
        stateController.text =
            profileCtrl!.profile.value!.state ?? '';
        countryController.text =
            profileCtrl.profile.value!.country ?? '';
        cityController.text =
            profileCtrl.profile.value!.city ?? '';
        zipCodeController.text =
            profileCtrl.profile.value!.zipCode ?? '';
        log("Fallback: Using user profile address - State: ${stateController.text}, Country: ${countryController.text}, City: ${cityController.text}, Zip: ${zipCodeController.text}");
        // Note: Street is not part of the pet address object, so we don't populate it from user profile
      }
      // Optional second fallback: try last known location if available
      // Not importing LocationController here to avoid extra dependency; profile controller already handles it.

      // Color
      selectedHexColor.value = pet.color ?? '';

      // Handle profile image - prioritize network URL
      if (pet.profilePic != null && pet.profilePic!.isNotEmpty) {
        networkImageUrl.value = pet.profilePic;
        log("Profile image URL set: ${pet.profilePic}");
      }

      // Handle additional photos
      if (pet.photos != null && pet.photos!.isNotEmpty) {
        log("Additional photos found: ${pet.photos!.length}");
        for (int i = 0; i < pet.photos!.length; i++) {
          log("Photo $i: ${pet.photos![i]}");
        }
      }

      log("Form populated successfully with pet data - Name: ${pet.name}, Breed: ${pet.breed}, ProfilePic: ${pet.profilePic}");
    } catch (e) {
      log("Error populating form with pet data: $e");
    }
  }

  void onWeightChanged(String value) {
    final kg = double.tryParse(value.trim());
    if (kg == null) {
      weightInLbs.value = '';
      return;
    }
    final lbs = kg * 2.2046226218;
    weightInLbs.value = lbs.toStringAsFixed(1);
  }

  Future<void> pickPetPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        petPhoto.value = File(image.path);
        // Clear network image when new photo is selected
        networkImageUrl.value = null;

        // Upload image immediately after picking
        await uploadPetProfileImage();
      }
    } catch (e) {
      log('Error picking image: $e');
      ShortMessageUtils.showError('Failed to pick image');
    }
  }

  /// Upload pet profile image separately using dedicated API
  Future<void> uploadPetProfileImage() async {
    if (petPhoto.value == null) {
      log("No pet profile photo to upload");
      return;
    }

    try {
      final loading = Get.find<LoadingController>();
      loading.show();

      log("Uploading pet profile image: ${petPhoto.value!.path}");

      // Use dedicated API service for image upload only
      final result = await _apiService.uploadPetProfileImage(
        petPhoto.value!,
      );

      log("Pet profile image upload result: $result");

      if (result['success']) {
        // Update the network image URL with the new URL
        final uploadedUrl =
            result['data']['profilePic'] ?? result['data']['imageUrl'];
        if (uploadedUrl != null) {
          networkImageUrl.value = uploadedUrl;
          log("Pet profile image uploaded successfully: $uploadedUrl");
          ShortMessageUtils.showSuccess("Pet profile picture updated!");
        }
      } else {
        log("Pet profile image upload failed: ${result['message']}");
        ShortMessageUtils.showError("Failed to upload pet profile picture");
      }

      loading.hide();
    } catch (e) {
      log("Error uploading pet profile image: $e");
      ShortMessageUtils.showError("Failed to upload pet profile picture");
      Get.find<LoadingController>().hide();
    }
  }

  Future<void> pickAdditionalPhotos() async {
    try {
      // Check current photo count
      final currentCount = getCurrentPhotoCount();
      final maxPhotos = 5;
      final remainingSlots = maxPhotos - currentCount;

      if (remainingSlots <= 0) {
        ShortMessageUtils.showError('Maximum 5 photos allowed');
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (images.isNotEmpty) {
        // Limit the number of photos that can be added
        final imagesToAdd = images.take(remainingSlots).toList();
        final photoFiles =
            imagesToAdd.map((image) => File(image.path)).toList();

        // Start upload with progress tracking
        await _uploadPhotosToServerWithProgress(photoFiles);
      }
    } catch (e) {
      log('Error picking additional images: $e');
      ShortMessageUtils.showError('Failed to pick images');
    }
  }

  /// Upload photos to server using dedicated API
  Future<void> _uploadPhotosToServer(List<File> photoFiles) async {
    if (photoFiles.isEmpty) {
      return;
    }

    try {
      log("Uploading photos to server: ${photoFiles.length} photos");

      final result = await _apiService.uploadPetPhotos(photoFiles);

      log("Photo upload result: $result");

      if (result['success']) {
        log("Photos uploaded successfully to server");
        // Refresh pet data to get updated photo list
        _refreshPetData();
      } else {
        log("Failed to upload photos to server: ${result['message']}");
        ShortMessageUtils.showError("Failed to upload photos to server");
      }
    } catch (e) {
      log("Error uploading photos to server: $e");
      ShortMessageUtils.showError("Failed to upload photos to server");
    }
  }

  /// Upload photos to server with progress tracking
  Future<void> _uploadPhotosToServerWithProgress(List<File> photoFiles) async {
    if (photoFiles.isEmpty) {
      return;
    }

    try {
      // Initialize progress tracking
      isUploading.value = true;
      uploadProgress.value = 0.0;
      totalFiles.value = photoFiles.length;
      uploadedFiles.value = 0;
      uploadStatus.value = 'Preparing upload...';

      log("Starting upload of ${photoFiles.length} photos");

      // Simulate progress for each file (since we can't track actual upload progress)
      for (int i = 0; i < photoFiles.length; i++) {
        final file = photoFiles[i];
        final fileName = file.path.split('/').last;

        // Update status for current file
        uploadStatus.value = 'Uploading ${fileName}...';
        uploadProgress.value = (i / photoFiles.length) * 100;
        uploadedFiles.value = i;

        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Final status
      uploadStatus.value = 'Finalizing upload...';
      uploadProgress.value = 95.0;

      // Actual upload
      final result = await _apiService.uploadPetPhotos(photoFiles);

      log("Photo upload result: $result");

      if (result['success']) {
        // Complete progress
        uploadProgress.value = 100.0;
        uploadStatus.value = 'Upload completed!';
        uploadedFiles.value = photoFiles.length;

        // Add to local list for UI display
        for (var photoFile in photoFiles) {
          photos.add(photoFile);
        }

        log("Photos uploaded successfully to server");

        // Show success message
        ShortMessageUtils.showSuccess(
            '${photoFiles.length} photos uploaded successfully!');

        // Refresh pet data to get updated photo list
        _refreshPetData();

        // Hide progress after a short delay
        await Future.delayed(const Duration(seconds: 1));
      } else {
        uploadStatus.value = 'Upload failed!';
        log("Failed to upload photos to server: ${result['message']}");
        ShortMessageUtils.showError("Failed to upload photos to server");
      }
    } catch (e) {
      uploadStatus.value = 'Upload failed!';
      log("Error uploading photos to server: $e");
      ShortMessageUtils.showError("Failed to upload photos to server");
    } finally {
      // Hide progress after a delay
      await Future.delayed(const Duration(seconds: 2));
      isUploading.value = false;
      uploadProgress.value = 0.0;
      uploadStatus.value = '';
      totalFiles.value = 0;
      uploadedFiles.value = 0;
    }
  }

  Future<void> editImage(int index) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final petData = this.petData.value;
        final networkPhotos = petData?.photos;
        final hasNetworkPhotos =
            networkPhotos != null && networkPhotos.isNotEmpty;

        // Get available network photos (excluding removed ones)
        final availableNetworkPhotos = hasNetworkPhotos
            ? networkPhotos
                .where((url) => !removedNetworkImages.contains(url))
                .toList()
            : <String>[];

        if (index < availableNetworkPhotos.length) {
          // This is a network image, we can't edit it directly
          // Instead, we'll add it as a new local photo
          photos.add(File(image.path));
          ShortMessageUtils.showSuccess('New photo added!');
        } else {
          // This is a local photo, we can replace it
          final localIndex = index - availableNetworkPhotos.length;
          if (localIndex < photos.length) {
            photos[localIndex] = File(image.path);
            ShortMessageUtils.showSuccess('Photo updated!');
          }
        }
      }
    } catch (e) {
      log('Error editing image: $e');
      ShortMessageUtils.showError('Failed to edit image');
    }
  }

  void removeImage(int index) {
    try {
      final petData = this.petData.value;
      final networkPhotos = petData?.photos;
      final hasNetworkPhotos =
          networkPhotos != null && networkPhotos.isNotEmpty;

      // Get available network photos (excluding removed ones)
      final availableNetworkPhotos = hasNetworkPhotos
          ? networkPhotos
              .where((url) =>
                  url.isNotEmpty &&
                  url != "[]" &&
                  !removedNetworkImages.contains(url))
              .toList()
          : <String>[];

      if (index < availableNetworkPhotos.length) {
        // This is a network image, remove it immediately via API
        final imageUrl = availableNetworkPhotos[index];
        log('Removing network image: $imageUrl');

        // Add to local removed list for immediate UI update
        if (!removedNetworkImages.contains(imageUrl)) {
          removedNetworkImages.add(imageUrl);
        }

        // Call API to remove the photo from server (don't await to prevent UI blocking)
        _removePhotoFromServer([imageUrl]).then((_) {
          // Success callback - no need to do anything since UI is already updated
          log('Photo removal completed successfully');
        }).catchError((error) {
          // Error callback - remove from local list if server call failed
          log('Photo removal failed: $error');
          removedNetworkImages.remove(imageUrl);
          ShortMessageUtils.showError('Failed to remove image from server');
        });

        ShortMessageUtils.showSuccess('Image removed');
      } else {
        // This is a local photo, we can remove it directly
        final localIndex = index - availableNetworkPhotos.length;
        if (localIndex < photos.length) {
          photos.removeAt(localIndex);
          ShortMessageUtils.showSuccess('Photo removed!');
        }
      }
    } catch (e) {
      log('Error removing image: $e');
      ShortMessageUtils.showError('Failed to remove image');
    }
  }

  /// Remove photos from server using dedicated API
  Future<void> _removePhotoFromServer(List<String> photoUrls) async {
    // Filter out empty or invalid URLs
    final validPhotoUrls =
        photoUrls.where((url) => url.isNotEmpty && url != "[]").toList();

    if (validPhotoUrls.isEmpty || petData.value?.id == null) {
      log("No valid photo URLs to remove or no pet ID");
      return;
    }

    try {
      log("Removing photos from server: $validPhotoUrls");

      // Use the dedicated removePetPhotos API
      final result = await _apiService.removePetPhotos(
        validPhotoUrls,
      );

      log("Photo removal result: $result");

      if (result['success']) {
        log("Photos removed successfully from server");

        // Don't refresh data immediately to prevent flickering
        // The UI is already updated with removedNetworkImages
        log("Photo removal completed - UI already updated");
      } else {
        log("Failed to remove photos from server: ${result['message']}");
        // Remove from local list if server call failed
        for (String url in validPhotoUrls) {
          removedNetworkImages.remove(url);
        }
        ShortMessageUtils.showError("Failed to remove photos from server");
      }
    } catch (e) {
      log("Error removing photos from server: $e");
      // Remove from local list if server call failed
      for (String url in validPhotoUrls) {
        removedNetworkImages.remove(url);
      }
      ShortMessageUtils.showError("Failed to remove photos from server");
    }
  }

  void restoreRemovedImage(String imageUrl) {
    if (removedNetworkImages.contains(imageUrl)) {
      removedNetworkImages.remove(imageUrl);
      ShortMessageUtils.showSuccess('Image restored!');
    }
  }

  /// Get current total photo count (local + network)
  int getCurrentPhotoCount() {
    final networkPhotos = petData.value?.photos ?? [];
    final availableNetworkPhotos = networkPhotos
        .where((url) =>
            url.isNotEmpty &&
            url != "[]" &&
            !removedNetworkImages.contains(url))
        .toList();
    return availableNetworkPhotos.length + photos.length;
  }

  /// Check if more photos can be added
  bool canAddMorePhotos() {
    return getCurrentPhotoCount() < 5;
  }

  /// Get remaining photo slots
  int getRemainingPhotoSlots() {
    return 5 - getCurrentPhotoCount();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Methods for managing multiple microchip numbers
  void addMicrochipField() {
    microchipControllers.add(TextEditingController());
  }

  void removeMicrochipField(int index) {
    if (microchipControllers.length > 1) {
      microchipControllers[index].dispose();
      microchipControllers.removeAt(index);
    }
  }

  void initializeMicrochipFields() {
    if (microchipControllers.isEmpty) {
      microchipControllers.add(TextEditingController());
    }
  }

  Future<void> savePetProfile() async {
    if (!_validateForm()) return;

    try {
      isSaving.value = true;
      Get.find<LoadingController>().show();

      // Collect all microchip numbers from controllers
      final microchipNumbers = <String>[];
      for (var controller in microchipControllers) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          microchipNumbers.add(value);
        }
      }

      final petData = <String, dynamic>{
        'isHavePet': hasPet.value,
        'petType': selectedPetType.value.toLowerCase(),
        'name': nameController.text.trim(),
        'breed': breedController.text.trim(),
        'sex': selectedSex.value.toLowerCase(),
        'dateOfBirth': dobController.text.trim(),
        'bio': bioController.text.trim(),
        'color': petColorController.text.trim(),
        'size': selectedSize.value.toLowerCase(),
        'weight': double.tryParse(weightController.text.trim()) ?? 0.0,
        'marks': marksController.text.trim(),
        'microchipNumber': microchipController.text.trim(), // Keep for backward compatibility
        'microchipNumbers': microchipNumbers, // New: array of microchip numbers
        'tagId': tagIdController.text.trim(),
        'lostStatus': false,
        'vaccinationStatus': vaccinationStatus.value == 'Yes',
        'vetName': vetNameController.text.trim(),
        'vetContactNumber': vetContactController.text.trim(),
        'personalityTraits': personalityController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'allergies': allergiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'specialNeeds': specialNeedsController.text.trim(),
        'feedingInstructions': feedingController.text.trim(),
        'dailyRoutine': routineController.text.trim(),
        'ownerContactNumber': ownerContactController.text.trim(),
        // Address data in nested structure - use cleaned data
        'address': _cleanAddressData(),
      };

      // Add pet ID for edit mode
      if (this.petData.value?.id != null) {
        petData['petId'] = this.petData.value!.id;
      }

      // Note: Profile image is now uploaded separately via uploadPetProfileImage()
      // No need to include profilePic in the main pet edit API call

      // Handle additional photos - use 'photos' field for API compatibility
      if (photos.isNotEmpty) {
        petData['photos'] = photos.map((file) => file.path).toList();
      }

      // Handle removed network images
      if (removedNetworkImages.isNotEmpty) {
        petData['removePhotos'] = removedNetworkImages.toList();
      }

      log("Saving pet data: $petData");
      log("Address data being saved - State: ${stateController.text}, Country: ${countryController.text}, City: ${cityController.text}, Zip: ${zipCodeController.text}");

      // Log image information
      if (petPhoto.value != null) {
        log("Profile photo path: ${petPhoto.value!.path}");
      }
      if (photos.isNotEmpty) {
        log("Additional photos count: ${photos.length}");
        for (int i = 0; i < photos.length; i++) {
          log("Photo $i: ${photos[i].path}");
        }
      }
      if (removedNetworkImages.isNotEmpty) {
        log("Removed network images: $removedNetworkImages");
      }

      final result = await _apiService.createPetProfile(
          petData, true); // true for edit mode

      if (result['success']) {
        Get.find<LoadingController>().hide();
        ShortMessageUtils.showSuccess('Pet profile updated successfully!');

        // Refresh profile data
        final profileController = Get.find<ProfileController>();
        await profileController.fetchProfilee();

        // Refresh local pet data with updated information
        _refreshPetData();

        // Clear local image data since they've been uploaded
        petPhoto.value = null;
        photos.clear();
        removedNetworkImages.clear();
        networkImageUrl.value = null;

        // Navigate to home page after successful save
        // You can change this to '/profile' if you prefer to go to profile page
        Get.offAllNamed('/home');
      } else {
        Get.find<LoadingController>().hide();
        ShortMessageUtils.showError(
            result['message'] ?? 'Failed to update pet profile');
      }
    } catch (e) {
      log("Error saving pet profile: $e");
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Failed to update pet profile');
    } finally {
      isSaving.value = false;
    }
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please enter pet name');
      return false;
    }

    if (breedController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please enter pet breed');
      return false;
    }

    if (dobController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please select date of birth');
      return false;
    }

    if (weightController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please enter pet weight');
      return false;
    }

    if (vetNameController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please enter vet name');
      return false;
    }

    if (vetContactController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please enter vet contact number');
      return false;
    }

    return true;
  }

  void selectPetType(String type) {
    selectedPetType.value = type;
  }

  void selectSex(String sex) {
    selectedSex.value = sex;
  }

  void selectSize(String size) {
    selectedSize.value = size;
  }

  void selectVaccinationStatus(String status) {
    vaccinationStatus.value = status;
  }

  void selectState(String state) {
    selectedState.value = state;
  }

  void selectCountry(String country) {
    selectedCountry.value = country;
  }

  void selectCity(String city) {
    selectedCity.value = city;
  }

  void goBack() {
    // Refresh data before going back to ensure consistency
    _refreshPetData();
    // Navigate to previous page in the flow
    Get.back();
  }

  // Method to refresh data when returning to edit screen
  Future<void> refreshEditData() async {
    try {
      isLoading.value = true;
      _refreshPetData();
    } catch (e) {
      log("Error refreshing edit data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Method to handle when user returns to edit screen
  Future<void> onScreenResumed() async {
    log("Pet edit screen resumed, refreshing data...");
    await refreshEditData();
  }

  // Method to refresh address fields specifically for EditOwnerInfoView
  void refreshAddressFields() {
    final pet = petData.value;
    if (pet != null) {
      log("Refreshing address fields for EditOwnerInfoView");
      _populateFormWithPetData(pet);
    }
  }

  // Address auto-complete suggestion handler for edit flow
  void onSuggestionClick(Place placeDetails) {
    log("Address suggestion clicked: ${placeDetails.formattedAddress}");

    // Fill the edit address fields from suggestion
    streetController.text = placeDetails.streetAddress ?? '';
    stateController.text = placeDetails.state ?? '';
    countryController.text = placeDetails.country ?? '';
    cityController.text = placeDetails.city ?? '';
    zipCodeController.text = placeDetails.zipCode ?? '';

    log("Address fields populated from autocomplete - Street: ${streetController.text}, State: ${stateController.text}, Country: ${countryController.text}, City: ${cityController.text}, Zip: ${zipCodeController.text}");
  }

  // Validate and clean address data before sending to API
  Map<String, dynamic> _cleanAddressData() {
    final address = <String, dynamic>{};
    
    // Only include non-empty address fields
    if (stateController.text.trim().isNotEmpty) {
      address['state'] = stateController.text.trim();
    }
    if (countryController.text.trim().isNotEmpty) {
      address['country'] = countryController.text.trim();
    }
    if (cityController.text.trim().isNotEmpty) {
      address['city'] = cityController.text.trim();
    }
    if (zipCodeController.text.trim().isNotEmpty) {
      address['zipCode'] = zipCodeController.text.trim();
    }
    if (streetController.text.trim().isNotEmpty) {
      address['street'] = streetController.text.trim();
    }
    
    log("🧹 Cleaned address data: $address");
    return address;
  }

  @override
  void onClose() {
    nameController.dispose();
    breedController.dispose();
    bioController.dispose();
    dobController.dispose();
    weightController.dispose();
    marksController.dispose();
    microchipController.dispose();
    tagIdController.dispose();
    vetNameController.dispose();
    vetContactController.dispose();
    personalityController.dispose();
    allergiesController.dispose();
    specialNeedsController.dispose();
    feedingController.dispose();
    routineController.dispose();
    ownerContactController.dispose();
    petColorController.dispose();

    // Dispose address controllers
    streetController.dispose();
    stateController.dispose();
    countryController.dispose();
    cityController.dispose();
    zipCodeController.dispose();

    super.onClose();
  }
}
