import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:chys/app/services/api_service.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:chys/app/services/short_message_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_places_autocomplete_widgets/model/place.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/controllers/loading_controller.dart';
import '../../../data/controllers/location_controller.dart';
import '../../../services/common_service.dart';
import '../../../services/storage_service.dart';
import '../../profile/controllers/profile_controller.dart';

class SignupController extends GetxController {
  final _imagePicker = ImagePicker();
  final ApiService _apiService;
  final LocationController controller;
  // TODO: CRITICAL Remove this before checking in
  static const bool bypassEmailVerification = true;
  // Loading states
  final isLoading = false.obs;
  final isFormValid = false.obs;
  final showPassword = false.obs;
  final showConfirmPassword = false.obs;
  RxBool isEditProfile = false.obs;
  // Step tracking
  final currentStep = 0.obs;
  String userToken = "";
  // Signup form controllers
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final bioController = TextEditingController();
  final dobController = TextEditingController();
  final otpController = TextEditingController();
  RxString selectedHexColor = '#FF6B81'.obs; // default color (pink-ish)

  SignupController({ApiService? apiService, LocationController? locationController})
      : _apiService = apiService ?? ApiService(),
        controller = locationController ?? Get.find<LocationController>();

  // OTP resend timer
  final RxInt otpSecondsRemaining = 60.obs;
  final RxBool canResendOtp = false.obs;
  Timer? _otpTimer;

