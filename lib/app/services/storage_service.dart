import 'package:get_storage/get_storage.dart';

class StorageService {
  static final _storage = GetStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _fcmTokenKey = 'fcmTokenKey';

  static const String signupDone = 'signup_done';
  static const String editProfileDone = 'edit_profile_done';
  static const String petOwnershipDone = 'pet_ownership_done';
  static const String petSelectionDone = 'pet_selection_done';
  static const String petOwnerDone = 'pet_owner_done';
  static const String petBasicDataDone =
      "pet_basic_done"; //Get.offAndToNamed(AppRoutes.apearence);
  static const String petApearenceDone =
      "pet_apearence_done"; //Get.offAndToNamed(AppRoutes.apearence);
  static const String petIdentificationDone =
      "pet_identification_done"; //Get.offAndToNamed(AppRoutes.identification);
  static const String petBehavioralDone =
      "pet_behavioral_done"; //Get.offAndToNamed(AppRoutes.behavioral);

  static const String petProfileComplete = 'pet_profile_complete';
  static const String petProfileDraft = 'pet_profile_draft';

  // Must be called before using GetStorage
  static Future<void> init() async {
    await GetStorage.init();
  }

  /// Save auth token
  static Future<void> saveToken(String token) async {
    await _storage.write(_tokenKey, token);
  }

  /// Get auth token
  static String? getToken() {
    return _storage.read<String>(_tokenKey);
  }

  static Future<void> setStepDone(String key) async {
    await _storage.write(key, true);
  }

// Check methods
  static bool isStepDone(String key) {
    return _storage.read<bool>(key) ?? false;
  }

  /// Save user data
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await _storage.write(_userKey, userData);
  }

  /// Get user data
  static Map<String, dynamic>? getUser() {
    final data = _storage.read<Map<String, dynamic>>(_userKey);
    return data;
  }

  /// Save FCM token
  static Future<void> saveFcmToken(String fcmToken) async {
    await _storage.write(_fcmTokenKey, fcmToken);
  }

  /// Get FCM token
  static String? getFcmToken() {
    return _storage.read<String>(_fcmTokenKey);
  }

  static Future<void> savePetProfileDraft(Map<String, dynamic> data) async {
    await _storage.write(petProfileDraft, data);
  }

  static Map<String, dynamic>? getPetProfileDraft() {
    return _storage.read<Map<String, dynamic>>(petProfileDraft);
  }

  static Future<void> clearPetProfileDraft() async {
    await _storage.remove(petProfileDraft);
  }

  /// Clear all stored data
  static Future<void> clearStorage() async {
    await _storage.erase();
  }
}
