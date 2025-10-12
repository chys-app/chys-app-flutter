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

  setUpAll(() async {
    await GetStorage.init();
  });

  setUp(() async {
    Get.testMode = true;
    await StorageService.clearStorage();
    await Get.deleteAll(force: true);
    Get.put(LoadingController());
  });

  tearDown(() async {
    await StorageService.clearStorage();
    await Get.deleteAll(force: true);
  });

  test('proceedFromPetOwnership upgrades business user and completes flow', () async {
    final locationController = _StubLocationController();
    Get.put<LocationController>(locationController);

    final apiService = _StubApiService(
      response: {
        'success': true,
        'message': 'Business profile updated.',
      },
    );

    final controller = SignupController(
      apiService: apiService,
      locationController: locationController,
    );

    await controller.selectBusinessOwnership();
    await controller.proceedFromPetOwnership();

    expect(apiService.upgradeCallCount, 1);
    expect(
      StorageService.isStepDone(StorageService.petProfileComplete),
      isTrue,
    );
    expect(controller.isLoading.value, isFalse);
  });
}

class _StubApiService extends ApiService {
  _StubApiService({required this.response});

  final Map<String, dynamic> response;
  int upgradeCallCount = 0;

  @override
  Future<Map<String, dynamic>> upgradeToBusinessUser() async {
    upgradeCallCount++;
    return response;
  }
}

class _StubLocationController extends LocationController {
  @override
  void onInit() {
    // Skip location fetching in tests.
  }
}
