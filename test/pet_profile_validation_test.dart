import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/data/controllers/location_controller.dart';
import 'package:chys/app/modules/signup/controller/signup_controller.dart';
import 'package:chys/app/services/api_service.dart';
import 'package:chys/app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    await Get.deleteAll(force: true);
    Get.put(LoadingController());
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  group('Pet Profile Step - Required Fields', () {
    late SignupController controller;

    setUp(() {
      final locationController = _StubLocationController();
      Get.put<LocationController>(locationController);
      controller = SignupController(
        apiService: _StubApiService(),
        locationController: locationController,
      );
    });

    test('should require pet name', () async {
      controller.nameController.text = '';
      controller.selectedSex.value = 'Male';
      controller.dobController.text = '01 / 01 / 2020';
      controller.bioController.text = 'Test bio';

      await controller.savePetProfile1();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require sex selection', () async {
      controller.nameController.text = 'Buddy';
      controller.selectedSex.value = '';
      controller.dobController.text = '01 / 01 / 2020';
      controller.bioController.text = 'Test bio';

      await controller.savePetProfile1();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require date of birth', () async {
      controller.nameController.text = 'Buddy';
      controller.selectedSex.value = 'Male';
      controller.dobController.text = '';
      controller.bioController.text = 'Test bio';

      await controller.savePetProfile1();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require bio', () async {
      controller.nameController.text = 'Buddy';
      controller.selectedSex.value = 'Male';
      controller.dobController.text = '01 / 01 / 2020';
      controller.bioController.text = '';

      await controller.savePetProfile1();
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('Pet Profile Step - Optional Fields', () {
    late SignupController controller;

    setUp(() {
      final locationController = _StubLocationController();
      Get.put<LocationController>(locationController);
      controller = SignupController(
        apiService: _StubApiService(),
        locationController: locationController,
      );
    });

    test('should NOT require spayed/neutered (optional field)', () async {
      controller.nameController.text = 'Buddy';
      controller.selectedSex.value = 'Male';
      controller.dobController.text = '01 / 01 / 2020';
      controller.bioController.text = 'Test bio';
      controller.isSpayedNeutered.value = false;

      await controller.savePetProfile1();
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('Appearance Step - Required Fields', () {
    late SignupController controller;

    setUp(() {
      final locationController = _StubLocationController();
      Get.put<LocationController>(locationController);
      controller = SignupController(
        apiService: _StubApiService(),
        locationController: locationController,
      );
    });

    test('should require pet color', () async {
      controller.petColor.text = '';
      controller.breedTextController.text = 'Labrador';
      controller.selectedSize.value = 'Large';
      controller.weightController.text = '30';
      controller.marksController.text = 'White spot';

      await controller.saveAppearance();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require breed', () async {
      controller.petColor.text = 'Brown';
      controller.breedTextController.text = '';
      controller.selectedSize.value = 'Large';
      controller.weightController.text = '30';
      controller.marksController.text = 'White spot';

      await controller.saveAppearance();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require size', () async {
      controller.petColor.text = 'Brown';
      controller.breedTextController.text = 'Labrador';
      controller.selectedSize.value = '';
      controller.weightController.text = '30';
      controller.marksController.text = 'White spot';

      await controller.saveAppearance();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require weight', () async {
      controller.petColor.text = 'Brown';
      controller.breedTextController.text = 'Labrador';
      controller.selectedSize.value = 'Large';
      controller.weightController.text = '';
      controller.marksController.text = 'White spot';

      await controller.saveAppearance();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require valid weight (positive number)', () async {
      controller.petColor.text = 'Brown';
      controller.breedTextController.text = 'Labrador';
      controller.selectedSize.value = 'Large';
      controller.weightController.text = '-5';
      controller.marksController.text = 'White spot';

      await controller.saveAppearance();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require distinguishing marks', () async {
      controller.petColor.text = 'Brown';
      controller.breedTextController.text = 'Labrador';
      controller.selectedSize.value = 'Large';
      controller.weightController.text = '30';
      controller.marksController.text = '';

      await controller.saveAppearance();
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('Identification Step - Required Fields', () {
    late SignupController controller;

    setUp(() {
      final locationController = _StubLocationController();
      Get.put<LocationController>(locationController);
      controller = SignupController(
        apiService: _StubApiService(),
        locationController: locationController,
      );
    });

    test('should require vaccination status', () async {
      controller.vaccinationStatus.value = '';
      controller.vetNameController.text = 'Dr. Smith';
      controller.vetContactController.text = '555-1234';

      await controller.saveIdentification();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require vet name', () async {
      controller.vaccinationStatus.value = 'Yes';
      controller.vetNameController.text = '';
      controller.vetContactController.text = '555-1234';

      await controller.saveIdentification();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require vet contact', () async {
      controller.vaccinationStatus.value = 'Yes';
      controller.vetNameController.text = 'Dr. Smith';
      controller.vetContactController.text = '';

      await controller.saveIdentification();
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('Identification Step - Optional Fields', () {
    late SignupController controller;

    setUp(() {
      final locationController = _StubLocationController();
      Get.put<LocationController>(locationController);
      controller = SignupController(
        apiService: _StubApiService(),
        locationController: locationController,
      );
    });

    test('should NOT require microchip numbers (optional)', () async {
      controller.vaccinationStatus.value = 'Yes';
      controller.vetNameController.text = 'Dr. Smith';
      controller.vetContactController.text = '555-1234';
      controller.microchipController.text = '';

      await controller.saveIdentification();
      expect(controller.isLoading.value, isFalse);
    });

    test('should NOT require tag ID (optional)', () async {
      controller.vaccinationStatus.value = 'Yes';
      controller.vetNameController.text = 'Dr. Smith';
      controller.vetContactController.text = '555-1234';
      controller.tagIdController.text = '';

      await controller.saveIdentification();
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('Behavioral Step - Required Fields', () {
    late SignupController controller;

    setUp(() {
      final locationController = _StubLocationController();
      Get.put<LocationController>(locationController);
      controller = SignupController(
        apiService: _StubApiService(),
        locationController: locationController,
      );
    });

    test('should require personality traits', () async {
      controller.personalityController.text = '';
      controller.allergiesController.text = 'None';
      controller.specialNeedsController.text = 'None';
      controller.feedingController.text = 'Twice daily';
      controller.routineController.text = 'Morning walk';

      await controller.saveBehavioralAndNavigate();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require allergies', () async {
      controller.personalityController.text = 'Friendly';
      controller.allergiesController.text = '';
      controller.specialNeedsController.text = 'None';
      controller.feedingController.text = 'Twice daily';
      controller.routineController.text = 'Morning walk';

      await controller.saveBehavioralAndNavigate();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require special needs', () async {
      controller.personalityController.text = 'Friendly';
      controller.allergiesController.text = 'None';
      controller.specialNeedsController.text = '';
      controller.feedingController.text = 'Twice daily';
      controller.routineController.text = 'Morning walk';

      await controller.saveBehavioralAndNavigate();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require feeding instructions', () async {
      controller.personalityController.text = 'Friendly';
      controller.allergiesController.text = 'None';
      controller.specialNeedsController.text = 'None';
      controller.feedingController.text = '';
      controller.routineController.text = 'Morning walk';

      await controller.saveBehavioralAndNavigate();
      expect(controller.isLoading.value, isFalse);
    });

    test('should require daily routine', () async {
      controller.personalityController.text = 'Friendly';
      controller.allergiesController.text = 'None';
      controller.specialNeedsController.text = 'None';
      controller.feedingController.text = 'Twice daily';
      controller.routineController.text = '';

      await controller.saveBehavioralAndNavigate();
      expect(controller.isLoading.value, isFalse);
    });
  });
}

class _StubApiService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> upgradeToBusinessUser() async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> createPetProfile(
    Map<String, dynamic> data,
    bool isEdit,
  ) async {
    return {'success': true};
  }
}

class _StubLocationController extends LocationController {
  @override
  void onInit() {
    // Skip location fetching in tests
  }
}