  void openColorPicker(BuildContext context) {
    Color currentColor = hexToColor(selectedHexColor.value);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pick a Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              selectedHexColor.value = colorToHex(color);
            },
            enableAlpha: false,
            labelTypes: const [ColorLabelType.hex],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // add alpha
    return Color(int.parse(hex, radix: 16));
  }

  var selectedSize = 'Medium'.obs;
  var weight = ''.obs;
  var marks = ''.obs;
  var weightInLbs = ''.obs;
  void onWeightChanged(String value) {
    final kg = double.tryParse(value);
    if (kg != null) {
      final lbs = CommonService.kgToLbs(kg);
      weightInLbs.value = '$lbs lbs';
    } else {
      weightInLbs.value = '';
    }
  }

  var photos = <File>[].obs;
  var microchipNumber = ''.obs; // Deprecated: kept for backward compatibility
  var microchipNumbers = <String>[].obs; // New: supports multiple microchip numbers
  var tagId = ''.obs;
  var lostStatus = 'Medium'.obs;
  var vaccinationStatus = 'Yes'.obs;
  var vetName = ''.obs;
  var vetContactNumber = ''.obs;
  final lostStatusOptions = ['Low', 'Medium', 'High'];
  final vaccinationStatusOptions = ['Yes', 'No'];
  final sizeOptions = ['Small', 'Medium', 'Large'];
  var selectedSex = 'Male'.obs;
  var isNeutered = false.obs;
  var selectedDate = Rxn<DateTime>();
  // Policy agreements
  final agreePolicy1 = false.obs;
  final agreePolicy2 = false.obs;
  final agreePolicy3 = false.obs;
  // Pet ownership step
  final hasPet = false.obs;
  final isBusinessOwner = false.obs;
  final hasSelectedPetOwnership = false.obs;
  // Pet selection step
  final selectedPetType = ''.obs;
  // Pet Profile
  final petPhoto = Rxn<File>();
  final petName = ''.obs;
  final breed = ''.obs;
  final bio = ''.obs;
  final weightController = TextEditingController();
  final marksController = TextEditingController();
  final petColor = TextEditingController();
  // Identification & Safety fields
  final microchipController = TextEditingController(); // Deprecated: for single entry
  final microchipControllers = <TextEditingController>[].obs; // New: for multiple entries
  final tagIdController = TextEditingController();
  final vetNameController = TextEditingController();
  final vetContactController = TextEditingController();
  // Behavioral Care Controllers
  final personalityController = TextEditingController();
  final allergiesController = TextEditingController();
  final specialNeedsController = TextEditingController();
  final feedingController = TextEditingController();
  final routineController = TextEditingController();
  // Owner Info Controllers
  final ownerContactController = TextEditingController();
  final breedTextController = TextEditingController();
  final streetController = TextEditingController();
  final zipCodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final isAddressPrivate = false.obs;
  final selectedCity = ''.obs;
  final selectedState = ''.obs;
  final selectedCountry = ''.obs;
  // Map Related
  GoogleMapController? mapController;
  final currentLocation = const LatLng(0, 0).obs;
  final markers = <Marker>{}.obs;
  // Dropdown Options

  void onSuggestionClick(Place placeDetails) {
    streetController.text = placeDetails.streetAddress ?? '';
    cityController.text = placeDetails.city ?? '';
    stateController.text = placeDetails.state ?? '';
    zipCodeController.text = placeDetails.zipCode ?? '';
    countryController.text = placeDetails.country ?? '';
  }

  final countries = ['United States'].obs;
  var filteredCities = <String>[].obs;

  // void filterCitiesByState(String state) {
  //   final filtered = cities
  //       .where((e) => e['state'] == state)
  //       .map((e) => e['city']!)
  //       .toList();
  //   filteredCities.assignAll(filtered);
  //   selectedCity.value = '';
  // }

  // Dog Breeds Selection
  final selectedBreeds = <String>[].obs;
  void toggleBreedSelection(String breed) {
    if (selectedBreeds.contains(breed)) {
      selectedBreeds.remove(breed);
    } else {
      selectedBreeds.add(breed);
    }
  }

  Future<void> saveDogBreedsAndNavigate() async {
    final loading = Get.find<LoadingController>();
    try {
      if (selectedBreeds.isEmpty) {
        Get.snackbar('Error', 'Please select at least one breed',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      isLoading.value = true;
      loading.show();
      await Future.delayed(const Duration(milliseconds: 800));
      loading.hide();
      Get.snackbar('Success', 'Breeds saved!',
          backgroundColor: Colors.green, colorText: Colors.white);
      // Navigate to city view and remove previous routes from stack
      // await Get.offAllNamed(AppRoutes.cityView);
    } catch (e) {
      loading.hide();
      Get.snackbar('Error', 'Failed to save breeds',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp(bool isSignup) async {
    final loading = Get.find<LoadingController>();

    try {
      loading.show();
      final response = await ApiClient().post(ApiEndPoints.verifyEmail, {
        "otp": otpController.text
      }, customHeaders: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      });
      log("Response for this is $response");
      StorageService.saveToken(userToken);
      if (isSignup) {
        Get.offAllNamed(AppRoutes.petOwnership);
      } else {
        Future.microtask(() => Get.find<MapController>().selectFeature("user"));
      }

      loading.hide();
    } catch (e) {
      loading.hide();
    }
  }

  void startOtpTimer() {
    otpSecondsRemaining.value = 60;
    canResendOtp.value = false;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpSecondsRemaining.value > 0) {
        otpSecondsRemaining.value--;
      } else {
        canResendOtp.value = true;
        _otpTimer?.cancel();
      }
    });
  }

  void stopOtpTimer() {
    _otpTimer?.cancel();
    canResendOtp.value = true;
  }

  Future<void> resendOtp({bool isSignup = true}) async {
    await sendOtp(isSignup: isSignup);
    startOtpTimer();
  }

  Future<void> sendOtp({bool isSignup = true}) async {
    final loading = Get.find<LoadingController>();
    try {
      loading.show();
      final response = await ApiClient()
          .post(ApiEndPoints.sendVerificationOtp, {}, customHeaders: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      });
      loading.hide();
      Get.toNamed(AppRoutes.verifyOtpView, arguments: {"isSignup": isSignup});
      log("Response for sending otp is $response");
      startOtpTimer();
    } catch (e) {
      ShortMessageUtils.showError("$e");
      loading.hide();
    }
  }

  Future<void> loginWithGoogle() async {
    final loading = Get.find<LoadingController>();
    try {
      loading.show();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        userName = googleUser.displayName ?? "";
        userEmail = googleUser.email;
        userPassword = googleUser.email;
        loading.hide();
        await handleSignup(isSocial: true);
        log("✅ Google login successful!");
        log("Access Token: ${googleAuth.accessToken}");
        log("ID Token: ${googleAuth.idToken}");
        log("User ID: ${googleUser.id}");
        log("Name: ${googleUser.displayName}");
        log("Email: ${googleUser.email}");
        log("Photo URL: ${googleUser.photoUrl}");
        // Optional: send googleAuth.idToken to your backend for verification
      } else {
        loading.hide();
        log("❌ Google sign-in canceled by user.");
      }
    } catch (e) {
      loading.hide();
      log("🔥 Google login error: $e");
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA256 hash of the nonce
  String sha256ofNonce(String nonce) {
    final bytes = utf8.encode(nonce);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInWithApple() async {
    final loading = Get.find<LoadingController>();

    try {
      loading.show();
      final rawNonce = generateNonce();
      final hashedNonce = sha256ofNonce(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      userName = "${credential.givenName} ${credential.familyName}";
      emailController.text = credential.email!;
      passwordController.text = credential.email!;
      confirmPasswordController.text = credential.email!;
      loading.hide();
      await handleSignup(isSocial: true);
      log("✅ Apple Sign-In Successful!");
      log("User ID: ${credential.userIdentifier}");
      log("Email: ${credential.email}");
      log("Full Name: ${credential.givenName} ${credential.familyName}");
      log("Identity Token: ${credential.identityToken}");
      log("Authorization Code: ${credential.authorizationCode}");
      log("Raw Nonce (send to backend): $rawNonce");
      loading.hide();
    } catch (e) {
      loading.hide();
      log("🔥 Apple Sign-In Error: $e");
    }
  }

  Future<void> finishSignup() async {
    final loading = Get.find<LoadingController>();
    try {
      isLoading.value = true;
      loading.show();
      await Future.delayed(const Duration(milliseconds: 800));
      loading.hide();
      Get.snackbar('Success', 'Welcome!',
          backgroundColor: Colors.green, colorText: Colors.white);
      // Navigate to map page with binding and remove previous routes from stack
      Get.put(MapController()).selectFeature("user");
    } catch (e) {
      loading.hide();
      Get.snackbar('Error', 'Failed to complete setup',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _getCurrentLocation();
    _loadDraft();
    // filteredCities.assignAll(cities.map((e) => e['city']!).toList());

    isLoading.value = false;
  }

  void _initializeControllers() {
    usernameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  void goBack() {
    final currentRoute = Get.currentRoute;
    final previousRoute = AppRoutes.getPreviousSignupRoute(currentRoute);
    isLoading.value = false;
    Get.find<LoadingController>().hide();
    if (previousRoute != null) {
      Get.offAndToNamed(previousRoute);
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
    // streetController.dispose();
    zipCodeController.dispose();
    mapController?.dispose();
    _otpTimer?.cancel();
    Get.find<LoadingController>().hide();
    super.onClose();
  }

  // Step 1 variables
  final name = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final address = ''.obs;

  // Pet Profile variables
  final isSpayedNeutered = false.obs;

  // Step 2 variables
  final language = 'en'.obs;
  final theme = 'system'.obs;
  final pushNotifications = true.obs;
  final emailNotifications = true.obs;

  // Step 1 methods
  void updateName(String value) => name.value = value;
  void updateEmail(String value) => email.value = value;
  void updatePhone(String value) => phone.value = value;
  void updateAddress(String value) => address.value = value;

  // Step 2 methods
  void updateLanguage(String? value) => language.value = value ?? 'en';
  void updateTheme(String? value) => theme.value = value ?? 'system';
  void togglePushNotifications(bool? value) =>
      pushNotifications.value = value ?? true;
  void toggleEmailNotifications(bool? value) =>
      emailNotifications.value = value ?? true;

  // Validation methods
  bool get isStep1Valid {
    return name.value.isNotEmpty &&
        email.value.isNotEmpty &&
        phone.value.isNotEmpty &&
        address.value.isNotEmpty;
  }

  bool get isStep2Valid {
    return language.value.isNotEmpty && theme.value.isNotEmpty;
  }

  // Navigation methods
  // void goToStep2() {
  //   if (isStep1Valid) {
  //     Get.toNamed(AppRoutes.step2);
  //   }
  // }

  void goToStep3() {
    if (isStep2Valid) {
      Get.toNamed(AppRoutes.petProfile);
    }
  }

  Future<void> pickPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        // Limit to 5 photos
        final remainingSlots = 5 - photos.length;
        if (remainingSlots > 0) {
          final newPhotos =
              images.take(remainingSlots).map((e) => File(e.path)).toList();
          photos.addAll(newPhotos);

          if (images.length > remainingSlots) {
            Get.snackbar('Info', 'Maximum 5 photos allowed',
                backgroundColor: Colors.blue, colorText: Colors.white);
          }
        } else {
          Get.snackbar('Info', 'Maximum 5 photos already selected',
              backgroundColor: Colors.blue, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void updateSize(String value) => selectedSize.value = value;
  void updateWeight(String value) => weight.value = value;
  void updateMarks(String value) => marks.value = value;

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dobController.text = '${picked.day.toString().padLeft(2, '0')} / '
          '${picked.month.toString().padLeft(2, '0')} / '
          '${picked.year}';
    }
  }

  Future<void> selectPetOwnership(bool value) async {
    print('DEBUG: selectPetOwnership called with value: $value');
    hasPet.value = value;
    isBusinessOwner.value = false;
    hasSelectedPetOwnership.value = true;
    print('DEBUG: Updated hasPet = ${hasPet.value}');
    print(
      'DEBUG: Updated hasSelectedPetOwnership = ${hasSelectedPetOwnership.value}',
    );

    isLoading.value = false;
  }

  Future<void> selectBusinessOwnership() async {
    print('DEBUG: selectBusinessOwnership called');
    isBusinessOwner.value = true;
    hasPet.value = false;
    hasSelectedPetOwnership.value = true;
    print('DEBUG: Updated isBusinessOwner = ${isBusinessOwner.value}');
    print(
      'DEBUG: Updated hasSelectedPetOwnership = ${hasSelectedPetOwnership.value}',
    );

    isLoading.value = false;
  }

  void selectPetType(String type) {
    selectedPetType.value = type;
  }

  Future<void> proceedFromPetOwnership() async {
    log("Comes here");
    final loading = Get.find<LoadingController>();
    if (!hasSelectedPetOwnership.value) {
      Get.snackbar('Error', 'Please select an option',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      loading.show();

      if (isBusinessOwner.value) {
        final upgradeResult = await _apiService.upgradeToBusinessUser();
        if (upgradeResult['success'] != true) {
          loading.hide();
          isLoading.value = false;
          ShortMessageUtils.showError(
              upgradeResult['message'] ?? 'Failed to switch to business account');
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 300));
      loading.hide();
      isLoading.value = false;

      // Navigate directly to pet selection
      if (hasPet.value == true) {
        await StorageService.setStepDone(StorageService.petOwnershipDone);
        await Get.offAllNamed(AppRoutes.petSelection);
      } else {
        log("Don't have pet");
        await StorageService.setStepDone(StorageService.petProfileComplete);
        await Get.offAllNamed(AppRoutes.cityView);
      }
    } catch (e) {
      loading.hide();
      Get.snackbar('Error', 'Something went wrong',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> proceedFromPetSelection() async {
    final loading = Get.find<LoadingController>();
    if (selectedPetType.value.isEmpty) {
      Get.snackbar('Error', 'Please select a pet type',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      loading.show();

      await Future.delayed(const Duration(milliseconds: 300));
      loading.hide();
      isLoading.value = false;
      saveDraft();
      await StorageService.setStepDone(StorageService.petSelectionDone);
      // Navigate directly to pet profile
      await Get.offAndToNamed(AppRoutes.petProfile);
    } catch (e) {
      loading.hide();
      Get.snackbar('Error', 'Something went wrong',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickPetPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        print('DEBUG: Image picked: ${image.path}');
        petPhoto.value = File(image.path);
        Get.snackbar('Success', 'Photo updated!',
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      print('DEBUG: Error picking image: $e');
      Get.snackbar('Error', 'Failed to pick image',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> savePetProfile1() async {
    final loading = Get.find<LoadingController>();
    if (!_validatePetProfileStep()) {
      return;
    }

    // Skip actual save operations in test mode
    if (Get.testMode == true) {
      return;
    }

    try {
      isLoading.value = true;
      loading.show();

      petName.value = nameController.text;
      breed.value = breedController.text;
      bio.value = bioController.text;

      await Future.delayed(const Duration(milliseconds: 800));
      loading.hide();
      Get.snackbar('Success', 'Profile saved successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
      // Determine next screen
      final currentRoute = Get.currentRoute;

      isLoading.value = false;
      saveDraft();
      await StorageService.setStepDone(StorageService.petBasicDataDone);
      final nextRoute = AppRoutes.getNextSignupRoute(currentRoute);
      if (nextRoute != null) {
        await Get.offNamed(nextRoute);
      } else {
        isLoading.value = false;
        await Get.offNamed(AppRoutes.appearance);
      }
    } catch (e, stackTrace) {
      loading.hide();
      Get.snackbar('Error', 'Failed to save profile',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void _showValidationError(String message) {
    if (Get.testMode != true) {
      Get.snackbar('Error', message,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  bool _validatePetProfileStep() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet name',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (selectedSex.value.isEmpty) {
      Get.snackbar('Error', 'Please select pet sex',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (dobController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please select date of birth',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (bioController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet bio',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  void saveDraft() {
    final draft = {
      'name': nameController.text,
      'breed': breedTextController.text,
      'breedController': breedController.text,
      'color': petColor.text,
      'selectedHexColor': selectedHexColor.value,
      'size': selectedSize.value,
      'weight': weightController.text,
      'marks': marksController.text,
      'sex': selectedSex.value,
      'dateOfBirth': dobController.text,
      'bio': bioController.text,
      'ownerContactNumber': ownerContactController.text,
      'street': streetController.text,
      'zipCode': zipCodeController.text,
      'city': selectedCity.value,
      'state': selectedState.value,
      'country': selectedCountry.value,
      'isAddressPrivate': isAddressPrivate.value,
      'microchipNumber': microchipController.text,
      'tagId': tagIdController.text,
      'vetName': vetNameController.text,
      'vetContactNumber': vetContactController.text,
      'personalityTraits': personalityController.text,
      'allergies': allergiesController.text,
      'specialNeeds': specialNeedsController.text,
      'feedingInstructions': feedingController.text,
      'dailyRoutine': routineController.text,
      'petType': selectedPetType.value,
      'petPhoto': petPhoto.value?.path ?? '',
      'photos': photos.map((file) => file.path).toList(),
      'vaccinationStatus': vaccinationStatus.value,
      'isNeutered': isNeutered.value,
      'isSpayedNeutered': isSpayedNeutered.value,
    };
    StorageService.savePetProfileDraft(draft);
  }

  void _loadDraft() {
    final draft = StorageService.getPetProfileDraft();
    if (draft != null) {
      nameController.text = draft['name'] ?? '';
      breedTextController.text = draft['breed'] ?? '';
      breedController.text = draft['breedController'] ?? '';
      petColor.text = draft['color'] ?? '';
      selectedHexColor.value = draft['selectedHexColor'] ?? '#FF6B81';
      selectedSize.value = draft['size'] ?? 'Medium';
      weightController.text = draft['weight'] ?? '';
      marksController.text = draft['marks'] ?? '';
      selectedSex.value = draft['sex'] ?? 'Male';
      dobController.text = draft['dateOfBirth'] ?? '';
      bioController.text = draft['bio'] ?? '';
      ownerContactController.text = draft['ownerContactNumber'] ?? '';
      streetController.text = draft['street'] ?? '';
      zipCodeController.text = draft['zipCode'] ?? '';
      selectedCity.value = draft['city'] ?? '';
      selectedState.value = draft['state'] ?? '';
      selectedCountry.value = draft['country'] ?? '';
      isAddressPrivate.value = draft['isAddressPrivate'] ?? false;
      microchipController.text = draft['microchipNumber'] ?? '';
      tagIdController.text = draft['tagId'] ?? '';
      vetNameController.text = draft['vetName'] ?? '';
      vetContactController.text = draft['vetContactNumber'] ?? '';
      personalityController.text = draft['personalityTraits'] ?? '';
      allergiesController.text = draft['allergies'] ?? '';
      specialNeedsController.text = draft['specialNeeds'] ?? '';
      feedingController.text = draft['feedingInstructions'] ?? '';
      routineController.text = draft['dailyRoutine'] ?? '';
      selectedPetType.value = draft['petType'] ?? '';
      vaccinationStatus.value = draft['vaccinationStatus'] ?? 'Yes';
      isNeutered.value = draft['isNeutered'] ?? false;
      isSpayedNeutered.value = draft['isSpayedNeutered'] ?? false;
      // Restore petPhoto
      final petPhotoPath = draft['petPhoto'];
      if (petPhotoPath != null &&
          petPhotoPath is String &&
          petPhotoPath.isNotEmpty) {
        petPhoto.value = File(petPhotoPath);
      }
      // Restore photos
      final photoPaths = draft['photos'];
      if (photoPaths != null && photoPaths is List) {
        photos.assignAll(
            photoPaths.whereType<String>().map((path) => File(path)));
      }
    }
  }

  void assignValues() {
    final profileController = Get.find<ProfileController>();
    final petData = profileController.userPet.value;
    log("pet  ");
    if (petData != null) {
      selectedSize.value = petData.sex!;
      selectedPetType.value = petData.petType!;
      selectedSize.value = petData.size!;
      nameController.text = petData.name!;
      petColor.text = petData.color!;
      breedTextController.text = petData.breed!;
      breedController.text = petData.breed!;
      bioController.text = petData.bio!;
      dobController.text = petData.dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(petData.dateOfBirth!)
          : '';
      weightController.text = petData.weight.toString();
      marksController.text = petData.marks!;
      microchipController.text = petData.microchipNumber!;
      tagIdController.text = petData.tagId!;
      vetNameController.text = petData.vetName!;
      vetContactController.text = petData.vetContactNumber!;
      personalityController.text = petData.personalityTraits!.join(',');
      allergiesController.text = petData.allergies!.join(',');
      specialNeedsController.text = petData.specialNeeds!;
      feedingController.text = petData.feedingInstructions!;
      routineController.text = petData.dailyRoutine!;
      selectedHexColor.value = petData.color!;
      hasPet.value = true;
      hasSelectedPetOwnership.value = true;
      ownerContactController.text = petData.ownerContactNumber ?? "";
      selectedState.value = petData.address?.state ?? "";
      selectedCountry.value = petData.address?.country ?? "";
      selectedCity.value = petData.address?.city ?? "";
    }
  }

  final loadingController = Get.find<LoadingController>();
  Future<void> verifyUsingEmail() async {
    try {
      loadingController.show();
      final response = await ApiClient().get(ApiEndPoints.verificationStatus);
      if (response["isVerified"] == true) {
        loadingController.hide();
        await StorageService.setStepDone(StorageService.signupDone);
        await StorageService.setStepDone(StorageService.editProfileDone);
        Get.offAllNamed(AppRoutes.petOwnership, arguments: true);
        // Get.offAllNamed(AppRoutes.editProfile, arguments: true);
      } else {
        loadingController.hide();
        Get.offAllNamed(AppRoutes.verifyEmailView);
        ShortMessageUtils.showError("Please verify your email first.");
      }
    } catch (e, stackTrace) {
      loadingController.hide();
      log("Error verifying email: $e\n$stackTrace");
      ShortMessageUtils.showError("Something went wrong. Please try again.");
    }
  }

  Future<void> resendEmail() async {
    try {
      loadingController.show();
      final response =
          await ApiClient().post(ApiEndPoints.resendVerificationEmail, {});
      loadingController.hide();
      ShortMessageUtils.showSuccess("We have resend you the email");
    } catch (e) {
      loadingController.hide();
    } finally {}
  }

  Future<void> savePetProfile() async {
    final loading = Get.find<LoadingController>();
    if (!_validatePetProfile()) return;
    log("isEdit profile  ");

    try {
      isLoading.value = true;
      loading.show();

      final petData = <String, dynamic>{
        'isHavePet': hasPet.value,
        'petType':
            selectedPetType.value.isNotEmpty ? selectedPetType.value : null,
        'name': nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : null,
        'breed': breedTextController.text,
        'sex': selectedSex.value.isNotEmpty
            ? selectedSex.value.toLowerCase()
            : null,
        'dateOfBirth': dobController.text.trim().isNotEmpty
            ? dobController.text.trim()
            : null,
        'bio': bioController.text,
        'color': petColor.text,
        'size': selectedSize.value.isNotEmpty
            ? selectedSize.value.toLowerCase()
            : null,
        'weight': double.tryParse(weightController.text.trim()) != null
            ? double.parse(weightController.text.trim())
            : null,
        'marks': marksController.text,
        'ownerContactNumber': ownerContactController.text,
        'address': {
          if (selectedState.value != "") 'state': selectedState.value,
          if (selectedCountry.value != "") 'country': selectedCountry.value,
          if (selectedCity.value != "") 'city': selectedCity.value,
          if (zipCodeController.text.trim().isNotEmpty) 'zipCode': zipCodeController.text.trim(),
          if (streetController.text.trim().isNotEmpty) 'street': streetController.text.trim(),
        },
        'microchipNumber': microchipController.text, // Keep for backward compatibility
        'microchipNumbers': microchipNumbers.toList(), // New: array of microchip numbers
        'tagId': tagIdController.text,
        'lostStatus': false,
        'vaccinationStatus': vaccinationStatus.value == 'Yes',
        'vetName': vetNameController.text,
        'vetContactNumber': vetContactController.text,
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
        'specialNeeds': specialNeedsController.text,
        'feedingInstructions': feedingController.text,
        'dailyRoutine': routineController.text,
        'race': breedController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
      };

      // 7f Only add profilePic and photos if not editing
      if (!isEditProfile.value) {
        petData['profilePic'] = petPhoto.value?.path ?? '';
        petData['photos'] = photos.map((file) => file.path).toList();
      }
      log("Pet data is $petData");
      final result =
          await _apiService.createPetProfile(petData, isEditProfile.value);
      if (result['success']) {
        loading.hide();
        Get.snackbar('Success', 'Pet profile created successfully!',
            backgroundColor: Colors.green, colorText: Colors.white);
        if (isEditProfile.value) {
          // Fetch profile after edit is done
          final profileController = Get.find<ProfileController>();
          await profileController.fetchProfilee();
        }
        await StorageService.setStepDone(StorageService.petOwnerDone);
        await StorageService.setStepDone(StorageService.petProfileComplete);
        Get.offAllNamed(AppRoutes.cityView);
        // Future.microtask(() => Get.put(MapController()).selectFeature("user"));
      } else {
        log("Result is $result");
        loading.hide();
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to create pet profile',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      log("Error is $e");
      loading.hide();
      Get.snackbar('Error', 'Failed to create pet profile',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  bool _validatePetProfile() {
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter pet name',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (dobController.text.isEmpty) {
      Get.snackbar('Error', 'Please select date of birth',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (selectedHexColor.value.isEmpty) {
      Get.snackbar('Error', 'Please select pet color',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (selectedSize.value.isEmpty) {
      Get.snackbar('Error', 'Please select pet size',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (weightController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter pet weight',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (vetNameController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter vet name',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (vetContactController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter vet contact number',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  void removePhoto(int index) {
    if (index >= 0 && index < photos.length) {
      photos.removeAt(index);
    }
  }

  bool _validateAppearanceStep() {
    if (photos.isEmpty && !isEditProfile.value) {
      Get.snackbar('Error', 'Please add at least one photo',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (petColor.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet color',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (breedTextController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet breed',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (selectedSize.value.isEmpty) {
      Get.snackbar('Error', 'Please select pet size',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (weightController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet weight',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    final weight = double.tryParse(weightController.text.trim());
    if (weight == null || weight <= 0) {
      Get.snackbar('Error', 'Please enter a valid weight',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (marksController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter distinguishing marks',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  bool _validateIdentificationStep() {
    if (vaccinationStatus.value.isEmpty) {
      Get.snackbar('Error', 'Please select vaccination status',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (vetNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter vet name',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (vetContactController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter vet contact number',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  bool _validateBehavioralStep() {
    if (personalityController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter personality traits',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (allergiesController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter allergies (or "None" if no allergies)',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (specialNeedsController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter special needs (or "None" if no special needs)',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (feedingController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter feeding instructions',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (routineController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter daily routine',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  Future<void> saveAppearance() async {
    final loading = Get.find<LoadingController>();
    if (!_validateAppearanceStep()) {
      return;
    }

    // Skip actual save operations in test mode
    if (Get.testMode == true) {
      return;
    }

    try {
      isLoading.value = true;
      loading.show();

      // Save the appearance data
      weight.value = weightController.text;
      marks.value = marksController.text;
      await Future.delayed(const Duration(milliseconds: 800));
      loading.hide();
      Get.snackbar('Success', 'Appearance saved!',
          backgroundColor: Colors.green, colorText: Colors.white);
      saveDraft();
      await StorageService.setStepDone(StorageService.petApearenceDone);
      // Navigate to the next screen in the signup flow
      Get.toNamed(AppRoutes.identification);
    } catch (e) {
      loading.hide();
      Get.snackbar('Error', 'Failed to save appearance',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateAppearanceStep() {
    if (photos.isEmpty && !isEditProfile.value) {
      Get.snackbar('Error', 'Please add at least one photo',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (petColor.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet color',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (breedTextController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet breed',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (selectedSize.value.isEmpty) {
      Get.snackbar('Error', 'Please select pet size',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (weightController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter pet weight',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    final weight = double.tryParse(weightController.text.trim());
    if (weight == null || weight <= 0) {
      Get.snackbar('Error', 'Please enter a valid weight',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  void updateLostStatus(String value) => lostStatus.value = value;
  void updateVaccinationStatus(String value) => vaccinationStatus.value = value;

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

  Future<void> saveIdentification() async {
    final loading = Get.find<LoadingController>();
    if (!_validateIdentificationStep()) {
      return;
    }

    // Skip actual save operations in test mode
    if (Get.testMode == true) {
      return;
    }

    try {
      saveDraft();
      isLoading.value = true;
      loading.show();
      
      // Collect all microchip numbers from controllers
      microchipNumbers.clear();
      for (var controller in microchipControllers) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          microchipNumbers.add(value);
        }
      }
      
      // Save identification data
      microchipNumber.value = microchipController.text; // Keep for backward compatibility
      tagId.value = tagIdController.text;
      vetName.value = vetNameController.text;
      vetContactNumber.value = vetContactController.text;

      await Future.delayed(const Duration(milliseconds: 800));
      loading.hide();
      Get.snackbar('Success', 'Information saved successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
      isLoading.value = false;
      await StorageService.setStepDone(StorageService.petIdentificationDone);

      // Navigate to behavioral page
      await Get.offNamed(AppRoutes.behavioral);
    } catch (e, stackTrace) {
      loading.hide();
      Get.snackbar('Error', 'Failed to save information',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateIdentificationStep() {
    if (vetNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter vet name',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (vetContactController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter vet contact number',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  Future<void> saveBehavioralAndNavigate() async {
    final loading = Get.find<LoadingController>();
    if (!_validateBehavioralStep()) {
      return;
    }

    // Skip actual save operations in test mode
    if (Get.testMode == true) {
      return;
    }

    try {
      saveDraft();
      isLoading.value = true;
      loading.show();
      final behavioralData = {
        'personality': personalityController.text,
        'allergies': allergiesController.text,
        'specialNeeds': specialNeedsController.text,
        'feeding': feedingController.text,
        'routine': routineController.text,
      };

      await Future.delayed(const Duration(milliseconds: 800));
      loading.hide();
      Get.snackbar('Success', 'Information saved!',
          backgroundColor: Colors.green, colorText: Colors.white);

      // Complete the signup flow
      isLoading.value = false;
      await StorageService.setStepDone(StorageService.petBehavioralDone);
      await Get.offAllNamed(AppRoutes.ownerInfo);
    } catch (e) {
      loading.hide();
      Get.snackbar('Error', 'Failed to save information',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      currentLocation.value = LatLng(position.latitude, position.longitude);

      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation.value,
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );

      mapController?.animateCamera(
        CameraUpdate.newLatLng(currentLocation.value),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> saveOwnerInfoAndNavigate() async {
    await Get.offNamed(AppRoutes.dogBreeds);

    try {
      if (!_validateOwnerInfo()) {
        return;
      }

      isLoading.value = true;
      Get.find<LoadingController>().show();

      // Save owner info data
      final ownerData = {
        'contact': ownerContactController.text,
        'street': streetController.text,
        'zipCode': zipCodeController.text,
        'city': selectedCity.value,
        'state': selectedState.value,
        'country': selectedCountry.value,
        'isPrivate': isAddressPrivate.value,
        'location': {
          'lat': currentLocation.value.latitude,
          'lng': currentLocation.value.longitude,
        },
      };

      await Future.delayed(const Duration(milliseconds: 800));
      Get.find<LoadingController>().hide();
      Get.snackbar('Success', 'Information saved!',
          backgroundColor: Colors.green, colorText: Colors.white);
      isLoading.value = false;
      // Navigate to next page
      await Get.offNamed(AppRoutes.dogBreeds);
    } catch (e) {
      Get.find<LoadingController>().hide();
      Get.snackbar('Error', 'Failed to save information',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  String userName = "";
  String userEmail = "";
  String userPassword = "";

  bool _validateOwnerInfo() {
    if (ownerContactController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter contact number',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (streetController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter street address',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (zipCodeController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter zip code',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (cityController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter city',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (stateController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter state',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (countryController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter country',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  Future<void> handleSignup({bool isSocial = false}) async {
    final loading = Get.find<LoadingController>();
    try {
      if (!isSocial && !_validateSignupForm()) return;
      if (!isSocial) {
        userName = nameController.text;
        userEmail = emailController.text;
        userPassword = passwordController.text;
      }
      isLoading.value = true;
      loading.show();

      final result = await _apiService.register(
        email: userEmail,
        password: userPassword,
        name: userName,
      );

      if (result['success'] == true) {
        final token = result["data"]["token"];
        userToken = token;
        print("Token is $token");

        loading.hide();
        ShortMessageUtils.showSuccess("Account created successfully!");
        // sendOtp();

        await StorageService.saveToken(result['data']['token']);
        log('SignupController saved token: ${StorageService.getToken()}');
        // Clear signup fields after successful account creation
        clearSignupFields();
        if (bypassEmailVerification) {
          await StorageService.setStepDone(StorageService.signupDone);
          await Get.offAllNamed(AppRoutes.petOwnership);
        } else {
          Get.toNamed(AppRoutes.verifyEmailView, arguments: true);
        }
        // Get.offAllNamed(AppRoutes.editProfile);
      } else {
        final errorMessage = result['message'] ?? 'Signup failed.';
        loading.hide();
        ShortMessageUtils.showError(errorMessage);
      }
    } catch (e) {
      loading.hide();
      ShortMessageUtils.showError("An error occurred during signup $e");
    } finally {
      isLoading.value = false;
    }
  }

  void clearSignupFields() {
    // Auth basics
    usernameController.text = '';
    emailController.text = '';
    passwordController.text = '';
    confirmPasswordController.text = '';
    userName = '';
    userEmail = '';
    userPassword = '';
    showPassword.value = false;
    showConfirmPassword.value = false;

    // OTP
    otpController.text = '';
    stopOtpTimer();
  }

  bool _validateSignupForm() {
    if (nameController.text.isEmpty) {
      Get.snackbar('Info', 'Please enter your name',
          backgroundColor: Colors.blue, colorText: Colors.white);
      return false;
    }

    if (emailController.text.isEmpty) {
      Get.snackbar('Info', 'Please enter your email',
          backgroundColor: Colors.blue, colorText: Colors.white);
      return false;
    }

    if (passwordController.text.isEmpty) {
      Get.snackbar('Info', 'Please enter your password',
          backgroundColor: Colors.blue, colorText: Colors.white);
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar('Info', 'Passwords do not match',
          backgroundColor: Colors.blue, colorText: Colors.white);
      return false;
    }

    return true;
  }

  void populatePetFormData(Map<String, dynamic> petData) {
    try {
      // Set edit mode
      isEditProfile.value = true;
      
      // Populate basic fields
      nameController.text = petData['name']?.toString() ?? '';
      breedController.text = petData['breed']?.toString() ?? '';
      bioController.text = petData['bio']?.toString() ?? '';
      
      // Handle date of birth
      if (petData['dateOfBirth'] != null) {
        try {
          final date = DateTime.parse(petData['dateOfBirth'].toString());
          dobController.text = DateFormat('yyyy-MM-dd').format(date);
        } catch (e) {
          log('Error parsing date: $e');
        }
      }
      
      // Handle other fields if they exist
      if (petData['weight'] != null) {
        weightController.text = petData['weight'].toString();
      }
      if (petData['marks'] != null) {
        marksController.text = petData['marks'].toString();
      }
      if (petData['microchipNumber'] != null) {
        microchipController.text = petData['microchipNumber'].toString();
      }
      if (petData['tagId'] != null) {
        tagIdController.text = petData['tagId'].toString();
      }
      if (petData['vetName'] != null) {
        vetNameController.text = petData['vetName'].toString();
      }
      if (petData['vetContactNumber'] != null) {
        vetContactController.text = petData['vetContactNumber'].toString();
      }
      if (petData['personalityTraits'] != null) {
        personalityController.text = petData['personalityTraits'].toString();
      }
      if (petData['allergies'] != null) {
        allergiesController.text = petData['allergies'].toString();
      }
      if (petData['specialNeeds'] != null) {
        specialNeedsController.text = petData['specialNeeds'].toString();
      }
      if (petData['feedingInstructions'] != null) {
        feedingController.text = petData['feedingInstructions'].toString();
      }
      if (petData['dailyRoutine'] != null) {
        routineController.text = petData['dailyRoutine'].toString();
      }
      if (petData['ownerContactNumber'] != null) {
        ownerContactController.text = petData['ownerContactNumber'].toString();
      }
      
      // Handle dropdown selections
      if (petData['sex'] != null) {
        selectedSex.value = petData['sex'].toString();
      }
      if (petData['petType'] != null) {
        selectedPetType.value = petData['petType'].toString();
      }
      if (petData['size'] != null) {
        selectedSize.value = petData['size'].toString();
      }
      if (petData['color'] != null) {
        selectedHexColor.value = petData['color'].toString();
      }
      
      // Handle address fields
      if (petData['address'] != null && petData['address'] is Map) {
        final address = petData['address'] as Map<String, dynamic>;
        if (address['state'] != null) {
          selectedState.value = address['state'].toString();
        }
        if (address['country'] != null) {
          selectedCountry.value = address['country'].toString();
        }
        if (address['city'] != null) {
          selectedCity.value = address['city'].toString();
        }
      }
      
      log('Pet form data populated successfully');
    } catch (e) {
      log('Error populating pet form data: $e');
    }
  }
}
